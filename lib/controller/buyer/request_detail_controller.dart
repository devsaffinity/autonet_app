import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/controller/buyer/accept_offer_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/data/repositories/requests_repository.dart';
import 'package:autonect/domain/conflict_kind.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// One request plus its offers, held as TWO independent ViewStates.
///
/// They load in parallel and neither blanks the other: the offers route is
/// uncapped and unpaginated, so a request with forty offers must not stop the
/// header — the only thing that says what the buyer is looking at — rendering.
class RequestDetailController extends ApiController {
  RequestDetailController(
    this._requests,
    this._orders, {
    super.toast,
    super.showBusy,
    super.hideBusy,
  });

  final RequestsRepository _requests;
  final OrdersRepository _orders;

  static RequestDetailController ensure() =>
      Get.isRegistered<RequestDetailController>()
      ? Get.find<RequestDetailController>()
      : Get.put(
          RequestDetailController(
            Get.find<RequestsRepository>(),
            Get.find<OrdersRepository>(),
          ),
        );

  /// TWO slots: the reads are PARALLEL, so one counter would have [loadOffers]
  /// supersede the [loadRequest] beside it and the header would never land.
  static const StateSlot _requestRead = StateSlot('request');
  static const StateSlot _offersRead = StateSlot('offers');

  final Rx<ViewState<PartRequest>> request =
      Rx<ViewState<PartRequest>>(const Loading());
  final Rx<ViewState<List<Offer>>> offers =
      Rx<ViewState<List<Offer>>>(const Loading());

  /// The request this singleton is pointed at; '' before the first [load].
  String get requestId => entityId ?? '';

  PartRequest? get requestOrNull => switch (request.value) {
    Data<PartRequest>(:final value) => value,
    _ => null,
  };

  Future<void> load(String id) {
    // [formError] here is a failed CLOSE or CANCEL, cleared only by those two
    // irreversible actions — offered only while a request is OPEN. Left alone,
    // A's red 'no longer open' prints over B's buttons, and on a request
    // already closed nothing on screen can remove it.
    beginEntity(id);
    request.value = const Loading();
    offers.value = const Loading();
    // Deliberately not through run(): the busy latch is one-at-a-time, and
    // serialising these two would reintroduce the blocking header.
    return Future.wait([loadRequest(), loadOffers()]);
  }

  /// A's header over B's offers is not cosmetic: each row gates Accept on
  /// `canAcceptOffer(offer, request)`, so A's status judging B's offers makes
  /// a live offer inert or a dead one tappable.
  Future<void> loadRequest() =>
      runRead(_requestRead, () => _requests.byId(requestId), (r) {
        switch (r) {
          case Err(:final error):
            request.value = Failed<PartRequest>(error);
          case Ok(:final value):
            request.value = Data<PartRequest>(value);
        }
      });

  Future<void> loadOffers() =>
      runRead(_offersRead, () => _orders.offersForRequest(requestId), (r) {
        switch (r) {
          case Err(:final error):
            offers.value = Failed<List<Offer>>(error);
          case Ok(:final value):
            offers.value = value.isEmpty
                ? const Empty<List<Offer>>(
                    'No offers yet',
                    'Suppliers usually respond within a few hours.',
                  )
                : Data<List<Offer>>(value);
        }
      });

  /// The row the server last gave us for [fallback], or [fallback] itself when
  /// the list has not loaded or no longer carries it. A screen pushed with an
  /// immutable Offer would otherwise go on offering an accept that
  /// [refreshIfStale]'s refetch has already disproved.
  Offer liveOffer(Offer fallback) {
    if (offers.value case Data<List<Offer>>(:final value)) {
      for (final o in value) {
        if (o.id == fallback.id) return o;
      }
    }
    return fallback;
  }

  /// As [liveOffer], for the request. Id-checked: this singleton may still be
  /// holding the previous request mid-load.
  PartRequest liveRequest(PartRequest fallback) {
    final r = requestOrNull;
    return r != null && r.id == fallback.id ? r : fallback;
  }

  /// Consume [AcceptOfferController.requestStale].
  ///
  /// An accept — successful, or one of the two actionable 409s — has already
  /// closed the request and rejected its siblings server-side, and the buyer is
  /// sent NO notification of their own accept, so nothing else can tell a
  /// mounted list its offers are gone. The flag is TAKEN before the refetch —
  /// one accept, one refetch — and put BACK if that refetch did not land.
  ///
  /// The conflict latch is released only on a refetch that actually LANDED, and
  /// this is the subtle half. It means 'the list I hold has been overtaken';
  /// releasing it on a failure would re-arm Place Order against the rows
  /// [liveOffer] and [liveRequest] fall back to — the PENDING/OPEN pair the
  /// server already refused. But it cannot be released only inside `accept()`
  /// either, which sits behind the button the latch disables: one actionable
  /// 409 and the buyer could buy nothing again, on any request, until the app
  /// restarted. So a failure leaves BOTH set and both escapes open: the next
  /// screen popping retries this refetch, `beginOffer` clears it outright.
  Future<void> refreshIfStale(AcceptOfferController accept) async {
    if (!accept.requestStale.value) return;
    accept.requestStale.value = false;
    final refreshed = requestId;
    // Both halves: the accept moved the request to CLOSED as well as rejecting
    // the siblings, and the acceptability rule reads them together.
    await Future.wait([loadRequest(), loadOffers()]);
    // A deeper screen re-pointed this singleton mid-flight, so both reads were
    // discarded and the refetch this flag paid for did not land either.
    if (requestId != refreshed ||
        request.value is Failed<PartRequest> ||
        offers.value is Failed<List<Offer>>) {
      accept.requestStale.value = true;
      return;
    }
    accept.clearConflict();
  }

  /// CLOSE or CANCEL. This route never answers 404 — an unknown id, a foreign
  /// id and an already-closed request all collapse into the same 409 — so the
  /// copy is 'no longer open', never 'not found'.
  Future<bool> close(CloseAction action) async {
    var conflicted = false;
    final closing = requestId; // a claim answers 'may I publish?' only once
    // runWrite, not run + a claim beside it: a tap about to be dropped must
    // not take the slot from the write in flight, and a write that publishes
    // nothing gives the slot back, so the read it superseded still lands.
    final ok = await runWrite<PartRequest, bool>(
      _requestRead,
      () => _requests.closeOrCancel(requestId, action),
      (r, claim) {
        switch (r) {
          case Ok(:final value):
            return claim.publish(() => request.value = Data<PartRequest>(value));
          case Err(:final error):
            conflicted = error.code == ApiErrorCode.conflict;
            // The red line sits under THIS request's Close/Cancel buttons.
            if (!claim.isCurrent) {
              absorbSuperseded(error);
            } else if (conflicted) {
              formError.value = _conflictCopy(error);
            } else {
              absorb(error);
            }
            return false;
        }
      },
    );
    // The server's copy of this request is not what we are showing. Re-read it
    // so the buttons stop offering an action already taken — while it is still
    // the request on screen.
    if (conflicted && requestId == closing) await loadRequest();
    return ok;
  }

  static String _conflictCopy(ApiError e) =>
      switch (classifyConflict(e.message)) {
        ConflictKind.requestNotOpen ||
        ConflictKind.requestAlreadyAccepted => 'This request is no longer open.',
        _ => userMessageFor(e),
      };
}

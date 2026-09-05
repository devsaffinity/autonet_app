import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/domain/conflict_kind.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:get/get.dart';

/// `POST /v1/offers/{id}/accept`.
class AcceptOfferController extends ApiController {
  AcceptOfferController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final OrdersRepository _repo;

  static AcceptOfferController ensure() =>
      Get.isRegistered<AcceptOfferController>()
      ? Get.find<AcceptOfferController>()
      : Get.put(AcceptOfferController(Get.find<OrdersRepository>()));

  /// TRUE once any offers list still mounted has been overtaken by the server.
  ///
  /// Accepting flips the parent request OPEN -> CLOSED and auto-REJECTS every
  /// sibling PENDING offer in the same transaction, and the buyer receives NO
  /// notification of their own accept — so nothing else would ever tell the
  /// list it is stale.
  final RxBool requestStale = false.obs;

  /// Set only for the two 409s the screen can act on, so it knows whether to
  /// refetch rather than merely apologise.
  final Rxn<ConflictKind> conflict = Rxn<ConflictKind>();

  /// [conflict] and the copy beneath it, which describe ONE offer. Claimed at
  /// dispatch so an accept that answers after the buyer has opened a different
  /// offer cannot close Place Order on an offer the server never refused.
  static const StateSlot _acceptWrite = StateSlot('accept');

  bool get shouldRefetch =>
      conflict.value == ConflictKind.offerNotAcceptable ||
      conflict.value == ConflictKind.requestAlreadyAccepted;

  /// Release the latch. [conflict] means 'the list I am holding has been
  /// overtaken by the server', which stops being true the moment a refetch
  /// lands — so [RequestDetailController.refreshIfStale] calls this, and
  /// [accept] cannot be the only caller: it sits behind the button the latch
  /// disables and would never run again.
  void clearConflict() => conflict.value = null;

  /// The ENTITY here is the offer, so [ApiController.entityId] owns the latch:
  /// unowned, one withdrawn offer's 409 would go on closing Place Order for
  /// every other offer the buyer ever opens. [requestStale] is deliberately NOT
  /// reset — it says 'some list still mounted has been overtaken', which is a
  /// fact about the server, not about the offer being opened.
  @override
  void resetForEntity() => clearConflict();

  /// Called by the summary screen as it mounts.
  ///
  /// The latch and the copy beneath it are one offer's answer. A summary for
  /// any OTHER offer opens clean even when no refetch has happened in between —
  /// the two routes that reach an offer without passing back through the list
  /// have no refetch to offer. Re-entering the SAME offer keeps the answer,
  /// which is still true of it.
  void beginOffer(String offerId) => beginEntity(offerId);

  /// [deliveryLocation] is omitted by the repository when null or blank: `{}`
  /// is a valid body but `""` fails the server's `min(1)`.
  Future<ApiResult<Order>> accept({
    required String offerId,
    String? deliveryLocation,
  }) {
    // Before the call, not after: this is what makes the latch _absorbAccept is
    // about to set belong to THIS offer, so re-entering it keeps the answer and
    // any other offer starts clean.
    beginEntity(offerId);
    // Through runWrite so the claim is taken only if this accept is actually
    // proceeding: claimed first, the second tap of a double tap would take the
    // latch away from the accept still in flight and that accept's answer would
    // then close Place Order on nothing, or fail to re-open it.
    return runWrite<Order, ApiResult<Order>>(
      _acceptWrite,
      () => _repo.acceptOffer(
        offerId: offerId,
        deliveryLocation: deliveryLocation,
      ),
      (r, claim) {
        if (claim.isCurrent) clearConflict();
        switch (r) {
          case Ok():
            requestStale.value = true;
          case Err(:final error):
            _absorbAccept(error, claim);
        }
        return r;
      },
    );
  }

  /// [claim] gates the PER-OFFER half only: the latch DISABLES Place Order, and
  /// on any offer but the one whose accept this was, nothing on screen could
  /// take it off again. [requestStale] is not per-offer — it says some mounted
  /// list has been overtaken by the server, which is true wherever the buyer
  /// now is — so a 409 sets it either way.
  void _absorbAccept(ApiError e, SlotClaim claim) {
    if (e.code == ApiErrorCode.conflict) requestStale.value = true;
    if (!claim.isCurrent) {
      absorbSuperseded(e);
      return;
    }
    if (e.code != ApiErrorCode.conflict) {
      absorb(e);
      return;
    }
    final kind = classifyConflict(e.message);
    conflict.value = kind;
    formError.value = switch (kind) {
      ConflictKind.offerNotAcceptable =>
        'That offer is no longer available. Here are the offers still open.',
      ConflictKind.requestAlreadyAccepted =>
        'You have already accepted an offer on this request.',
      _ => userMessageFor(e),
    };
  }
}

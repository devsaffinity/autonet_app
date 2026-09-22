import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart' show SubmittedReview;
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/domain/conflict_kind.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/order_steps.dart';
import 'package:autonect/domain/order_transitions.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// What a cancel attempt did, so the caller can act AFTER run()'s finally has
/// released the busy latch — a refetch launched from inside `then` would be
/// dropped by that very latch.
///
/// [abandoned] is not a failure: either the buyer left this order while the
/// PATCH was in flight — so its answer, the order and the notice and the error
/// alike, describes a screen that is no longer here — or this attempt was the
/// duplicate half of a double tap, and the PATCH the guard kept is still doing
/// the work and owns the screen.
enum _CancelOutcome { done, stale, failed, abandoned }

/// One order: its stepper, its cancel button and its review gate.
class OrderDetailController extends ApiController {
  OrderDetailController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final OrdersRepository _repo;

  static OrderDetailController ensure() =>
      Get.isRegistered<OrderDetailController>()
      ? Get.find<OrderDetailController>()
      : Get.put(OrderDetailController(Get.find<OrdersRepository>()));

  /// Everything on this screen — the part name, the status badge, the stepper,
  /// and the Cancel and Review gates that read [status] — is published from
  /// this ONE slot, so one claim decides for all of them at once.
  static const StateSlot _orderRead = StateSlot('order');

  final Rx<ViewState<Order>> order = Rx<ViewState<Order>>(const Loading());

  /// Not an error: the order moved on under us and we have already re-read it.
  final RxnString staleNotice = RxnString();

  String get _id => entityId ?? '';

  Order? get orderOrNull => switch (order.value) {
    Data<Order>(:final value) => value,
    _ => null,
  };

  OrderStatus? get status => orderOrNull?.status;

  List<OrderStep> get steps =>
      buildOrderSteps(status, orderOrNull?.events ?? const []);

  bool get canCancel => OrderTransitions.canBuyerCancel(status);

  bool get hasReviewed => orderOrNull?.hasReviewed ?? false;

  bool get canReview => status == OrderStatus.delivered && !hasReviewed;

  SubmittedReview? get review => orderOrNull?.buyerReview;

  /// Optimistically attaches the newly created review so the screen switches
  /// to the reviewed state immediately without waiting for the next network fetch.
  void recordReview(SubmittedReview review) {
    if (orderOrNull case final current?) {
      final updatedReviews = [
        review,
        ...current.reviews.where((r) => r.id != review.id),
      ];
      order.value = Data<Order>(current.copyWith(reviews: updatedReviews));
    }
  }

  /// Everything below the header belongs to ONE order. [staleNotice] is the
  /// dangerous half: it is written by a cancel and cleared by the next cancel,
  /// so on an order that is not cancellable the button that would clear it is
  /// never even rendered — order A's 'this just moved on' would sit under order
  /// B's title with nothing on the screen able to remove it.
  @override
  void resetForEntity() {
    staleNotice.value = null;
    order.value = const Loading();
  }

  Future<void> load(String id) {
    beginEntity(id);
    // Same order re-opened (initState, or StateView's retry): refresh under the
    // rows it already has rather than flashing a skeleton over correct data.
    if (order.value is! Data<Order>) order.value = const Loading();
    return _fetch();
  }

  /// Superseding, never dropped: the buyer who taps order A, backs out and taps
  /// order B is asking for B, and A's answer must not land on B's screen —
  /// where it would render A's part name and gate B's Cancel button on A's
  /// status while the cancel itself PATCHed B.
  Future<void> _fetch() => runRead(_orderRead, () => _repo.byId(_id), (r) {
    switch (r) {
      case Err(:final error):
        order.value = Failed<Order>(error);
      case Ok(:final value):
        order.value = Data<Order>(value);
    }
  });

  /// The buyer may only ever send CANCELLED, only from PLACED, and the note is
  /// mandatory — a blank one is a `.refine` 400 bound to `note`, so it is
  /// caught here rather than spent on a round trip.
  Future<bool> cancel(String note) async {
    final reason = note.trim();
    if (reason.isEmpty) {
      clearErrors();
      fieldErrors['note'] = 'Tell the supplier why you are cancelling';
      return false;
    }
    staleNotice.value = null;
    // The order this attempt describes, so the follow-up below can ask whether
    // the buyer is still looking at it. The claim cannot answer that: by then
    // it has resolved, and a claim answers 'may I publish?' only once.
    final cancelling = _id;
    // The PATCH answers with a NEWER order than any GET already in flight, so
    // it TAKES the slot: an earlier read must not land on top of the cancelled
    // order and hand the Cancel button back. runWrite, not run with a claim
    // taken beside it: a duplicate tap about to be dropped must take nothing.
    final outcome = await runWrite<Order, _CancelOutcome>(
      _orderRead,
      () => _repo.changeStatus(
        orderId: _id,
        status: OrderStatus.cancelled,
        note: reason,
      ),
      (r, claim) => switch (r) {
        // The PATCH response is the full re-fetched order WITH the appended
        // event, so a follow-up GET would only spend the limiter.
        Ok(:final value) =>
          claim.publish(() => order.value = Data<Order>(value))
              ? _CancelOutcome.done
              : _CancelOutcome.abandoned,
        Err(:final error) => _absorbCancel(error, claim),
      },
    );
    if (outcome == _CancelOutcome.stale && _id == cancelling) {
      staleNotice.value = 'This order just moved on — showing the latest.';
      await _fetch();
    }
    return outcome == _CancelOutcome.done;
  }

  _CancelOutcome _absorbCancel(ApiError e, SlotClaim claim) {
    // Every branch below writes something that belongs to ONE order — a red
    // line under its buttons, a notice above its stepper — so a superseded
    // answer publishes none of them.
    if (!claim.isCurrent) {
      absorbSuperseded(e);
      return _CancelOutcome.abandoned;
    }
    if (e.code != ApiErrorCode.conflict) {
      absorb(e);
      return _CancelOutcome.failed;
    }
    final kind = classifyConflict(e.message);
    if (kind == ConflictKind.staleRead) return _CancelOutcome.stale;
    // illegalTransition and notCancellable interpolate the live status
    // ('cannot be cancelled at PREPARING'), which is more useful than anything
    // this client could say instead.
    formError.value = userMessageFor(e);
    return _CancelOutcome.failed;
  }
}

import 'dart:async';

import 'package:autonect/controller/buyer/order_detail_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/domain/order_steps.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_buyer_repositories.dart';

Order _order(OrderStatus status, {List<OrderStatus> evented = const []}) =>
    Order.fromJson({
      'id': 'ord_1',
      'offerId': 'off_1',
      'requestId': 'req_1',
      'buyerId': 'usr_buyer',
      'supplierId': 'usr_sup1',
      'totalPence': 12999,
      'status': status.wire,
      'createdAt': '2026-09-02T09:00:00.000Z',
      'updatedAt': '2026-09-02T09:00:00.000Z',
      'offer': {'id': 'off_1', 'pricePence': 12999, 'quantity': 1},
      'request': {
        'id': 'req_1',
        'partName': 'Front brake discs',
        'regNumber': 'LM19XYZ',
      },
      'events': [
        for (var i = 0; i < evented.length; i++)
          {
            'id': 'evt_$i',
            'orderId': 'ord_1',
            'status': evented[i].wire,
            'at': '2026-09-0${i + 2}T09:00:00.000Z',
          },
      ],
    });

/// Holds the PATCH open, which is the only way to express 'the buyer tapped
/// Confirm twice before the first one came back'.
class _SlowOrders extends FakeOrdersRepository {
  final Completer<ApiResult<Order>> patch = Completer<ApiResult<Order>>();

  @override
  Future<ApiResult<Order>> changeStatus({
    required String orderId,
    required OrderStatus status,
    String? note,
  }) {
    calls.add('patch:$orderId:${status.wire}:$note');
    return patch.future;
  }
}

Err<Order> _conflict(String message) =>
    Err(ApiError(code: ApiErrorCode.conflict, statusCode: 409, message: message));

void main() {
  late FakeOrdersRepository repo;
  late OrderDetailController c;

  setUp(() {
    repo = FakeOrdersRepository();
    c = OrderDetailController(
      repo,
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    );
  });

  Future<void> loadAt(OrderStatus status) async {
    repo.byIdQueue.add(Ok(_order(status)));
    await c.load('ord_1');
  }

  test('canCancel is true ONLY at PLACED', () async {
    for (final s in OrderStatus.values) {
      final fresh = OrderDetailController(
        FakeOrdersRepository()..byIdResult = Ok(_order(s)),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await fresh.load('ord_1');
      expect(fresh.canCancel, s == OrderStatus.placed, reason: s.wire);
    }
  });

  test('canReview is true ONLY at DELIVERED', () async {
    for (final s in OrderStatus.values) {
      final fresh = OrderDetailController(
        FakeOrdersRepository()..byIdResult = Ok(_order(s)),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await fresh.load('ord_1');
      expect(fresh.canReview, s == OrderStatus.delivered, reason: s.wire);
    }
  });

  test('a blank note never reaches the repository', () async {
    await loadAt(OrderStatus.placed);
    final ok = await c.cancel('   ');
    // The server's .refine binds that 400 to `note`, so spending a round trip
    // on it buys nothing the client did not already know.
    expect(ok, isFalse);
    expect(repo.patchCalls, 0);
    expect(c.fieldErrorFor('note'), isNotNull);
  });

  test('a staleRead 409 triggers exactly ONE silent refetch', () async {
    repo.byIdQueue.addAll([
      Ok(_order(OrderStatus.placed)),
      Ok(_order(OrderStatus.preparing, evented: [OrderStatus.placed])),
    ]);
    repo.changeStatusResult = _conflict('Order changed concurrently, please retry');
    await c.load('ord_1');

    final ok = await c.cancel('Ordered the wrong side');
    expect(ok, isFalse);
    expect(repo.patchCalls, 1);
    // One load + one refetch, and no more: a retry loop here would hammer the
    // 300 req/60s limiter on an order that is simply moving.
    expect(repo.byIdCalls, 2);
    expect(c.status, OrderStatus.preparing);
    // Not an error — the order moved on and we are already showing the truth.
    expect(c.staleNotice.value, isNotNull);
    expect(c.formError.value, isNull);
  });

  test('notCancellable surfaces the server wording and does NOT refetch', () async {
    await loadAt(OrderStatus.placed);
    repo.changeStatusResult = _conflict('Order cannot be cancelled at PREPARING');

    final ok = await c.cancel('Changed my mind');
    expect(ok, isFalse);
    expect(c.formError.value, 'Order cannot be cancelled at PREPARING');
    expect(c.staleNotice.value, isNull);
    expect(repo.byIdCalls, 1);
  });

  test('a successful cancel renders the PATCH body with no follow-up GET', () async {
    await loadAt(OrderStatus.placed);
    repo.changeStatusResult = Ok(
      _order(OrderStatus.cancelled, evented: [OrderStatus.placed, OrderStatus.cancelled]),
    );

    final ok = await c.cancel('Ordered the wrong side');
    expect(ok, isTrue);
    expect(c.status, OrderStatus.cancelled);
    expect(repo.byIdCalls, 1);
    expect(repo.calls.last, 'patch:ord_1:CANCELLED:Ordered the wrong side');
    expect(c.steps.last.phase, StepPhase.cancelled);
  });

  test('a double tap cancels ONCE and the screen still ends on CANCELLED',
      () async {
    final slow = _SlowOrders()..byIdResult = Ok(_order(OrderStatus.placed));
    final c = OrderDetailController(slow,
        toast: (_) {}, showBusy: () {}, hideBusy: () {});
    await c.load('ord_1');

    // Both taps inside one frame: the first PATCH is still open when the
    // second arrives.
    final first = c.cancel('Ordered the wrong side');
    final second = c.cancel('Ordered the wrong side');

    // The guard is right and stays: one tap, one cancellation, one supplier
    // told about it.
    expect(slow.patchCalls, 1);
    expect(await second, isFalse);

    slow.patch.complete(Ok(_order(OrderStatus.cancelled,
        evented: [OrderStatus.placed, OrderStatus.cancelled])));

    // What was wrong was everything after: the dropped tap took the slot from
    // the PATCH in flight, so this genuinely successful cancel was discarded
    // as superseded and the screen went on offering to cancel an order the
    // server had already cancelled.
    expect(await first, isTrue);
    expect(c.status, OrderStatus.cancelled);
    expect(c.canCancel, isFalse);
    expect(c.formError.value, isNull);
  });

  /// Drives the ONE thing that writes [staleNotice] — a staleRead 409 on a
  /// cancel — so the cross-order tests below start from the real state.
  Future<void> staleCancelOnOrd1() async {
    repo.byIdQueue.addAll([
      Ok(_order(OrderStatus.placed)),
      Ok(_order(OrderStatus.preparing, evented: [OrderStatus.placed])),
    ]);
    repo.changeStatusResult = _conflict('Order changed concurrently, please retry');
    await c.load('ord_1');
    await c.cancel('Ordered the wrong side');
    expect(c.staleNotice.value, isNotNull, reason: 'precondition');
  }

  test("order A's stale notice never appears on order B", () async {
    await staleCancelOnOrd1();
    // B is DELIVERED, so `canCancel` is false and the cancel dialog — the only
    // other code that clears staleNotice — is not even rendered on it.
    repo.byIdResult = Ok(_order(OrderStatus.delivered));
    await c.load('ord_2');
    expect(c.staleNotice.value, isNull);
    expect(c.canCancel, isFalse, reason: 'nothing on B could have cleared it');
  });

  test('a DIFFERENT order blanks the previous one instead of aliasing it',
      () async {
    await loadAt(OrderStatus.placed);
    // Asserted BEFORE the await: the screen rebuilds the moment load() is
    // called, and A's stepper with A's live Cancel button under B's title is
    // the same leak as the notice.
    final pending = c.load('ord_2');
    expect(c.order.value, isA<Loading<Order>>());
    expect(c.canCancel, isFalse);
    await pending;
  });

  test('re-opening the SAME order keeps its rows and its notice', () async {
    await staleCancelOnOrd1();
    repo.byIdQueue.add(Ok(_order(OrderStatus.preparing)));
    final pending = c.load('ord_1');
    // No skeleton over rows that are still correct, and the notice is still
    // true of THIS order — clearing it would be the over-eager half of the bug.
    expect(c.order.value, isA<Data<Order>>());
    await pending;
    expect(c.staleNotice.value, isNotNull);
  });

  test('a failed load becomes Failed and leaves both gates shut', () async {
    repo.byIdResult = const Err(ApiError.network());
    await c.load('ord_1');
    expect(c.order.value, isA<Failed<Order>>());
    expect(c.canCancel, isFalse);
    expect(c.canReview, isFalse);
    expect(c.steps.every((s) => s.phase == StepPhase.pending), isTrue);
  });
}

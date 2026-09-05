import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/domain/order_steps.dart';
import 'package:flutter_test/flutter_test.dart';

OrderEvent event(OrderStatus status, int day, {String? note}) => OrderEvent(
  id: 'evt_${status.wire}',
  orderId: 'ord_1',
  status: status,
  note: note,
  at: DateTime.utc(2026, 9, day, 10),
);

List<StepPhase> phases(List<OrderStep> steps) =>
    steps.map((s) => s.phase).toList();

void main() {
  group('buildOrderSteps', () {
    test('PLACED only -> current then three pending', () {
      final steps = buildOrderSteps(OrderStatus.placed, [
        event(OrderStatus.placed, 1),
      ]);
      expect(phases(steps), [
        StepPhase.current,
        StepPhase.pending,
        StepPhase.pending,
        StepPhase.pending,
      ]);
      expect(steps.map((s) => s.title).toList(), [
        'Order Placed',
        'Preparing Order',
        'Out for Delivery',
        'Delivered',
      ]);
    });

    test('the happy path is three done and a current DELIVERED', () {
      final steps = buildOrderSteps(OrderStatus.delivered, [
        event(OrderStatus.placed, 1),
        event(OrderStatus.preparing, 2),
        event(OrderStatus.outForDelivery, 3),
        event(OrderStatus.delivered, 4),
      ]);
      expect(phases(steps), [
        StepPhase.done,
        StepPhase.done,
        StepPhase.done,
        StepPhase.current,
      ]);
    });

    test('THE ADMIN JUMP: DELIVERED with only a PLACED event skips 1 and 2', () {
      final steps = buildOrderSteps(OrderStatus.delivered, [
        event(OrderStatus.placed, 1),
      ]);
      expect(steps, hasLength(4));
      expect(steps[0].phase, StepPhase.done);
      expect(steps[1].phase, StepPhase.skipped);
      expect(steps[2].phase, StepPhase.skipped);
      expect(steps[3].phase, StepPhase.current);
    });

    test('CANCELLED at PLACED collapses the tail into one cancelled step', () {
      final steps = buildOrderSteps(OrderStatus.cancelled, [
        event(OrderStatus.placed, 1),
        event(OrderStatus.cancelled, 2, note: 'Buyer changed their mind'),
      ]);
      expect(steps, hasLength(2));
      expect(steps[0].phase, StepPhase.done);
      expect(steps[1].phase, StepPhase.cancelled);
      expect(steps[1].title, 'Cancelled');
      expect(steps[1].subtitle, contains('Buyer changed their mind'));
    });

    test('CANCELLED mid-path keeps only the rows that happened', () {
      final steps = buildOrderSteps(OrderStatus.cancelled, [
        event(OrderStatus.placed, 1),
        event(OrderStatus.preparing, 2),
        event(OrderStatus.cancelled, 3, note: 'Out of stock'),
      ]);
      expect(steps, hasLength(3));
      expect(phases(steps), [
        StepPhase.done,
        StepPhase.done,
        StepPhase.cancelled,
      ]);
    });

    test('an unknown status (null) leaves every row pending, no throw', () {
      final steps = buildOrderSteps(null, const []);
      expect(phases(steps), List.filled(4, StepPhase.pending));
    });

    test('subtitles come from the event, never a hard-coded date', () {
      final steps = buildOrderSteps(OrderStatus.preparing, [
        event(OrderStatus.placed, 1),
      ]);
      expect(steps[0].subtitle, contains('2026'));
      expect(steps[1].subtitle, isNull, reason: 'no event, no subtitle');
    });
  });
}

/// The order stepper, derived from the order's status and its event history.
///
/// There is exactly one stepper implementation in the app and this is it; §3
/// counts two pre-existing ones as debt not to add to.
library;

import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';

/// FIVE members, and [skipped] is the load-bearing one.
///
/// An admin can force any order straight to CANCELLED or DELIVERED
/// (admin-marketplace.routes.ts), so a buyer can legitimately observe
/// PLACED -> DELIVERED with no PREPARING event ever written. Rendering those
/// rows as [done] would assert a completion the backend never produced;
/// rendering them [pending] behind a DELIVERED head is incoherent.
enum StepPhase { done, current, pending, skipped, cancelled }

class OrderStep {
  const OrderStep({required this.title, required this.phase, this.subtitle});

  final String title;
  final String? subtitle;
  final StepPhase phase;
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _stamp(DateTime at) {
  final t = at.toLocal();
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${_months[t.month - 1]} ${t.year}, $hh:$mm';
}

/// Never a hard-coded date: the timestamp comes from the event the server sent.
String _subtitleFor(OrderEvent e) {
  final note = e.note?.trim() ?? '';
  final stamp = _stamp(e.at);
  return note.isEmpty ? stamp : '$stamp · $note';
}

/// Builds the rows for [OrderStatus.forwardPath], or the truncated history plus
/// one cancellation row when the order was cancelled.
List<OrderStep> buildOrderSteps(OrderStatus? current, List<OrderEvent> events) {
  OrderEvent? eventFor(OrderStatus s) {
    for (final e in events) {
      if (e.status == s) return e;
    }
    return null;
  }

  final path = OrderStatus.forwardPath;

  if (current == OrderStatus.cancelled) {
    var lastEvented = -1;
    for (var i = 0; i < path.length; i++) {
      if (eventFor(path[i]) != null) lastEvented = i;
    }
    final steps = <OrderStep>[];
    for (var i = 0; i <= lastEvented; i++) {
      final e = eventFor(path[i]);
      steps.add(OrderStep(
        title: path[i].label,
        subtitle: e == null ? null : _subtitleFor(e),
        phase: e == null ? StepPhase.skipped : StepPhase.done,
      ));
    }
    final cancelEvent = eventFor(OrderStatus.cancelled);
    steps.add(OrderStep(
      title: OrderStatus.cancelled.label,
      subtitle: cancelEvent == null ? null : _subtitleFor(cancelEvent),
      phase: StepPhase.cancelled,
    ));
    return steps;
  }

  final currentIndex = current == null ? -1 : path.indexOf(current);
  final steps = <OrderStep>[];
  for (var i = 0; i < path.length; i++) {
    final status = path[i];
    final e = eventFor(status);
    final StepPhase phase;
    if (status == current) {
      phase = StepPhase.current;
    } else if (e != null) {
      phase = StepPhase.done;
    } else if (i < currentIndex) {
      // The admin jump: the head is ahead of a row that never happened.
      phase = StepPhase.skipped;
    } else {
      phase = StepPhase.pending;
    }
    steps.add(OrderStep(
      title: status.label,
      subtitle: e == null ? null : _subtitleFor(e),
      phase: phase,
    ));
  }
  return steps;
}

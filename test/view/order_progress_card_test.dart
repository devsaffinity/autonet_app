import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/domain/order_steps.dart';
import 'package:autonect/view/widget/order_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The stepper's job is to tell the truth about what the backend recorded.
/// `skipped` exists because an admin can force PLACED -> DELIVERED, and these
/// tests are what stop a future refactor from folding it back into `done`.
void main() {
  Widget host(List<OrderStep> steps) => MaterialApp(
    home: Scaffold(body: OrderProgressCard(steps: steps)),
  );

  testWidgets('four done steps render four ticks', (t) async {
    await t.pumpWidget(host(const [
      OrderStep(title: 'Order Placed', phase: StepPhase.done),
      OrderStep(title: 'Preparing Order', phase: StepPhase.done),
      OrderStep(title: 'Out for Delivery', phase: StepPhase.done),
      OrderStep(title: 'Delivered', phase: StepPhase.done),
    ]));
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(4));
  });

  testWidgets('a skipped step is muted, subtitled and NEVER ticked', (t) async {
    await t.pumpWidget(host(const [
      OrderStep(title: 'Order Placed', phase: StepPhase.done),
      OrderStep(title: 'Preparing Order', phase: StepPhase.skipped),
      OrderStep(title: 'Delivered', phase: StepPhase.current),
    ]));

    // One tick only — the skipped row must not claim a completion.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.text('Not recorded'), findsOneWidget);

    final skipped = t.widget<Text>(find.text('Preparing Order'));
    expect(skipped.style?.color, kGreyTextColor);

    // ...and the row it was skipped past is still painted as reached.
    final done = t.widget<Text>(find.text('Order Placed'));
    expect(done.style?.color, kSuccessColor);
  });

  testWidgets('a cancelled step renders in kRedColor with its note', (t) async {
    await t.pumpWidget(host(const [
      OrderStep(
        title: 'Order Placed',
        phase: StepPhase.done,
        subtitle: '3 Sep 2026, 09:15',
      ),
      OrderStep(
        title: 'Cancelled',
        phase: StepPhase.cancelled,
        subtitle: '3 Sep 2026, 10:02 · Buyer changed their mind',
      ),
    ]));

    final cancelled = t.widget<Text>(find.text('Cancelled'));
    expect(cancelled.style?.color, kRedColor);
    expect(
      find.text('3 Sep 2026, 10:02 · Buyer changed their mind'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}

import 'package:autonect/domain/billing_confirmation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_billing.dart';

/// A purchase is done when the SERVER says so — never on the sheet's word.
void main() {
  final started = DateTime(2026, 9, 18, 12);

  PendingConfirmation pending(PurchaseKind kind, {String key = kLeads5, int baseline = 2}) => PendingConfirmation(
    kind: kind,
    lookupKey: key,
    planName: '',
    baselineCredits: baseline,
    startedAt: started,
  );

  test('credits: confirmed when the balance goes up', () {
    final p = pending(PurchaseKind.credits);
    expect(p.isSatisfiedBy(billingStatus(rank: 1, credits: 2)), isFalse);
    expect(p.isSatisfiedBy(billingStatus(rank: 1, credits: 7)), isTrue);
  });

  test('never while the server still says processing', () {
    final p = pending(PurchaseKind.credits);
    expect(p.isSatisfiedBy(billingStatus(rank: 1, credits: 7, display: 'PROCESSING')), isFalse);
  });

  test('subscription: confirmed only for the plan that was bought', () {
    final p = pending(PurchaseKind.subscription, key: kElectricianPro);
    expect(p.isSatisfiedBy(billingStatus()), isFalse);
    expect(p.isSatisfiedBy(billingStatus(rank: 2, display: 'ACTIVE_RENEWING')), isTrue);
    expect(
      pending(PurchaseKind.subscription, key: 'another-plan').isSatisfiedBy(billingStatus(rank: 2, display: 'ACTIVE_RENEWING')),
      isFalse,
    );
  });

  test('recovery: confirmed once no longer past due', () {
    final p = pending(PurchaseKind.recovery, key: 'retry');
    expect(p.isSatisfiedBy(billingStatus(rank: 2, display: 'PAST_DUE')), isFalse);
    expect(p.isSatisfiedBy(billingStatus(rank: 2, display: 'ACTIVE_RENEWING')), isTrue);
  });

  test('expires after its max age', () {
    final p = pending(PurchaseKind.credits);
    expect(p.isExpired(started.add(const Duration(minutes: 9))), isFalse);
    expect(p.isExpired(started.add(PendingConfirmation.maxAge + const Duration(seconds: 1))), isTrue);
  });

  test('the poll schedule is about half a minute', () {
    final total = kConfirmSchedule.fold(Duration.zero, (a, b) => a + b);
    expect(total.inSeconds, inInclusiveRange(20, 40));
  });
}

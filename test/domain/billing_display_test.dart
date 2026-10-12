import 'package:autonect/domain/billing_confirmation.dart';
import 'package:autonect/domain/billing_display.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_billing.dart';

/// The banner and dialog copy both roles' screens show — every promise dated
/// and priced from the server's status, never assumed.
void main() {
  const e = BillingAudience.electrician;
  const s = BillingAudience.supplier;

  group('levelLabel', () {
    test('per role, as the design names them', () {
      expect([0, 1, 2].map((r) => levelLabel(r, e)), ['Free', 'Pay-Per-Lead', 'Pro (Monthly)']);
      expect([0, 1, 2].map((r) => levelLabel(r, s)), ['Standard', 'Pay-Per-Lead', 'Pro Unlimited']);
    });
  });

  group('describeBilling', () {
    test('free electrician is told how to accept leads', () {
      final b = describeBilling(billingStatus(), e);
      expect(b.title, 'Free');
      expect(b.tone, BannerTone.neutral);
      expect(b.detail, 'Choose Pay-Per-Lead or Pro to accept client leads.');
    });

    test('standard supplier sees their balance', () {
      final b = describeBilling(billingStatus(supplier: true, credits: 1), s);
      expect(b.pill, 'STANDARD');
      expect(b.detail, '1 credit available');
    });

    test('pay-per-lead shows the balance in the audience unit', () {
      expect(describeBilling(billingStatus(rank: 1, credits: 3), e).detail, '3 lead credits available');
      expect(describeBilling(billingStatus(supplier: true, rank: 1, credits: 3), s).detail, '3 credits available');
    });

    test('renewing: dated and priced', () {
      final b = describeBilling(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'), e);
      expect(b.pill, 'ACTIVE');
      expect(b.title, 'Pro (Monthly)');
      expect(b.detail, 'Renews on 18 November 2026 · £149/mo');
      expect(describeBilling(billingStatus(supplier: true, rank: 2, display: 'ACTIVE_RENEWING'), s).pill, 'ACTIVE PRO');
    });

    test('cancelling: the end date and that resume is possible', () {
      final b = describeBilling(billingStatus(rank: 2, display: 'ACTIVE_CANCELLING'), e);
      expect(b.pill, 'CANCELLING');
      expect(b.tone, BannerTone.warning);
      expect(b.detail, 'Ends on 18 November 2026 — you can resume until then.');
    });

    test('past due: critical, with the grace deadline', () {
      final b = describeBilling(billingStatus(rank: 2, display: 'PAST_DUE'), e);
      expect(b.pill, 'PAYMENT FAILED');
      expect(b.tone, BannerTone.critical);
      expect(
        b.detail,
        'Your last payment failed. Update your payment method in the store by 18 November 2026 to keep Pro.',
      );
    });

    test('admin trial', () {
      final b = describeBilling(billingStatus(rank: 2, display: 'TRIALING'), e);
      expect(b.pill, 'TRIAL');
      expect(b.detail, 'Free trial until 18 November 2026');
    });

    test('processing on the server, or awaiting confirmation locally', () {
      final server = describeBilling(billingStatus(display: 'PROCESSING'), e);
      expect(server.pill, 'PROCESSING');
      expect(server.busy, isTrue);

      final local = describeBilling(
        billingStatus(),
        e,
        awaiting: PendingConfirmation(
          kind: PurchaseKind.subscription,
          lookupKey: kElectricianPro,
          planName: 'Electrician Pro (Monthly)',
          baselineCredits: 0,
          startedAt: DateTime(2026, 9, 18),
        ),
      );
      expect(local.title, 'Electrician Pro (Monthly)');
      expect(local.detail, 'Confirming your payment…');
    });
  });

  group('dialogs', () {
    test('cancel names the end date and what the plan falls back to', () {
      expect(
        cancelWarning(billingStatus(rank: 2, baseRank: 1, display: 'ACTIVE_RENEWING'), e),
        'Cancelling happens in the store that charges you. You keep unlimited leads and your PRO badge '
        'until 18 November 2026, and after that your plan becomes Pay-Per-Lead.',
      );
      expect(
        cancelWarning(billingStatus(supplier: true, rank: 2, display: 'ACTIVE_RENEWING'), s),
        contains('after that your plan becomes Standard.'),
      );
    });

    test('resume names the next charge', () {
      expect(
        resumeWarning(billingStatus(rank: 2, display: 'ACTIVE_CANCELLING')),
        'Resubscribe in the store before 18 November 2026 and your plan continues uninterrupted, '
        'renewing with the usual payment of £149.',
      );
    });
  });
}

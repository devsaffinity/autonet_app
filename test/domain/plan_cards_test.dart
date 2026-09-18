import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/domain/plan_cards.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_billing.dart';

/// Free < Pay-Per-Lead < Pro: the cards only ever offer a move UP, and only
/// the moves the server said are allowed.
void main() {
  group('electricianTierCards', () {
    test('free: Free is current, both upgrades offered at server prices', () {
      final c = electricianTierCards(billingStatus(), busy: false);

      expect(c.free.isCurrent, isTrue);
      expect(c.free.buttonText, 'Current Plan');
      expect(c.pro.price, '£149');
      expect(c.pro.buttonText, 'Upgrade to Pro');
      expect(c.pro.action, TierAction.subscribe);
      expect(c.pro.enabled, isTrue);
      expect(c.payPerLead.price, '£12', reason: 'the single-credit pack is the per-lead price');
      expect(c.payPerLead.buttonText, 'Choose Credits');
      expect(c.payPerLead.enabled, isTrue);
    });

    test('pay-per-lead: Free is included, never a downgrade target', () {
      final c = electricianTierCards(billingStatus(rank: 1, baseRank: 1, credits: 2), busy: false);

      expect(c.free.buttonText, 'Included');
      expect(c.free.action, TierAction.none);
      expect(c.free.enabled, isFalse);
      expect(c.payPerLead.isCurrent, isTrue);
      expect(c.payPerLead.buttonText, 'Top-Up Credits');
      expect(c.pro.buttonText, 'Upgrade to Pro');
    });

    test('pro renewing: manage; packs included; free not selectable', () {
      final c = electricianTierCards(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'), busy: false);

      expect(c.pro.isCurrent, isTrue);
      expect(c.pro.buttonText, 'Manage / Cancel');
      expect(c.pro.action, TierAction.manage);
      expect(c.payPerLead.buttonText, 'Included in Pro');
      expect(c.payPerLead.enabled, isFalse);
      expect(c.free.enabled, isFalse);
    });

    test('pro cancelling: resume', () {
      final c = electricianTierCards(billingStatus(rank: 2, display: 'ACTIVE_CANCELLING'), busy: false);
      expect(c.pro.buttonText, 'Resume Pro');
      expect(c.pro.action, TierAction.resume);
    });

    test('pro past due: fix payment', () {
      final c = electricianTierCards(billingStatus(rank: 2, display: 'PAST_DUE'), busy: false);
      expect(c.pro.buttonText, 'Update Payment');
      expect(c.pro.action, TierAction.fixPayment);
    });

    test('busy: every purchase is inert and says so', () {
      final c = electricianTierCards(billingStatus(), busy: true);
      expect(c.pro.enabled, isFalse);
      expect(c.pro.buttonText, 'Processing…');
      expect(c.payPerLead.enabled, isFalse);
    });

    test('a refused upgrade is disabled', () {
      final c = electricianTierCards(
        billingStatus(plans: [planJson(kElectricianPro, name: 'Pro', pricePence: 14900, subscription: true, allowed: false, reason: 'No')]),
        busy: false,
      );
      expect(c.pro.enabled, isFalse);
    });

    test('no plans priced yet: shown as unavailable, never a made-up price', () {
      final c = electricianTierCards(billingStatus(plans: const []), busy: false);
      expect(c.pro.price, '—');
      expect(c.pro.buttonText, 'Currently unavailable');
      expect(c.pro.enabled, isFalse);
      expect(c.payPerLead.price, '—');
      expect(c.payPerLead.enabled, isFalse);
    });

    test('without a single-credit pack, the cheapest per-lead price', () {
      final c = electricianTierCards(
        billingStatus(
          plans: [
            planJson(kLeads5, name: '5', pricePence: 5500, credits: 5),
            planJson('electrician-leads-10', name: '10', pricePence: 10000, credits: 10),
          ],
        ),
        busy: false,
      );
      expect(c.payPerLead.price, '£10');
    });
  });

  group('registrationTierCards', () {
    const plans = [
      BillingPlan(id: '1', lookupKey: kElectricianPro, name: 'Pro', pricePence: 14900, interval: PlanInterval.month),
      BillingPlan(id: '2', lookupKey: kLead1, name: '1', pricePence: 1200, interval: PlanInterval.oneTime, credits: 1),
    ];

    test('Pro is shown priced but cannot be chosen', () {
      final c = registrationTierCards(plans, selectedTier: 'FREE');
      expect(c.pro.price, '£149');
      expect(c.pro.buttonText, 'Available after approval');
      expect(c.pro.enabled, isFalse);
      expect(c.pro.action, TierAction.none);
    });

    test('Free and Pay-Per-Lead are the choices; the selection is marked', () {
      final c = registrationTierCards(plans, selectedTier: 'PAY_PER_LEAD');
      expect(c.free.action, TierAction.chooseFree);
      expect(c.free.isCurrent, isFalse);
      expect(c.payPerLead.action, TierAction.choosePayPerLead);
      expect(c.payPerLead.isCurrent, isTrue);
      expect(c.payPerLead.price, '£12');
    });
  });
}

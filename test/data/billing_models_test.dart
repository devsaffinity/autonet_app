import 'package:autonect/data/models/billing_checkout.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_billing.dart';

/// The app renders `GET /v1/billing/status` directly, so decoding is lenient
/// where a bad value can be ignored (an unknown state shows nothing) and
/// strict where it cannot (a sheet with no client secret must not open).
void main() {
  group('BillingStatus.fromJson', () {
    test('decodes a subscribed electrician', () {
      final s = BillingStatus.fromJson(statusJson(rank: 2, baseRank: 1, credits: 3, display: 'ACTIVE_RENEWING'));

      expect(s.level.code, 'PRO');
      expect(s.level.rank, 2);
      expect(s.baseLevel.code, 'PAY_PER_LEAD');
      expect(s.credits, 3);
      expect(s.isSubscribed, isTrue);
      expect(s.displayState, BillingDisplayState.activeRenewing);
      expect(s.displayDate, DateTime.utc(2026, 11, 18, 12).toLocal());
      expect(s.canCancel, isTrue);
      expect(s.canResume, isFalse);

      final sub = s.subscription!;
      expect(sub.status, 'ACTIVE');
      expect(sub.planLookupKey, kElectricianPro);
      expect(sub.pricePence, 14900);
      expect(sub.interval, PlanInterval.month);
      expect(sub.cancelAtPeriodEnd, isFalse);
    });

    test('offers carry the server verdict; packs sorted smallest first', () {
      final s = BillingStatus.fromJson(
        statusJson(
          plans: [
            planJson(kLeads5, name: '5 Lead Credits', pricePence: 5500, productId: 'autonect_test_product', credits: 5),
            planJson(kElectricianPro, name: 'Pro', pricePence: 14900, productId: 'autonect_test_product', subscription: true),
            planJson(kLead1, name: '1 Lead Credit', pricePence: 1200, productId: 'autonect_test_product', credits: 1, allowed: false, reason: 'No.'),
          ],
        ),
      );

      expect(s.subscriptionOffer?.lookupKey, kElectricianPro);
      expect(s.subscriptionOffer?.action, PlanAction.subscribe);
      expect(s.creditPacks.map((p) => p.lookupKey), [kLead1, kLeads5]);
      final refused = s.offer(kLead1)!;
      expect(refused.allowed, isFalse);
      expect(refused.action, isNull);
      expect(refused.reason, 'No.');
      expect(s.offer('missing'), isNull);
    });

    test('the current subscription wins over a cheaper one on offer', () {
      final s = BillingStatus.fromJson(
        statusJson(
          plans: [
            planJson('basic', name: 'Basic', pricePence: 900, productId: 'autonect_basic', subscription: true),
            {...planJson('plus', name: 'Plus', pricePence: 1900, productId: 'autonect_plus', subscription: true, current: true), 'rank': 20},
          ],
        ),
      );
      expect(s.subscriptionOffer?.lookupKey, 'plus');
    });

    test('unknown state reads as none; malformed plan rows are dropped', () {
      final j = statusJson(credits: 1)
        ..['display'] = {'state': 'SOMETHING_NEW', 'date': 'not a date'}
        ..['plans'] = [
          {'lookupKey': 'no-price'},
          'garbage',
          planJson(kLead1, name: '1 Lead Credit', pricePence: 1200, productId: 'autonect_test_product', credits: 1),
        ];
      final s = BillingStatus.fromJson(j);
      expect(s.displayState, BillingDisplayState.none);
      expect(s.displayDate, isNull);
      expect(s.offers.map((o) => o.lookupKey), [kLead1]);
    });

    test('a bare body decodes to a safe empty status', () {
      final s = BillingStatus.fromJson(const {});
      expect(s.level.rank, 0);
      expect(s.credits, 0);
      expect(s.subscription, isNull);
      expect(s.offers, isEmpty);
      expect(s.subscriptionOffer, isNull);
      expect(s.isProcessing, isFalse);
    });

    test('pending marker', () {
      final s = BillingStatus.fromJson(
        statusJson(display: 'PROCESSING', pending: {'kind': 'CREDITS', 'lookupKey': kLeads5, 'since': '2026-09-18T12:00:00Z'}),
      );
      expect(s.isProcessing, isTrue);
      expect(s.pendingKind, 'CREDITS');
      expect(s.pendingLookupKey, kLeads5);
    });
  });

  group('BillingConfig', () {
    test('decodes the store keys and the entitlement to look for', () {
      final c = BillingConfig.fromJson({
        'provider': 'revenuecat',
        'androidApiKey': 'goog_abc',
        'iosApiKey': 'appl_abc',
        'entitlement': 'pro',
        'offering': 'default',
      });
      expect(c.androidApiKey, 'goog_abc');
      expect(c.iosApiKey, 'appl_abc');
      expect(c.entitlement, 'pro');
      expect(c.hasAnyKey, isTrue);
    });

    test('one store configured is enough to sell on that store', () {
      final c = BillingConfig.fromJson({'androidApiKey': 'goog_abc', 'iosApiKey': null});
      expect(c.iosApiKey, isNull);
      expect(c.hasAnyKey, isTrue);
    });

    test('refuses a config with no store key at all', () {
      expect(() => BillingConfig.fromJson({'androidApiKey': '', 'iosApiKey': null}), throwsFormatException);
      expect(() => BillingConfig.fromJson(const {}), throwsFormatException);
    });
  });

  group('store product ids', () {
    test('an offer knows what each store sells it as', () {
      final s = BillingStatus.fromJson(
        statusJson(plans: [planJson(kLeads5, name: '5', pricePence: 5500, productId: 'autonect_leads_5', credits: 5)]),
      );
      final offer = s.offer(kLeads5)!;
      expect(offer.storeProductId(ios: false), 'autonect_leads_5');
      expect(offer.storeProductId(ios: true), 'autonect_leads_5');
    });

    test('the manage URL comes from the server, not built in the app', () {
      final s = BillingStatus.fromJson(statusJson(rank: 2, display: 'ACTIVE_RENEWING'));
      expect(s.manageUrl, kManageUrl);
      expect(BillingStatus.fromJson(statusJson()).manageUrl, isNull);
    });
  });
}

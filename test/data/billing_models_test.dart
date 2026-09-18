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
      expect(s.displayDate, DateTime.utc(2026, 10, 18, 12).toLocal());
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
            planJson(kLeads5, name: '5 Lead Credits', pricePence: 5500, credits: 5),
            planJson(kElectricianPro, name: 'Pro', pricePence: 14900, subscription: true),
            planJson(kLead1, name: '1 Lead Credit', pricePence: 1200, credits: 1, allowed: false, reason: 'No.'),
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
            planJson('basic', name: 'Basic', pricePence: 900, subscription: true),
            {...planJson('plus', name: 'Plus', pricePence: 1900, subscription: true, current: true), 'rank': 20},
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
          planJson(kLead1, name: '1 Lead Credit', pricePence: 1200, credits: 1),
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
    test('decodes and knows test mode from the key', () {
      final c = BillingConfig.fromJson({
        'publishableKey': 'pk_test_abc',
        'merchantDisplayName': 'Autonect',
        'merchantCountryCode': 'GB',
        'currency': 'gbp',
        'livemode': false,
      });
      expect(c.isTestMode, isTrue);
      expect(BillingConfig.fromJson({'publishableKey': 'pk_live_abc'}).isTestMode, isFalse);
    });

    test('refuses a config without a key', () {
      expect(() => BillingConfig.fromJson({'publishableKey': ''}), throwsFormatException);
      expect(() => BillingConfig.fromJson(const {}), throwsFormatException);
    });
  });

  group('PaymentSheetSession', () {
    Map<String, dynamic> body({bool requiresPayment = true, String? clientSecret = 'pi_1_secret'}) => {
      'mode': 'payment',
      'requiresPayment': requiresPayment,
      'clientSecret': clientSecret,
      'paymentIntentId': 'pi_1',
      'subscriptionId': null,
      'customerId': 'cus_1',
      'customerSessionClientSecret': 'cuss_1',
      'ephemeralKeySecret': null,
      'publishableKey': 'pk_test_abc',
      'amountPence': 5500,
      'plan': {'lookupKey': kLeads5, 'name': '5 Lead Credits'},
    };

    test('decodes a credits sheet', () {
      final s = PaymentSheetSession.fromJson(body());
      expect(s.isSubscription, isFalse);
      expect(s.requiresPayment, isTrue);
      expect(s.paymentIntentId, 'pi_1');
      expect(s.customerSessionClientSecret, 'cuss_1');
      expect(s.planLookupKey, kLeads5);
      expect(s.amountPence, 5500);
    });

    test('a subscription sheet', () {
      final s = PaymentSheetSession.fromJson({...body(), 'mode': 'subscription', 'subscriptionId': 'sub_1'});
      expect(s.isSubscription, isTrue);
      expect(s.subscriptionId, 'sub_1');
    });

    test('a payment owed with no client secret is refused', () {
      expect(() => PaymentSheetSession.fromJson(body(clientSecret: null)), throwsFormatException);
      expect(() => PaymentSheetSession.fromJson(body(clientSecret: '')), throwsFormatException);
    });

    test('nothing owed needs no client secret', () {
      final s = PaymentSheetSession.fromJson(body(requiresPayment: false, clientSecret: null));
      expect(s.requiresPayment, isFalse);
      expect(s.clientSecret, isNull);
    });
  });
}

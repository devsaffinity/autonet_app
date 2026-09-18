import 'dart:convert';

import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/data/repositories/billing_api_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_billing.dart';
import '../fakes/fake_transport.dart';

/// The wire contract with `/v1/billing` — the paths and bodies the backend's
/// routes validate, and the envelopes they answer with.
void main() {
  late FakeTransport t;
  late BillingApiRepository repo;

  String ok(Object data) => jsonEncode({'success': true, 'data': data});

  Map<String, dynamic> sentBody(String method, String path) {
    final body = t.lastOf(method, path)?.body;
    return body == null ? const {} : (jsonDecode(body) as Map).cast<String, dynamic>();
  }

  final session = {
    'mode': 'subscription',
    'requiresPayment': true,
    'clientSecret': 'pi_1_secret',
    'paymentIntentId': 'pi_1',
    'subscriptionId': 'sub_1',
    'customerId': 'cus_1',
    'customerSessionClientSecret': 'cuss_1',
    'amountPence': 14900,
    'plan': {'lookupKey': kElectricianPro, 'name': 'Electrician Pro (Monthly)'},
  };

  setUp(() {
    t = FakeTransport();
    final tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
    repo = BillingApiRepository(ApiClient(transport: t, baseUrl: 'http://test.local', tokens: tokens), tokens);
  });

  test('config', () async {
    t.on('GET', '/v1/billing/config', body: ok({'publishableKey': 'pk_test_x', 'livemode': false}));
    final r = await repo.config();
    expect((r as Ok).value.publishableKey, 'pk_test_x');
  });

  test('config without a key is a malformed response, not a crash', () async {
    t.on('GET', '/v1/billing/config', body: ok({'publishableKey': null}));
    final r = await repo.config();
    expect((r as Err).error.code, ApiErrorCode.malformedResponse);
  });

  test('status', () async {
    t.on('GET', '/v1/billing/status', body: ok(statusJson(rank: 1, baseRank: 1, credits: 9)));
    final r = await repo.status();
    final s = (r as Ok<BillingStatus>).value;
    expect(s.credits, 9);
    expect(s.creditPacks, isNotEmpty);
  });

  test('sync sends only the ids it has', () async {
    t.on('POST', '/v1/billing/sync', body: ok(statusJson()));
    await repo.sync(paymentIntentId: 'pi_1');
    expect(sentBody('POST', '/v1/billing/sync'), {'paymentIntentId': 'pi_1'});

    await repo.sync(subscriptionId: 'sub_1');
    expect(sentBody('POST', '/v1/billing/sync'), {'subscriptionId': 'sub_1'});
  });

  test('credits intent', () async {
    t.on('POST', '/v1/billing/credits/intent', body: ok({...session, 'mode': 'payment', 'subscriptionId': null}));
    final r = await repo.createCreditsIntent(kLeads5);
    expect(sentBody('POST', '/v1/billing/credits/intent'), {'lookupKey': kLeads5});
    expect((r as Ok).value.paymentIntentId, 'pi_1');
  });

  test('subscription', () async {
    t.on('POST', '/v1/billing/subscriptions', body: ok(session));
    final r = await repo.createSubscription(kElectricianPro);
    expect(sentBody('POST', '/v1/billing/subscriptions'), {'lookupKey': kElectricianPro});
    expect((r as Ok).value.subscriptionId, 'sub_1');
  });

  test('a refused upgrade is a 409 conflict with the server message', () async {
    t.on(
      'POST',
      '/v1/billing/subscriptions',
      status: 409,
      body: errorBody('CONFLICT', 'You already have this plan.'),
    );
    final r = await repo.createSubscription(kElectricianPro);
    final e = (r as Err).error;
    expect(e.code, ApiErrorCode.conflict);
    expect(e.message, 'You already have this plan.');
  });

  test('retry payment', () async {
    t.on('POST', '/v1/billing/subscriptions/retry-payment', body: ok(session));
    final r = await repo.retryPayment();
    expect(r, isA<Ok>());
  });

  test('cancel and resume return the new status', () async {
    t.on('POST', '/v1/billing/subscriptions/cancel', body: ok(statusJson(rank: 2, display: 'ACTIVE_CANCELLING')));
    t.on('POST', '/v1/billing/subscriptions/resume', body: ok(statusJson(rank: 2, display: 'ACTIVE_RENEWING')));

    final cancelled = await repo.cancelSubscription();
    expect((cancelled as Ok<BillingStatus>).value.displayState, BillingDisplayState.activeCancelling);
    final resumed = await repo.resumeSubscription();
    expect((resumed as Ok<BillingStatus>).value.displayState, BillingDisplayState.activeRenewing);
  });
}

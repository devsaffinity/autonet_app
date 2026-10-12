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

/// The wire contract with `/v1/billing`. Buying is not here: the store takes
/// the money, and the only thing the app asks the server for afterwards is
/// "what do I actually own now?".
void main() {
  late FakeTransport t;
  late BillingApiRepository repo;

  String ok(Object data) => jsonEncode({'success': true, 'data': data});

  setUp(() {
    t = FakeTransport();
    final tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
    repo = BillingApiRepository(ApiClient(transport: t, baseUrl: 'http://test.local', tokens: tokens), tokens);
  });

  test('config: public store keys only', () async {
    t.on('GET', '/v1/billing/config', body: ok({
      'provider': 'revenuecat',
      'androidApiKey': 'goog_x',
      'iosApiKey': 'appl_x',
      'entitlement': 'pro',
      'offering': 'default',
    }));
    final r = await repo.config();
    expect((r as Ok).value.androidApiKey, 'goog_x');
  });

  test('config with no key at all is a malformed response, not a crash', () async {
    t.on('GET', '/v1/billing/config', body: ok({'androidApiKey': null, 'iosApiKey': null}));
    final r = await repo.config();
    expect((r as Err).error.code, ApiErrorCode.malformedResponse);
  });

  test('status carries the plans with their store product ids', () async {
    t.on('GET', '/v1/billing/status', body: ok(statusJson(rank: 1, baseRank: 1, credits: 9)));
    final r = await repo.status();
    final s = (r as Ok<BillingStatus>).value;
    expect(s.credits, 9);
    expect(s.creditPacks.first.androidProductId, isNotNull);
  });

  test('sync posts no body and returns the resulting status', () async {
    t.on('POST', '/v1/billing/sync', body: ok(statusJson(rank: 2, display: 'ACTIVE_RENEWING')));
    final r = await repo.sync();
    expect((r as Ok<BillingStatus>).value.isSubscribed, isTrue);
    expect(jsonDecode(t.lastOf('POST', '/v1/billing/sync')!.body!), isEmpty);
  });

  test('a RevenueCat outage surfaces as a server error, not a false "no plan"', () async {
    t.on('POST', '/v1/billing/sync', status: 503, body: errorBody('INTERNAL', 'Purchases are not available right now.'));
    final r = await repo.sync();
    expect((r as Err).error.statusCode, 503);
  });

  test('wallet', () async {
    t.on('GET', '/v1/billing/wallet', body: ok({'credits': 4, 'ledger': [], 'subscription': null}));
    final r = await repo.wallet();
    expect((r as Ok).value['credits'], 4);
  });
}

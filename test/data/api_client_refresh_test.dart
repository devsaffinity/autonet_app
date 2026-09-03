import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/http_transport.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/auth_user.dart';
import 'package:autonect/data/models/message_ack.dart';
import 'package:autonect/data/models/token_pair.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_transport.dart';

/// THE regression guard for the single-flight refresh. If any of these go red,
/// users are being hard-logged-out at random: a reused refresh token makes the
/// server revoke the entire token family.
void main() {
  late FakeTransport t;
  late InMemoryTokenStore tokens;
  late ApiClient client;
  late int expiredCount;

  const unauthorized = '{"success":false,"error":'
      '{"code":"UNAUTHORIZED","message":"Access token expired"}}';
  const badCreds = '{"success":false,"error":'
      '{"code":"INVALID_CREDENTIALS","message":"Invalid email or password"}}';
  const okBody = '{"success":true,"data":{"message":"ok"}}';

  setUp(() {
    t = FakeTransport();
    tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
    expiredCount = 0;
    client = ApiClient(
      transport: t,
      baseUrl: 'http://test.local',
      tokens: tokens,
      onSessionExpired: () async => expiredCount++,
    );
  });

  Future<ApiResult<MessageAck>> get_(String path, {bool auth = true}) =>
      client.send(
        method: 'GET',
        path: path,
        decode: MessageAck.fromJson,
        authenticated: auth,
      );

  Future<void> pump() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  int refreshCalls() => t.countOf('POST', '/v1/auth/refresh');

  List<HttpRequest> bearing(String token) => t.calls
      .where((c) => c.headers['authorization'] == 'Bearer $token')
      .toList();

  test('N concurrent 401s produce exactly one refresh call', () async {
    const paths = ['/v1/a', '/v1/b', '/v1/c', '/v1/d'];
    for (final p in paths) {
      t.on('GET', p, status: 401, body: unauthorized);
      t.onSecondCall('GET', p, body: okBody);
    }
    final gate = t.withDelay('POST', '/v1/auth/refresh',
        body: tokensBody('A2', 'R2'));

    final futures = [for (final p in paths) get_(p)];
    await pump();
    gate.complete();
    final results = await Future.wait(futures);

    expect(refreshCalls(), 1);
    expect(results.every((r) => r.isOk), isTrue);
    // All four retries went out on the NEW token.
    expect(bearing('A2').length, 4);
    expect(expiredCount, 0);
  });

  test('a 401 on login is NOT refreshed', () async {
    t.on('POST', '/v1/auth/login', status: 401, body: badCreds);
    final r = await client.send(
      method: 'POST',
      path: '/v1/auth/login',
      decode: MessageAck.fromJson,
      authenticated: false,
    );
    expect(r.errorOrNull?.code, ApiErrorCode.invalidCredentials);
    expect(refreshCalls(), 0);
  });

  test('a 401 INVALID_CREDENTIALS on an authed route is NOT refreshed', () async {
    t.on('GET', '/v1/a', status: 401, body: badCreds);
    final r = await get_('/v1/a');
    expect(r.errorOrNull?.code, ApiErrorCode.invalidCredentials);
    expect(refreshCalls(), 0);
  });

  test('stale-generation 401 retries without refreshing', () async {
    final gate = t.withDelay('GET', '/v1/a', status: 401, body: unauthorized);
    t.onSecondCall('GET', '/v1/a', body: okBody);

    final f = get_('/v1/a');
    await pump();
    // Somebody else rotated while we were in flight.
    await tokens.save(TokenPair(
      accessToken: 'A2',
      refreshToken: 'R2',
      user: const AuthUser(id: 'u1', email: 'a@b.com', role: 'BUYER', status: 'ACTIVE'),
    ));
    gate.complete();

    expect((await f).isOk, isTrue);
    expect(refreshCalls(), 0);
    expect(bearing('A2').length, 1);
  });

  test('a request starting during a refresh parks and never 401s', () async {
    t.on('GET', '/v1/a', status: 401, body: unauthorized);
    t.onSecondCall('GET', '/v1/a', body: okBody);
    t.on('GET', '/v1/b', body: okBody);
    final gate = t.withDelay('POST', '/v1/auth/refresh',
        body: tokensBody('A2', 'R2'));

    final a = get_('/v1/a');
    await pump(); // the refresh is now in flight
    final b = get_('/v1/b');
    await pump();
    gate.complete();
    await Future.wait([a, b]);

    expect(refreshCalls(), 1);
    // /v1/b went out ONCE, already carrying the new token.
    expect(t.countOf('GET', '/v1/b'), 1);
    expect(t.lastOf('GET', '/v1/b')!.headers['authorization'], 'Bearer A2');
  });

  test('a second 401 after refresh returns sessionExpired and does not refresh again',
      () async {
    t.on('GET', '/v1/a', status: 401, body: unauthorized);
    t.onSecondCall('GET', '/v1/a', status: 401, body: unauthorized);
    t.on('POST', '/v1/auth/refresh', body: tokensBody('A2', 'R2'));

    final r = await get_('/v1/a');
    expect(r.errorOrNull?.code, ApiErrorCode.sessionExpired);
    expect(refreshCalls(), 1);
    expect(tokens.refreshToken, isNull);
    expect(expiredCount, 1);
  });

  test('reuse-detected refresh (401) clears tokens and fires onSessionExpired exactly once',
      () async {
    for (final p in ['/v1/a', '/v1/b', '/v1/c']) {
      t.on('GET', p, status: 401, body: unauthorized);
    }
    final gate = t.withDelay('POST', '/v1/auth/refresh',
        status: 401, body: unauthorized);

    final futures = [for (final p in ['/v1/a', '/v1/b', '/v1/c']) get_(p)];
    await pump();
    gate.complete();
    final results = await Future.wait(futures);

    expect(refreshCalls(), 1);
    expect(
      results.every((r) => r.errorOrNull?.code == ApiErrorCode.sessionExpired),
      isTrue,
    );
    expect(tokens.refreshToken, isNull);
    // One failure, one toast, one navigation.
    expect(expiredCount, 1);
  });

  test('refresh 403 ACCOUNT_SUSPENDED clears tokens and logs out', () async {
    t.on('GET', '/v1/a', status: 401, body: unauthorized);
    t.on('POST', '/v1/auth/refresh',
        status: 403, body: errorBody('ACCOUNT_SUSPENDED', 'suspended'));

    final r = await get_('/v1/a');
    expect(r.errorOrNull?.code, ApiErrorCode.sessionExpired);
    expect(tokens.refreshToken, isNull);
    expect(expiredCount, 1);
  });

  test('offline during refresh KEEPS the refresh token', () async {
    t.on('GET', '/v1/a', status: 401, body: unauthorized);
    t.on('POST', '/v1/auth/refresh', throws: const TransportFailure('offline'));

    final r = await get_('/v1/a');
    expect(r.errorOrNull?.code, ApiErrorCode.network);
    expect(tokens.refreshToken, 'R1');
    expect(expiredCount, 0);
  });

  test('a timeout during refresh KEEPS the refresh token', () async {
    t.on('GET', '/v1/a', status: 401, body: unauthorized);
    t.on('POST', '/v1/auth/refresh', throws: const TransportTimeout());

    final r = await get_('/v1/a');
    expect(r.errorOrNull?.code, ApiErrorCode.timeout);
    expect(tokens.refreshToken, 'R1');
    expect(expiredCount, 0);
  });

  test('RATE_LIMITED (429) during refresh KEEPS the refresh token', () async {
    t.on('GET', '/v1/a', status: 401, body: unauthorized);
    t.on('POST', '/v1/auth/refresh',
        status: 429, body: errorBody('RATE_LIMITED', 'Too many requests'));

    final r = await get_('/v1/a');
    expect(r.errorOrNull?.code, ApiErrorCode.rateLimited);
    expect(tokens.refreshToken, 'R1');
    expect(expiredCount, 0);
  });

  test('INTERNAL (500) during refresh KEEPS the refresh token', () async {
    t.on('GET', '/v1/a', status: 401, body: unauthorized);
    t.on('POST', '/v1/auth/refresh',
        status: 500, body: errorBody('INTERNAL', 'boom'));

    final r = await get_('/v1/a');
    expect(r.errorOrNull?.code, ApiErrorCode.internal);
    expect(tokens.refreshToken, 'R1');
    expect(expiredCount, 0);
  });

  test('an empty refresh token is terminal without hitting the network', () async {
    tokens = InMemoryTokenStore(access: 'A1');
    client = ApiClient(
      transport: t,
      baseUrl: 'http://test.local',
      tokens: tokens,
      onSessionExpired: () async => expiredCount++,
    );
    t.on('GET', '/v1/a', status: 401, body: unauthorized);

    final r = await get_('/v1/a');
    expect(r.errorOrNull?.code, ApiErrorCode.sessionExpired);
    expect(refreshCalls(), 0);
    expect(expiredCount, 1);
  });
}

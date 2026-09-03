import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/message_ack.dart';
import 'package:autonect/data/models/token_pair.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_transport.dart';

/// Guards the invariant `_ensureRefreshed` documents: _performRefresh NEVER
/// throws.
///
/// It is asserted in a comment, and the comment was previously the only thing
/// enforcing it. Three real paths could break it — `TokenStore.save`,
/// `TokenStore.clear`, and the host-supplied `onSessionExpired` — and the last
/// is live in production: main.dart wires it to RoleController.forceSignOut,
/// which calls Get.find, a Fluttertoast platform channel and Get.offAllNamed.
///
/// A throw there does not merely fail one request. It escapes `send()` as a raw
/// exception to the initiator AND to every caller parked on the shared future,
/// so a single failed toast becomes an unhandled error in every screen that
/// happened to be loading. These tests fail loudly if that regresses.
void main() {
  const unauthorized = '{"success":false,"error":'
      '{"code":"UNAUTHORIZED","message":"Access token expired"}}';
  const okBody = '{"success":true,"data":{"message":"ok"}}';

  ApiClient clientWith(
    FakeTransport t,
    TokenStore tokens, {
    Future<void> Function()? onExpired,
  }) => ApiClient(
    transport: t,
    baseUrl: 'http://test.local',
    tokens: tokens,
    onSessionExpired: onExpired,
  );

  Future<ApiResult<MessageAck>> get_(ApiClient c) => c.send(
    method: 'GET',
    path: '/v1/thing',
    decode: MessageAck.fromJson,
  );

  test('a throwing onSessionExpired does not escape send()', () async {
    final t = FakeTransport()
      ..on('GET', '/v1/thing', status: 401, body: unauthorized)
      // Terminal refresh failure -> _killSession -> onSessionExpired throws.
      ..on('POST', '/v1/auth/refresh', status: 401, body: unauthorized);

    final client = clientWith(
      t,
      InMemoryTokenStore(access: 'A1', refresh: 'R1'),
      onExpired: () async => throw StateError('Fluttertoast channel died'),
    );

    final r = await get_(client);

    expect(r, isA<Err<MessageAck>>());
    expect((r as Err<MessageAck>).error.code, ApiErrorCode.sessionExpired);
  });

  test('a throwing TokenStore.save during rotation does not escape', () async {
    final t = FakeTransport()
      ..on('GET', '/v1/thing', status: 401, body: unauthorized)
      ..on('POST', '/v1/auth/refresh', body: tokensBody('A2', 'R2'));

    final client = clientWith(t, _SaveThrowsStore(access: 'A1', refresh: 'R1'));

    final r = await get_(client);

    expect(r, isA<Err<MessageAck>>());
    expect((r as Err<MessageAck>).error.code, ApiErrorCode.sessionExpired);
  });

  test('a throwing TokenStore.clear during teardown does not escape', () async {
    final t = FakeTransport()
      ..on('GET', '/v1/thing', status: 401, body: unauthorized)
      ..on('POST', '/v1/auth/refresh', status: 401, body: unauthorized);

    final client = clientWith(t, _ClearThrowsStore(access: 'A1', refresh: 'R1'));

    final r = await get_(client);

    expect(r, isA<Err<MessageAck>>());
    expect((r as Err<MessageAck>).error.code, ApiErrorCode.sessionExpired);
  });

  test(
    'parked callers survive a refresh whose teardown throws',
    () async {
      // The blast radius that made this worth fixing: one failing toast must not
      // take down every request that happened to be waiting on the refresh.
      final t = FakeTransport()
        ..on('GET', '/v1/thing', status: 401, body: unauthorized)
        ..on('GET', '/v1/thing', status: 401, body: unauthorized)
        ..on('GET', '/v1/thing', status: 401, body: unauthorized);
      final gate = t.withDelay(
        'POST',
        '/v1/auth/refresh',
        status: 401,
        body: unauthorized,
      );

      var expiredCalls = 0;
      final client = clientWith(
        t,
        InMemoryTokenStore(access: 'A1', refresh: 'R1'),
        onExpired: () async {
          expiredCalls++;
          throw StateError('navigation blew up');
        },
      );

      final inFlight = [get_(client), get_(client), get_(client)];
      await Future<void>.delayed(Duration.zero);
      gate.complete();

      final results = await Future.wait(inFlight);

      expect(t.countOf('POST', '/v1/auth/refresh'), 1,
          reason: 'single-flight must still hold on the failure path');
      expect(expiredCalls, 1);
      for (final r in results) {
        expect(r, isA<Err<MessageAck>>());
        expect((r as Err<MessageAck>).error.code, ApiErrorCode.sessionExpired);
      }
    },
  );

  test('a healthy rotation is unaffected by the guards', () async {
    final t = FakeTransport()
      ..on('GET', '/v1/thing', status: 401, body: unauthorized)
      ..on('GET', '/v1/thing', body: okBody)
      ..on('POST', '/v1/auth/refresh', body: tokensBody('A2', 'R2'));

    final tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
    final client = clientWith(t, tokens);

    final r = await get_(client);

    expect(r, isA<Ok<MessageAck>>());
    expect(tokens.accessToken, 'A2');
    expect(t.countOf('POST', '/v1/auth/refresh'), 1);
  });
}

class _SaveThrowsStore extends InMemoryTokenStore {
  _SaveThrowsStore({super.access, super.refresh});

  @override
  Future<void> save(TokenPair p) async => throw StateError('disk full');
}

class _ClearThrowsStore extends InMemoryTokenStore {
  _ClearThrowsStore({super.access, super.refresh});

  @override
  Future<void> clear() async => throw StateError('disk full');
}

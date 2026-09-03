import 'dart:convert';

import 'package:autonect/constants/app_role.dart';
import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/repositories/auth_api_repository.dart';
import 'package:autonect/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_transport.dart';

void main() {
  late FakeTransport t;
  late InMemoryTokenStore tokens;
  late AuthApiRepository repo;

  const ack = '{"success":true,"data":{"message":"ok"}}';

  setUp(() {
    t = FakeTransport();
    tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
    repo = AuthApiRepository(
      ApiClient(transport: t, baseUrl: 'http://test.local', tokens: tokens),
      tokens,
    );
  });

  Map<String, dynamic> bodyOf(String method, String path) =>
      jsonDecode(t.lastOf(method, path)!.body!) as Map<String, dynamic>;

  /// Every /v1/auth route is public. If one ever went out authenticated, a 401
  /// there would enter the refresh path and burn a rotation.
  void expectUnauthenticated(String method, String path) {
    expect(t.lastOf(method, path)!.headers.containsKey('authorization'), isFalse,
        reason: '$method $path must be sent with authenticated: false');
  }

  test('login posts a normalised email and never authenticates', () async {
    t.on('POST', '/v1/auth/login', body: tokensBody('A2', 'R2'));
    final r = await repo.login(email: '  Bob@Example.COM ', password: 'Passw0rd');
    expect(r.isOk, isTrue);
    expect(bodyOf('POST', '/v1/auth/login'),
        {'email': 'bob@example.com', 'password': 'Passw0rd'});
    expectUnauthenticated('POST', '/v1/auth/login');
    // Tokens are persisted on the way through.
    expect(tokens.accessToken, 'A2');
    expect(tokens.user?.role, 'BUYER');
  });

  test('signup sends the role wire string and omits blank optionals', () async {
    t.on('POST', '/v1/auth/signup', body: ack);
    await repo.signup(
      email: 'A@B.com',
      password: 'Passw0rd',
      role: AppRole.supplier,
      name: '  ',
    );
    expect(bodyOf('POST', '/v1/auth/signup'),
        {'email': 'a@b.com', 'password': 'Passw0rd', 'role': 'SUPPLIER'});
    expectUnauthenticated('POST', '/v1/auth/signup');
    // Signup returns no tokens — the account is PENDING_VERIFICATION.
    expect(tokens.accessToken, 'A1');
  });

  test('verifyOtp posts to otp/verify and persists the tokens', () async {
    t.on('POST', '/v1/auth/otp/verify', body: tokensBody('A2', 'R2'));
    await repo.verifyOtp(email: ' A@B.com ', code: ' 123456 ');
    expect(bodyOf('POST', '/v1/auth/otp/verify'),
        {'email': 'a@b.com', 'code': '123456'});
    expectUnauthenticated('POST', '/v1/auth/otp/verify');
    expect(tokens.refreshToken, 'R2');
  });

  test('resendOtp and forgot post only the email', () async {
    t.on('POST', '/v1/auth/otp/resend', body: ack);
    t.on('POST', '/v1/auth/forgot', body: ack);
    await repo.resendOtp('A@B.com');
    await repo.forgot('A@B.com');
    expect(bodyOf('POST', '/v1/auth/otp/resend'), {'email': 'a@b.com'});
    expect(bodyOf('POST', '/v1/auth/forgot'), {'email': 'a@b.com'});
    expectUnauthenticated('POST', '/v1/auth/otp/resend');
    expectUnauthenticated('POST', '/v1/auth/forgot');
  });

  test('social sends the provider and an optional role', () async {
    t.on('POST', '/v1/auth/social', body: tokensBody('A2', 'R2'));
    await repo.social(provider: 'GOOGLE', idToken: 'tok', role: AppRole.buyer);
    expect(bodyOf('POST', '/v1/auth/social'),
        {'provider': 'GOOGLE', 'idToken': 'tok', 'role': 'BUYER'});
    expectUnauthenticated('POST', '/v1/auth/social');
  });

  test('reset clears the store — the server revoked every session', () async {
    t.on('POST', '/v1/auth/reset', body: ack);
    await repo.reset(email: 'A@B.com', code: '123456', password: 'Passw0rd');
    expect(bodyOf('POST', '/v1/auth/reset'),
        {'email': 'a@b.com', 'code': '123456', 'password': 'Passw0rd'});
    expect(tokens.refreshToken, isNull);
  });

  test('logout posts the refresh token and clears even when it fails', () async {
    t.on('POST', '/v1/auth/logout', status: 500, body: errorBody('INTERNAL'));
    final r = await repo.logout();
    expect(bodyOf('POST', '/v1/auth/logout'), {'refreshToken': 'R1'});
    expect(r.isOk, isFalse);
    // A failed logout must never trap the user inside the app.
    expect(tokens.refreshToken, isNull);
  });

  test('logout with no refresh token makes no network call', () async {
    await tokens.clear();
    final r = await repo.logout();
    expect(r.isOk, isTrue);
    expect(t.calls, isEmpty);
  });

  group('PrefsTokenStore', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SessionStore.init();
    });

    test('save writes both tokens, the server role and the logged-in flag',
        () async {
      final prefs = PrefsTokenStore();
      final r = AuthApiRepository(
        ApiClient(transport: t, baseUrl: 'http://test.local', tokens: prefs),
        prefs,
      );
      t.on('POST', '/v1/auth/login', body: tokensBody('A9', 'R9', role: 'SUPPLIER'));
      final before = prefs.generation;
      await r.login(email: 'a@b.com', password: 'Passw0rd');

      expect(prefs.accessToken, 'A9');
      expect(prefs.refreshToken, 'R9');
      expect(prefs.user?.role, 'SUPPLIER');
      expect(SessionStore.role, 'SUPPLIER');
      expect(SessionStore.loggedIn, isTrue);
      expect(prefs.generation, greaterThan(before));

      await prefs.clear();
      expect(prefs.refreshToken, isNull);
      expect(prefs.user, isNull);
      expect(SessionStore.loggedIn, isFalse);
    });
  });
}

import 'package:autonect/constants/app_role.dart';
import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/message_ack.dart';
import 'package:autonect/data/models/token_pair.dart';
import 'package:autonect/data/repositories/auth_repository.dart';

/// All nine /v1/auth routes are public, so EVERY call here passes
/// authenticated: false. That is also the second half of the "a 401 on login is
/// never refreshed" guarantee — the first half is ApiError.isStaleAccessToken.
class AuthApiRepository implements AuthRepository {
  AuthApiRepository(this._c, this._tokens);

  final ApiClient _c;
  final TokenStore _tokens;

  /// auth.dto.ts uses z.email().toLowerCase(), and OTP rows are keyed on the
  /// stored email string — a stray capital from a soft keyboard would make
  /// verify look up a row that does not exist.
  static String _n(String v) => v.trim().toLowerCase();

  static TokenPair _tokenPair(Object? d) =>
      TokenPair.fromJson((d as Map).cast<String, dynamic>());

  @override
  Future<ApiResult<TokenPair>> login({
    required String email,
    required String password,
  }) => _c
      .send(
        method: 'POST',
        path: '/v1/auth/login',
        authenticated: false,
        body: {'email': _n(email), 'password': password},
        decode: _tokenPair,
      )
      .then(_persistIfOk);

  @override
  Future<ApiResult<MessageAck>> signup({
    required String email,
    required String password,
    required AppRole role,
    String? name,
    String? phone,
  }) => _c.send(
    method: 'POST',
    path: '/v1/auth/signup',
    authenticated: false,
    body: {
      'email': _n(email),
      'password': password,
      'role': role.wire,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    },
    decode: MessageAck.fromJson,
  );

  @override
  Future<ApiResult<TokenPair>> verifyOtp({
    required String email,
    required String code,
  }) => _c
      .send(
        method: 'POST',
        path: '/v1/auth/otp/verify',
        authenticated: false,
        body: {'email': _n(email), 'code': code.trim()},
        decode: _tokenPair,
      )
      .then(_persistIfOk);

  @override
  Future<ApiResult<MessageAck>> resendOtp(String email) => _c.send(
    method: 'POST',
    path: '/v1/auth/otp/resend',
    authenticated: false,
    body: {'email': _n(email)},
    decode: MessageAck.fromJson,
  );

  @override
  Future<ApiResult<TokenPair>> social({
    required String provider,
    required String idToken,
    AppRole? role,
  }) => _c
      .send(
        method: 'POST',
        path: '/v1/auth/social',
        authenticated: false,
        body: {
          'provider': provider,
          'idToken': idToken,
          if (role != null) 'role': role.wire,
        },
        decode: _tokenPair,
      )
      .then(_persistIfOk);

  @override
  Future<ApiResult<MessageAck>> forgot(String email) => _c.send(
    method: 'POST',
    path: '/v1/auth/forgot',
    authenticated: false,
    body: {'email': _n(email)},
    decode: MessageAck.fromJson,
  );

  @override
  Future<ApiResult<MessageAck>> reset({
    required String email,
    required String code,
    required String password,
  }) async {
    final r = await _c.send(
      method: 'POST',
      path: '/v1/auth/reset',
      authenticated: false,
      body: {'email': _n(email), 'code': code.trim(), 'password': password},
      decode: MessageAck.fromJson,
    );
    // A reset revokes ALL sessions server-side, so a retained token would walk
    // straight into reuse detection on its next 401.
    if (r.isOk) await _tokens.clear();
    return r;
  }

  @override
  Future<ApiResult<MessageAck>> logout() async {
    final rt = _tokens.refreshToken;
    if (rt == null || rt.isEmpty) return const Ok(MessageAck('Logged out'));
    // Cleared BEFORE the round trip, not after. The captured `rt` is all the
    // server needs to revoke, and clearing first means the credentials are off
    // the device even if the process dies mid-flight or the caller never awaits
    // us — which the ADMIN rejection in AuthController deliberately does not.
    // Also means a failed logout can never trap the user inside the app.
    await _tokens.clear();
    return _c.send(
      method: 'POST',
      path: '/v1/auth/logout',
      authenticated: false,
      body: {'refreshToken': rt},
      decode: MessageAck.fromJson,
    );
  }

  Future<ApiResult<TokenPair>> _persistIfOk(ApiResult<TokenPair> r) async {
    if (r case Ok(:final value)) await _tokens.save(value);
    return r;
  }
}

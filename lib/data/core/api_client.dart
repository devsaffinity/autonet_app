import 'dart:convert';

import 'package:autonect/data/core/api_envelope.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/http_transport.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/token_pair.dart';

/// WHY THIS CLASS IS SHAPED THE WAY IT IS — read before "simplifying" it.
///
/// The backend treats refresh tokens as a REUSE-DETECTION FAMILY
/// (refresh-token.service.ts rotate(), lines 56-62): presenting a refresh token
/// whose row already has revokedAt or replacedById set is treated as THEFT, so
/// the server calls revokeFamily() and EVERY session for that user dies. The
/// user is hard-logged-out on every device.
///
/// So two concurrent 401s must NOT each POST /v1/auth/refresh: the first
/// rotates, the second presents the now-used token, and the whole family is
/// revoked. That is a random logout whenever two list screens load at once. The
/// client must therefore issue AT MOST ONE refresh per token generation. The
/// park, _refreshFuture and TokenStore.generation exist for exactly that. None
/// of it is defensive padding, and collapsing any of it reintroduces the bug.
///
/// THERE MUST BE EXACTLY ONE ApiClient INSTANCE IN THE PROCESS. _refreshFuture
/// is per-instance; two instances are two concurrent refreshes are a hard
/// logout. Get.put<ApiClient>(..., permanent: true) in main() and nowhere else.
/// Do not call an authenticated endpoint from a background isolate — an isolate
/// has its own memory and therefore its own _refreshFuture.
class ApiClient {
  ApiClient({
    required HttpTransport transport,
    required String baseUrl,
    required TokenStore tokens,
    this.onSessionExpired,
  }) : _transport = transport,
       _baseUrl = baseUrl,
       _tokens = tokens;

  final HttpTransport _transport;

  /// e.g. https://api.autonect.co.uk — NO /v1.
  final String _baseUrl;
  final TokenStore _tokens;
  final Future<void> Function()? onSessionExpired;

  /// Non-null exactly while a refresh is on the wire. Completes with null on
  /// success, or with the ApiError callers should surface.
  Future<ApiError?>? _refreshFuture;

  /// The meta-blind spelling. Byte-identical signature to the phase-0 one: every
  /// existing caller and both refresh tests keep working untouched.
  Future<ApiResult<T>> send<T>({
    required String method,
    required String path,
    required T Function(Object? data) decode,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) => sendEnvelope(
    method: method,
    path: path,
    decode: (d, _) => decode(d),
    body: body,
    query: query,
    authenticated: authenticated,
  );

  /// The real send. Identical refresh machinery; the only difference is that the
  /// decoder also receives the top-level `meta` sibling, so a paged repository
  /// can read hasNextPage without re-parsing the body.
  Future<ApiResult<T>> sendEnvelope<T>({
    required String method,
    required String path,
    required EnvelopeDecoder<T> decode,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    // PARK. A refresh is running: wait rather than firing a request we already
    // know carries a dead token. No deadlock: _performRefresh calls _dispatch
    // directly and never re-enters send().
    if (authenticated) {
      final pending = _refreshFuture;
      if (pending != null) {
        // Belt and braces: _performRefresh is contractually non-throwing, but a
        // parked caller must never die on somebody else's refresh if that
        // contract is ever broken by a later edit.
        try {
          await pending;
        } catch (_) {
          return Err<T>(const ApiError.sessionExpired());
        }
      }
    }

    // Captured AFTER the park and BEFORE the send. This is guard 2's anchor.
    final generationAtDispatch = _tokens.generation;

    HttpResponse res;
    try {
      res = await _dispatch(
        method,
        path,
        body,
        query,
        bearer: authenticated ? _tokens.accessToken : null,
      );
    } on TransportTimeout {
      return const Err(ApiError.timeout());
    } on TransportFailure catch (e) {
      return Err(ApiError.network(e.message));
    }

    final parsed = decodeEnvelopeWithMeta<T>(res.statusCode, res.body, decode);

    // Only a stale ACCESS token is refreshable. Every /v1/auth route is sent
    // with authenticated:false, and isStaleAccessToken additionally requires
    // code==UNAUTHORIZED, so a 401 INVALID_CREDENTIALS can never refresh.
    if (!authenticated ||
        parsed is! Err<T> ||
        !parsed.error.isStaleAccessToken) {
      return parsed;
    }

    // GUARD 2 — somebody already rotated while we were in flight. Retry with
    // the current token; issue NO refresh at all.
    if (_tokens.generation != generationAtDispatch) {
      return _retryOnce(method, path, body, query, decode);
    }

    // GUARD 1 — single flight.
    final refreshError = await _ensureRefreshed(generationAtDispatch);
    if (refreshError != null) return Err<T>(refreshError);
    return _retryOnce(method, path, body, query, decode);
  }

  /// Returns null on success, else the error to surface. Every concurrent
  /// caller in one generation receives THE SAME Future.
  Future<ApiError?> _ensureRefreshed(int generationAtDispatch) {
    if (_tokens.generation != generationAtDispatch) {
      return Future<ApiError?>.value(null);
    }
    final inFlight = _refreshFuture;
    if (inFlight != null) return inFlight;
    // _performRefresh() runs synchronously up to its first await, and the
    // assignment below happens in that same event-loop turn with NO await
    // between the read above and the write here. That is the entire
    // mutual-exclusion argument; Dart's single-threaded isolate makes a lock
    // unnecessary. _performRefresh NEVER throws, so whenComplete cannot leak
    // an unhandled error.
    final started = _performRefresh();
    _refreshFuture = started;
    started.whenComplete(() {
      _refreshFuture = null;
    });
    return started;
  }

  /// Enforces the invariant _ensureRefreshed documents rather than merely
  /// asserting it. _tokens.save/clear and the host's onSessionExpired callback
  /// can all throw; without this wrapper that exception escapes send() as a raw
  /// throw and hits the initiator plus every parked caller simultaneously.
  Future<ApiError?> _performRefresh() async {
    try {
      return await _refreshOnce();
    } catch (_) {
      // Unknown failure mid-rotation: the token state is no longer trustworthy,
      // so end the session deliberately instead of leaving it half-rotated.
      await _killSession();
      return const ApiError.sessionExpired();
    }
  }

  Future<ApiError?> _refreshOnce() async {
    final rt = _tokens.refreshToken;
    if (rt == null || rt.isEmpty) {
      await _killSession();
      return const ApiError.sessionExpired();
    }
    HttpResponse res;
    try {
      res = await _dispatch(
        'POST',
        '/v1/auth/refresh',
        {'refreshToken': rt},
        null,
        bearer: null,
      );
    } on TransportTimeout {
      // TRANSIENT — session KEPT. Being offline is not being revoked.
      return const ApiError.timeout();
    } on TransportFailure catch (e) {
      return ApiError.network(e.message); // TRANSIENT — session KEPT.
    }
    final parsed = decodeEnvelope<TokenPair>(
      res.statusCode,
      res.body,
      (d) => TokenPair.fromJson((d as Map).cast<String, dynamic>()),
    );
    switch (parsed) {
      case Ok(:final value):
        await _tokens.save(value); // bumps generation -> releases guard 2
        return null;
      case Err(:final error):
        if (_isTerminalRefreshFailure(error)) {
          await _killSession();
          return const ApiError.sessionExpired();
        }
        return error; // 429 / 5xx / malformed -> session KEPT
    }
  }

  /// THE ONLY two terminal outcomes. VERIFIED:
  ///   401 -> rotate() threw AppError.unauthorized: invalid, expired, revoked,
  ///          or REUSE-DETECTED (family already dead server-side).
  ///   403 ACCOUNT_SUSPENDED -> auth.service.ts:106-110 called revokeAllForUser
  ///          before throwing; every session is gone.
  /// Everything else is transient. authRateLimit (20 / 15 min, constants.ts:37)
  /// covers /v1/auth/refresh, so a 429 here is REACHABLE and MUST NOT log out.
  static bool _isTerminalRefreshFailure(ApiError e) =>
      e.statusCode == 401 || e.code == ApiErrorCode.accountSuspended;

  Future<ApiResult<T>> _retryOnce<T>(
    String method,
    String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    EnvelopeDecoder<T> decode,
  ) async {
    HttpResponse res;
    try {
      res = await _dispatch(
        method,
        path,
        body,
        query,
        bearer: _tokens.accessToken,
      );
    } on TransportTimeout {
      return const Err(ApiError.timeout());
    } on TransportFailure catch (e) {
      return Err(ApiError.network(e.message));
    }
    final parsed = decodeEnvelopeWithMeta<T>(res.statusCode, res.body, decode);
    // RETRY CAP OF ONE. A 401 on a token minted seconds ago is a dead session,
    // never a reason to refresh again. Recursion is provably bounded.
    if (parsed is Err<T> && parsed.error.isStaleAccessToken) {
      await _killSession();
      return const Err(ApiError.sessionExpired());
    }
    return parsed;
  }

  /// MUST NOT throw. The single-flight contract depends on it: an exception
  /// here escapes to the initiator AND to every caller parked on the shared
  /// future, as a raw throw rather than an Err. onSessionExpired is
  /// host-supplied — main.dart wires it to RoleController.forceSignOut, which
  /// touches Get and a Fluttertoast platform channel — so it is not ours to
  /// trust. Both steps are attempted independently: a storage failure must not
  /// skip the sign-out notification.
  Future<void> _killSession() async {
    try {
      await _tokens.clear();
    } catch (_) {
      // Nothing useful to do — the session is dead either way, and rethrowing
      // would take the whole refresh down with it.
    }
    try {
      await onSessionExpired?.call();
    } catch (_) {
      // A failed sign-out notification must not poison the refresh.
    }
  }

  Future<HttpResponse> _dispatch(
    String method,
    String path,
    Map<String, dynamic>? body,
    Map<String, String>? query, {
    String? bearer,
  }) {
    return _transport.send(
      HttpRequest(
        method: method,
        url: '$_baseUrl$path',
        query: query,
        headers: {
          'content-type': 'application/json',
          'accept': 'application/json',
          if (bearer != null && bearer.isNotEmpty)
            'authorization': 'Bearer $bearer',
        },
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }
}

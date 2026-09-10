import 'dart:convert';

import 'package:autonect/data/models/auth_user.dart';
import 'package:autonect/data/models/token_pair.dart';
import 'package:autonect/services/session_store.dart';

abstract class TokenStore {
  String? get accessToken;
  String? get refreshToken;
  AuthUser? get user;

  /// Monotonic; bumped on every save() and clear(). This is what lets ApiClient
  /// tell "my token is stale" from "somebody already rotated". Do not remove.
  int get generation;

  Future<void> save(TokenPair pair);
  Future<void> clear();
  void updateUser(AuthUser user);
}

class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore({String? access, String? refresh, this.user})
    : _access = access,
      _refresh = refresh;

  String? _access;
  String? _refresh;
  @override
  AuthUser? user;
  int _gen = 0;

  @override
  String? get accessToken => _access;
  @override
  String? get refreshToken => _refresh;
  @override
  int get generation => _gen;

  @override
  Future<void> save(TokenPair p) async {
    _access = p.accessToken;
    _refresh = p.refreshToken;
    user = p.user;
    _gen++;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
    user = null;
    _gen++;
  }

  @override
  void updateUser(AuthUser u) {
    user = u;
    _gen++;
  }
}

/// Persists the access token as well as the refresh token: ACCESS_TTL_SEC is
/// 15 min (constants.ts:7), so a memory-only access token would burn a rotation
/// on every cold start inside that window for nothing.
class PrefsTokenStore implements TokenStore {
  int _gen = 0;

  @override
  String? get accessToken => SessionStore.accessToken;
  @override
  String? get refreshToken => SessionStore.refreshToken;

  @override
  AuthUser? get user {
    final raw = SessionStore.userJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUser.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  @override
  int get generation => _gen;

  @override
  Future<void> save(TokenPair p) async {
    // ORDER IS LOAD-BEARING: refresh token first. A crash mid-write must never
    // leave a NEW access token beside an OLD refresh token — presenting a
    // rotated token is what triggers revokeFamily().
    SessionStore.refreshToken = p.refreshToken;
    SessionStore.accessToken = p.accessToken;
    SessionStore.userJson = jsonEncode(p.user.toJson());
    // SERVER'S ROLE WINS over whatever RolePage recorded locally.
    SessionStore.role = p.user.role;
    SessionStore.loggedIn = true;
    _gen++;
  }

  @override
  Future<void> clear() async {
    SessionStore.clearSession();
    _gen++;
  }

  @override
  void updateUser(AuthUser u) {
    SessionStore.userJson = jsonEncode(u.toJson());
    _gen++;
  }
}

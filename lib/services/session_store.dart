import 'package:shared_preferences/shared_preferences.dart';

/// The only file in the app permitted to import shared_preferences.
///
/// Every getter is synchronous because [init] is awaited in main() before
/// runApp — that is what lets SplashScreen decide the first route with no
/// await and therefore no flash of the wrong screen.
class SessionStore {
  SessionStore._();

  static const _kRole = 'session.role';
  static const _kLoggedIn = 'session.loggedIn';
  static const _kOnboardingSeen = 'session.onboardingSeen';
  static const _kProviderOnboarded = 'session.providerOnboarded';
  static const _kAccess = 'session.accessToken';
  static const _kRefresh = 'session.refreshToken';
  static const _kUser = 'session.user';
  static const _kCategories = 'session.categories';
  static const _kLastRegion = 'session.lastRegion';
  static const _kDraftPrefix = 'session.requestDraft.';

  /// Not `final`: tests re-init after SharedPreferences.setMockInitialValues
  /// to get a clean store per case, and a late-final field can only be written
  /// once per isolate.
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? get role => _prefs.getString(_kRole);
  static set role(String? v) {
    if (v == null) {
      _prefs.remove(_kRole);
    } else {
      _prefs.setString(_kRole, v);
    }
  }

  static bool get loggedIn => _prefs.getBool(_kLoggedIn) ?? false;
  static set loggedIn(bool v) => _prefs.setBool(_kLoggedIn, v);

  /// Survives logout — a returning user must not be shown onboarding again.
  static bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;
  static set onboardingSeen(bool v) => _prefs.setBool(_kOnboardingSeen, v);

  static bool get providerOnboarded =>
      _prefs.getBool(_kProviderOnboarded) ?? false;
  static set providerOnboarded(bool v) =>
      _prefs.setBool(_kProviderOnboarded, v);

  /// Both tokens live here rather than in flutter_secure_storage this phase:
  /// TokenStore is the seam that makes a SecureTokenStore a one-line swap in
  /// main(). android:allowBackup="false" covers the Android clone hazard.
  static String? get accessToken => _prefs.getString(_kAccess);
  static set accessToken(String? v) {
    if (v == null) {
      _prefs.remove(_kAccess);
    } else {
      _prefs.setString(_kAccess, v);
    }
  }

  static String? get refreshToken => _prefs.getString(_kRefresh);
  static set refreshToken(String? v) {
    if (v == null) {
      _prefs.remove(_kRefresh);
    } else {
      _prefs.setString(_kRefresh, v);
    }
  }

  static String? get userJson => _prefs.getString(_kUser);
  static set userJson(String? v) {
    if (v == null) {
      _prefs.remove(_kUser);
    } else {
      _prefs.setString(_kUser, v);
    }
  }

  /// The raw `GET /v1/categories` array, verbatim off the wire. Public
  /// reference data, not session data: it survives sign-out because it belongs
  /// to nobody.
  static String? get categoriesJson => _prefs.getString(_kCategories);
  static set categoriesJson(String? v) {
    if (v == null) {
      _prefs.remove(_kCategories);
    } else {
      _prefs.setString(_kCategories, v);
    }
  }

  /// The Region wire value from the buyer's last successful create, used to
  /// PRE-SELECT the wizard's region field. Never a silent default — the field
  /// still shows and still validates.
  static String? get lastRegionWire => _prefs.getString(_kLastRegion);
  static set lastRegionWire(String? v) {
    if (v == null) {
      _prefs.remove(_kLastRegion);
    } else {
      _prefs.setString(_kLastRegion, v);
    }
  }

  /// One unfinished wizard per user id. Keyed per user so a second account on
  /// the same device can never see the first account's draft, which is also
  /// what makes it safe to leave behind on sign-out.
  static String? requestDraftJson(String userId) =>
      _prefs.getString(_draftKey(userId));

  static void setRequestDraftJson(String userId, String? v) {
    if (v == null) {
      _prefs.remove(_draftKey(userId));
    } else {
      _prefs.setString(_draftKey(userId), v);
    }
  }

  static String _draftKey(String userId) => '$_kDraftPrefix$userId';

  /// onboardingSeen deliberately survives — a returning user must not be shown
  /// onboarding again after a logout.
  ///
  /// So do the request drafts: a forced sign-out (an expired refresh token, a
  /// 403 SUSPENDED) is not the buyer abandoning a half-typed request, and
  /// throwing away already-uploaded S3 keys would force a full re-upload after
  /// a re-login. The per-user key is what makes keeping them safe.
  static void clearSession() {
    _prefs.remove(_kRole);
    _prefs.remove(_kLoggedIn);
    _prefs.remove(_kProviderOnboarded);
    _prefs.remove(_kAccess);
    _prefs.remove(_kRefresh);
    _prefs.remove(_kUser);
  }
}

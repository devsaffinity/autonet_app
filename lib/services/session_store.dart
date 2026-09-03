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

  static late final SharedPreferences _prefs;

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

  static void clearSession() {
    _prefs.remove(_kRole);
    _prefs.remove(_kLoggedIn);
    _prefs.remove(_kProviderOnboarded);
  }
}

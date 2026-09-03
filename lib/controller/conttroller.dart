import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_role.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/data/models/auth_user.dart';
import 'package:autonect/data/repositories/auth_repository.dart';
import 'package:autonect/services/session_store.dart';
import 'package:get/get.dart';

class RoleController extends GetxController {
  static RoleController get to => Get.find<RoleController>();

  final Rxn<AppRole> role = Rxn<AppRole>();
  final RxBool isLoggedIn = false.obs;
  final RxBool onboardingSeen = false.obs;

  /// Mirrors SupplierProfile.approved / ElectricianProfile.approved: a provider
  /// who has not finished KYC is held on the wizard instead of the shell.
  final RxBool providerOnboarded = false.obs;

  bool get hasRole => role.value != null;

  @override
  void onInit() {
    super.onInit();
    role.value = AppRole.fromWire(SessionStore.role);
    // The two sources of truth can diverge (prefs partially wiped). Without the
    // AND, the app boots into a shell where every request 401s and
    // force-logs-out — a launch loop that reads as a routing bug.
    isLoggedIn.value =
        SessionStore.loggedIn && (SessionStore.refreshToken?.isNotEmpty ?? false);
    onboardingSeen.value = SessionStore.onboardingSeen;
    providerOnboarded.value = SessionStore.providerOnboarded;
  }

  void selectRole(AppRole r) {
    role.value = r;
    SessionStore.role = r.wire;
  }

  void markOnboardingSeen() {
    onboardingSeen.value = true;
    SessionStore.onboardingSeen = true;
  }

  void completeProviderOnboarding() {
    providerOnboarded.value = true;
    SessionStore.providerOnboarded = true;
  }

  /// The server's role is authoritative over whatever RolePage recorded.
  /// Returns false for ADMIN (AppRole.fromWire -> null, app_role.dart:19-25):
  /// admins have no app shell, so the caller must surface that, not route on it.
  bool signInFromSession(AuthUser user) {
    final r = AppRole.fromWire(user.role);
    if (r == null) return false;
    selectRole(r);
    isLoggedIn.value = true;
    SessionStore.loggedIn = true;
    return true;
  }

  /// User-initiated. Revokes server-side FIRST.
  Future<void> signOut() async {
    await Get.find<AuthRepository>().logout();
    _localTeardown();
    Get.offAllNamed(AppLinks.role);
  }

  /// Wired to ApiClient.onSessionExpired. The session is ALREADY dead
  /// server-side, so this MUST NOT call /auth/logout — that just 401s and
  /// re-enters the same teardown. THAT IS WHY THESE ARE TWO METHODS.
  /// Idempotent: N waiters share one failure, so one toast and one nav.
  bool _forcedOut = false;

  void forceSignOut() {
    if (_forcedOut) return;
    _forcedOut = true;
    _localTeardown();
    displayToast(msg: 'Your session expired. Please log in again.');
    if (Get.isDialogOpen == true) Get.close(1);
    Get.offAllNamed(AppLinks.login);
  }

  /// Call on a successful sign-in, or the latch swallows the next real expiry.
  void resetForceSignOutLatch() => _forcedOut = false;

  void _localTeardown() {
    isLoggedIn.value = false;
    providerOnboarded.value = false;
    role.value = null;
    SessionStore.clearSession();
  }

  /// THE decision function: the only code in the app that maps a role to a
  /// destination. Splash, login and register call this and nothing else.
  String get landingRoute {
    final r = role.value;
    if (r == null) return AppLinks.role;
    if (r == AppRole.supplier && !providerOnboarded.value) {
      return AppLinks.supplierOnboarding;
    }
    if (r == AppRole.electrician && !providerOnboarded.value) {
      return AppLinks.electricianOnboarding;
    }
    return AppLinks.homeFor(r);
  }
}

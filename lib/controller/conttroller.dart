import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_role.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/data/models/auth_user.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
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

  /// Server truth about whether the supplier shell may open.
  ///
  /// Null until `GET /v1/me` has answered once this session. [providerOnboarded]
  /// is only a local record that the wizard was FILLED IN — it says nothing
  /// about approval, and on its own it let a supplier tap through to a shell
  /// where every route answered 403.
  final Rxn<bool> providerApproved = Rxn<bool>();

  /// Re-reads the provider's approval state and routes on the answer.
  ///
  /// Approval happens elsewhere — an admin acting on the review queue — and the
  /// app has no push channel, so an explicit re-read is the only way a waiting
  /// supplier ever learns about it.
  ///
  /// Deliberately silent on failure beyond leaving them where they are: this is
  /// called from a screen whose entire purpose is to be a holding pattern, and
  /// a network blip must not eject them from it.
  Future<void> refreshProviderAccess() async {
    if (!await syncProviderAccess()) return;
    // landingRoute now reflects the server, so it is the one decision point
    // again rather than a second copy of the same rules.
    final target = landingRoute;
    if (target != AppLinks.supplierAwaitingApproval) {
      Get.offAllNamed(target);
    }
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
    if (r == AppRole.supplier) {
      // Three destinations, not two. A supplier who HAS registered is not
      // therefore allowed into the shell — approval is a separate admin
      // decision, and every supplier route answers 403 until it happens.
      if (!providerOnboarded.value) return AppLinks.supplierOnboarding;
      if (providerApproved.value != true) {
        return AppLinks.supplierAwaitingApproval;
      }
      return AppLinks.homeFor(r);
    }
    if (r == AppRole.electrician) {
      // THREE destinations here too, for the same reason as the supplier.
      //
      // This used to be two: an electrician who had filled in the wizard went
      // straight into the shell on a LOCAL flag, with no server-side approval
      // check anywhere. An unapproved provider could browse the app and be
      // handed work, while every route that mattered would have refused them.
      if (!providerOnboarded.value) return AppLinks.electricianOnboarding;
      if (providerApproved.value != true) {
        return AppLinks.supplierAwaitingApproval;
      }
      return AppLinks.homeFor(r);
    }
    return AppLinks.homeFor(r);
  }

  /// Refreshes [providerOnboarded] and [providerApproved] from `GET /v1/me`.
  ///
  /// MUST be awaited before routing EITHER provider role anywhere, because both
  /// flags otherwise come from SharedPreferences — which knows only whether
  /// THIS install completed the wizard. `_localTeardown` clears the flag on
  /// every sign-out, so without this a provider who registered and was approved
  /// months ago is sent back through the wizard on their next login, and
  /// RoleGuard bounces them there again if they try to leave.
  ///
  /// COVERS ELECTRICIANS TOO. It was gated to `supplier` alone, which meant an
  /// electrician's access was decided entirely by a local boolean — the wizard
  /// wrote it without ever calling the server, so finishing the form was
  /// self-approval.
  ///
  /// A failed read leaves both flags untouched and returns false, so a network
  /// blip falls back to the local answer rather than stranding a provider at a
  /// screen they cannot leave.
  Future<bool> syncProviderAccess() async {
    if (role.value != AppRole.supplier && role.value != AppRole.electrician) {
      return false;
    }
    switch (await Get.find<ProfileRepository>().me()) {
      case Err():
        return false;
      case Ok(:final value):
        // Whichever profile this account has. A row EXISTING is what
        // "onboarded" actually means; the local flag only ever recorded that
        // the wizard was filled in on this device.
        final onboarded = value.hasProviderProfile;
        providerOnboarded.value = onboarded;
        SessionStore.providerOnboarded = onboarded;
        providerApproved.value = value.providerApproved ?? false;
        return true;
    }
  }
}

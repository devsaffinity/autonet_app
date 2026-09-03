import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_role.dart';
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
    isLoggedIn.value = SessionStore.loggedIn;
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

  // TODO(api): `r` must come from the POST /auth/login response via
  // AppRole.fromWire(res['role']). The server's role always wins over
  // whatever RolePage recorded locally.
  void signIn(AppRole r) {
    selectRole(r);
    isLoggedIn.value = true;
    SessionStore.loggedIn = true;
  }

  void signOut() {
    isLoggedIn.value = false;
    providerOnboarded.value = false;
    role.value = null;
    SessionStore.clearSession();
    Get.offAllNamed(AppLinks.role);
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

// NAVIGATION RULE, binding on the whole team:
// IF THE NAVIGATION CLEARS THE STACK IT IS NAMED;
// IF IT PUSHES ONTO THE STACK IT STAYS `Get.to(() => W())`.
// That is why this table is short — the existing leaf pushes are working
// navigation and are deliberately not converted.
//
// The sign-up role picker and the sign-up form are NOT here for the same
// reason: both are only ever pushed (Login → RolePage → RegisterPage), and the
// form takes its role as a required constructor argument, which a named route
// could only smuggle through untyped `arguments`.

import 'package:autonect/config/routes/role_guard.dart';
import 'package:autonect/constants/app_role.dart';
import 'package:autonect/view/screens/auth/forget.dart';
import 'package:autonect/view/screens/auth/login.dart';
import 'package:autonect/view/screens/buyer/nav_bar/nav_bar.dart';
import 'package:autonect/view/screens/electrician/nav_bar/nav_bar.dart';
import 'package:autonect/view/screens/electrician/registration/service_provider_registration.dart';
import 'package:autonect/view/screens/launch/onboarding/onboarding.dart';
import 'package:autonect/view/screens/launch/splash_screen.dart';
import 'package:autonect/view/screens/supplier/nav_bar/nav_bar.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_awaiting_approval.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration.dart';
import 'package:get/get.dart';

class AppRoutes {
  static final List<GetPage> pages = [
    GetPage(name: AppLinks.splash_screen, page: () => SplashScreen()),
    GetPage(
      name: AppLinks.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppLinks.login,
      page: () => LoginPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(name: AppLinks.forgot, page: () => ForgetPage()),
    GetPage(
      name: AppLinks.buyerShell,
      page: () => const BuyerNavBar(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppLinks.supplierShell,
      page: () => const SupplierNavBar(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppLinks.electricianShell,
      page: () => const ElectricianNavBar(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppLinks.supplierOnboarding,
      page: () => const SupplierRegistrationPage(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppLinks.supplierAwaitingApproval,
      // No profile argument: reached from a cold start where there is none.
      page: () => const SupplierAwaitingApprovalPage(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppLinks.electricianOnboarding,
      page: () => const ServiceProviderRegistrationPage(),
      middlewares: [RoleGuard()],
    ),
  ];
}

class AppLinks {
  // ignore: constant_identifier_names
  static const splash_screen = '/splash_screen';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const forgot = '/forgot';
  static const buyerShell = '/buyer';
  static const supplierShell = '/supplier';
  static const electricianShell = '/electrician';
  static const supplierOnboarding = '/supplier/onboarding';
  static const supplierAwaitingApproval = '/supplier/awaiting-approval';
  static const electricianOnboarding = '/electrician/onboarding';

  /// Exhaustive on purpose: a fourth AppRole must be a compile error here and
  /// nowhere else.
  static String homeFor(AppRole role) {
    switch (role) {
      case AppRole.buyer:
        return buyerShell;
      case AppRole.supplier:
        return supplierShell;
      case AppRole.electrician:
        return electricianShell;
    }
  }
}

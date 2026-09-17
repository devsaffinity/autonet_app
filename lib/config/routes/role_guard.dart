import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Keeps the three shells and the two KYC wizards reachable only by the role
/// that owns them.
///
/// Termination proof: the redirect target is always `landingRoute`, and
/// landingRoute is idempotent — re-entering the guard at that route yields
/// `target == route` and returns null. NEVER add a second middleware to these
/// five GetPages without re-verifying this.
class RoleGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final c = RoleController.to;
    // A role alone is not a session: `selectRole` can be called without one,
    // and older builds stored the sign-up pick before any account existed.
    // landingRoute deliberately ignores isLoggedIn — splash
    // uses it to place a *restored* session — which would otherwise let a deep
    // link or a stray toNamed() walk straight into a shell with no tokens.
    // Terminates: the login route carries no middleware.
    if (!c.isLoggedIn.value) {
      return route == AppLinks.login
          ? null
          : const RouteSettings(name: AppLinks.login);
    }
    final target = c.landingRoute;
    return target == route ? null : RouteSettings(name: target);
  }
}

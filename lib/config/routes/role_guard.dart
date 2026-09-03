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
    final target = RoleController.to.landingRoute;
    return target == route ? null : RouteSettings(name: target);
  }
}

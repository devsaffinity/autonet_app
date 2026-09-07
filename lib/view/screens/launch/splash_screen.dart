import 'dart:async';

import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1500), _route);
  }

  /// Every value read here is already in memory because SessionStore.init()
  /// was awaited in main(), so the first three branches have no await and no
  /// flash of a wrong screen. Branch 3 is what keeps an ADMIN token — which
  /// AppRole.fromWire reads as null — from reaching an exhaustive switch.
  ///
  /// The LAST branch is the one exception: a restored supplier session needs
  /// the server's answer, because the local flags record only what this device
  /// did and are cleared on every sign-out. syncProviderAccess is a no-op for
  /// every other role, so nobody else pays for it, and this screen is already
  /// showing a logo — a short wait here beats routing an approved supplier back
  /// into the wizard.
  Future<void> _route() async {
    final c = RoleController.to;
    if (!c.onboardingSeen.value) {
      Get.offAllNamed(AppLinks.onboarding);
    } else if (!c.isLoggedIn.value) {
      Get.offAllNamed(c.hasRole ? AppLinks.login : AppLinks.role);
    } else if (!c.hasRole) {
      Get.offAllNamed(AppLinks.role);
    } else {
      await c.syncProviderAccess();
      if (!mounted) return;
      Get.offAllNamed(c.landingRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSecondaryColor,
      body: Center(
        child: CommonImageView(height: 130, imagePath: Assets.imagesSpLogo),
      ),
    );
  }
}

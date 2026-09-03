import 'dart:async';

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/buyer/home/home.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/screens/buyer/request/request_status_tracking.dart';
import 'package:autonect/view/screens/buyer/services/services.dart';
import 'package:autonect/view/screens/chat/chat_home.dart';
import 'package:autonect/view/screens/electrician/dash_board/total_balance.dart';
import 'package:autonect/view/screens/electrician/home/electrician_booking.dart';
import 'package:autonect/view/screens/electrician/home/home.dart';
import 'package:autonect/view/screens/electrician/home/upcoming_booking_details.dart';
import 'package:autonect/view/screens/electrician/dash_board/electrician_avalibilty_page.dart';
import 'package:autonect/view/screens/electrician/dash_board/manage_services.dart';
import 'package:autonect/view/screens/electrician/nav_bar/nav_bar.dart';
import 'package:autonect/view/screens/electrician/registration/service_provider_registration.dart';
import 'package:autonect/view/screens/launch/onboarding/onboarding.dart';
import 'package:autonect/view/screens/launch/role.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    splashScreenHandler();
  }

  void splashScreenHandler() {
    Timer(
      Duration(seconds: 2),
      () => Get.offAll(
        () => OnboardingScreen(),
        // RolePage(),
        //============== BUYER ====================
        // BuyerHomePage(),
        // AddPartRequestPage(),
        // RequestStatusTrackingPage(),
        // ServicePage(),
        //============== ===== ====================
        //============== Electrician ====================
        // ServiceProviderRegistrationPage(),
        // ElectricianHomePage(),
        // ElectricianMyBookingsPage(),
        // ElectricianBookingDetailsPage(),
        // ManageServicesPage(),
        // ElectricianAvailabilityPage(),
        // TotalBalancePage(),
        // ElectricianNavBar(),

        // ------------
        // ------------
        // ------------
        // ------------
        // ChatHomePage(),
      ),
    );
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

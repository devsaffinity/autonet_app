import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/screens/buyer/services/my_booking.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/profile_menu_tile.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Buyer profile — tab 4 of `BuyerNavBar` and one of the app's logout paths.
class BuyerProfilePage extends StatelessWidget {
  const BuyerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "Profile", hasBackButton: false),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Identity block
            Center(
              child: Column(
                children: [
                  CommonImageView(
                    url: 'https://randomuser.me/api/portraits/women/44.jpg',
                    height: 90,
                    width: 90,
                    radius: 45,
                    fit: BoxFit.cover,
                  ),
                  MyText(
                    paddingTop: 12,
                    text: 'Lorem Ipsum',
                    size: 18,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                  MyText(
                    paddingTop: 2,
                    text: 'buyer@autonect.com',
                    size: 13,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ProfileMenuTile(
              icon: Icons.event_note_outlined,
              label: 'My Bookings',
              onTap: () => Get.to(() => const MyBookingsPage()),
            ),
            ProfileMenuTile(
              icon: Icons.receipt_long_outlined,
              label: 'My Requests',
              // Requests live in tab 1 of the shell. maybeOf() is nullable on
              // purpose — this page is also reachable as a standalone push,
              // where there is no shell ancestor. Never bang it.
              onTap: () => RoleShell.maybeOf(context)?.goTo(1),
            ),
            ProfileMenuTile(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              // TODO(screens): there is no notifications screen in lib/ yet.
              onTap: () => Get.snackbar(
                "Notifications",
                "You have no new notifications",
                backgroundColor: kWhiteColor,
              ),
            ),
            ProfileMenuTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              isDestructive: true,
              onTap: () => RoleController.to.signOut(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

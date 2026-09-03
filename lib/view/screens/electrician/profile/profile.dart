import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/screens/electrician/dash_board/electrician_avalibilty_page.dart';
import 'package:autonect/view/screens/electrician/dash_board/manage_services.dart';
import 'package:autonect/view/screens/electrician/dash_board/total_balance.dart';
import 'package:autonect/view/screens/electrician/home/electrician_booking.dart';
import 'package:autonect/view/screens/electrician/review/review.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/profile_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 of ElectricianNavBar. Before this screen existed the Profile tab
// rendered a second ElectricianHomePage(); it is also the app's only route to
// the availability, services, earnings and reviews screens, plus the first
// logout path.
// ─────────────────────────────────────────────────────────────────────────────

class ElectricianProfilePage extends StatelessWidget {
  const ElectricianProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Profile', hasBackButton: false),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 24),
            MyText(
              text: 'MANAGE',
              size: 10,
              weight: FontWeight.w700,
              color: kSecondaryColor,
              letterSpacing: 1,
              paddingBottom: 12,
            ),
            ProfileMenuTile(
              icon: Icons.build_outlined,
              label: 'Manage Services',
              onTap: () => Get.to(() => const ManageServicesPage()),
            ),
            ProfileMenuTile(
              icon: Icons.calendar_today_outlined,
              label: 'Availability',
              onTap: () => Get.to(() => const ElectricianAvailabilityPage()),
            ),
            ProfileMenuTile(
              icon: Icons.event_note_outlined,
              label: 'My Bookings',
              onTap: () => Get.to(() => const ElectricianMyBookingsPage()),
            ),
            ProfileMenuTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Earnings',
              trailingText: '\$1,240',
              onTap: () => Get.to(() => const TotalBalancePage()),
            ),
            ProfileMenuTile(
              icon: Icons.star_outline_rounded,
              label: 'Reviews',
              trailingText: '4.9',
              onTap: () => Get.to(() => const ElectricianReviewPage()),
            ),
            const SizedBox(height: 12),
            MyText(
              text: 'ACCOUNT',
              size: 10,
              weight: FontWeight.w700,
              color: kSecondaryColor,
              letterSpacing: 1,
              paddingBottom: 12,
            ),
            ProfileMenuTile(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () {},
            ),
            ProfileMenuTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              isDestructive: true,
              onTap: _confirmLogout,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: AppStyling().myDecoration(
            color: kSecondaryColor,
            borderColor: kSecondaryColor,
            radius: 100,
          ),
          padding: const EdgeInsets.all(.3),
          child: ClipOval(
            child: CommonImageView(
              imagePath: Assets.imagesProfileImage,
              width: 66,
              height: 66,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Alex Chen',
                size: 20,
                weight: FontWeight.w800,
                color: kBlackColor,
                paddingBottom: 4,
              ),
              MyText(
                text: 'Electrician / Coder • London',
                size: 12,
                weight: FontWeight.w400,
                color: kGreyTextColor,
                paddingBottom: 8,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kLightOrangeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 11,
                      color: kSecondaryColor,
                    ),
                    const SizedBox(width: 3),
                    MyText(
                      text: 'VERIFIED PROVIDER',
                      size: 10,
                      weight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: AppStyling().myShadowStyle(),
      child: Row(
        children: [
          _stat('4.9', 'RATING'),
          _divider(),
          _stat('128', 'JOBS DONE'),
          _divider(),
          _stat('94%', 'ACCEPTANCE'),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 32, color: kTertiaryColor);

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          MyText(
            text: value,
            size: 18,
            weight: FontWeight.w800,
            color: kBlackColor,
            paddingBottom: 2,
          ),
          MyText(
            text: label,
            size: 10,
            weight: FontWeight.w600,
            color: kGreyTextColor,
          ),
        ],
      ),
    );
  }

  // ── Log out ────────────────────────────────────────────────────────────────
  void _confirmLogout() {
    Get.bottomSheet(
      MyBSheet(
        btnText: 'Log out',
        onTap: () => RoleController.to.signOut(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(
              text: 'Log out?',
              size: 20,
              weight: FontWeight.w800,
              color: kBlackColor,
              paddingBottom: 8,
            ),
            MyText(
              text:
                  'You will be signed out of Autonect and returned to the role screen. Your saved bookings stay on your account.',
              size: 14,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              paddingBottom: 8,
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

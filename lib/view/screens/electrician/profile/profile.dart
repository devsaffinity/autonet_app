import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/controller/electrician/provider_dashboard_controller.dart';
import 'package:autonect/data/models/provider_dashboard.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/electrician/dash_board/electrician_avalibilty_page.dart';
import 'package:autonect/view/screens/electrician/dash_board/manage_services.dart';
import 'package:autonect/view/screens/electrician/dash_board/total_balance.dart';
import 'package:autonect/view/screens/electrician/home/electrician_booking.dart';
import 'package:autonect/view/screens/buyer/notifications/notifications_page.dart';
import 'package:autonect/view/screens/electrician/profile/edit_provider_profile.dart';
import 'package:autonect/view/screens/electrician/review/review.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
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

class ElectricianProfilePage extends StatefulWidget {
  const ElectricianProfilePage({super.key});

  @override
  State<ElectricianProfilePage> createState() =>
      _ElectricianProfilePageState();
}

class _ElectricianProfilePageState extends State<ElectricianProfilePage> {
  final ProfileController _profile = ProfileController.ensure();
  final ProviderDashboardController _dashboard =
      ProviderDashboardController.ensure();

  @override
  void initState() {
    super.initState();
    _profile.load();
    // JOBS DONE comes from the same dashboard the earnings screen reads,
    // rather than a second count that could disagree with it.
    _dashboard.load();
  }

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
              icon: Icons.edit_outlined,
              label: 'Edit Profile',
              // Re-reads on the way back so the header and stats reflect an
              // edit that just landed.
              onTap: () async {
                await Get.to<void>(() => const EditProviderProfilePage());
                await _profile.load();
              },
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
            // Both trailing values were literals, and the earnings one was in
            // dollars in a GBP-only product. They now read the same sources
            // the screens behind them do, so tapping through cannot show a
            // different number from the one that led you there.
            Obx(() {
              final dash = _dashboard.state.value;
              return ProfileMenuTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Earnings',
                trailingText: dash is Data<ProviderDashboard>
                    ? formatPence(dash.value.workCompletedPence)
                    : null,
                onTap: () => Get.to(() => const TotalBalancePage()),
              );
            }),
            Obx(() {
              final provider = _profile.me?.electricianProfile;
              return ProfileMenuTile(
                icon: Icons.star_outline_rounded,
                label: 'Reviews',
                // Omitted rather than '0.0' when nobody has reviewed them yet.
                trailingText: (provider?.ratingCount ?? 0) == 0
                    ? null
                    : provider!.ratingAvg.toStringAsFixed(1),
                onTap: () => Get.to(() => const ElectricianReviewPage()),
              );
            }),
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
              // Was a dead tap. NotificationsPage reads its own controller and
              // is not buyer-specific, so it serves a provider unchanged.
              onTap: () => Get.to(() => const NotificationsPage()),
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
    return Obx(() {
      final me = _profile.me;
      final provider = me?.electricianProfile;
      final avatar = me?.avatarUrl;
      final name = provider?.fullName ?? me?.name ?? 'Your profile';
      final approved = provider?.approved ?? false;

      return Row(
        children: [
          Semantics(
            button: true,
            label: 'Change profile photo',
            child: InkWell(
              onTap: _profile.changeAvatar,
              customBorder: const CircleBorder(),
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: AppStyling().myDecoration(
                            color: kSecondaryColor,
                            borderColor: kSecondaryColor,
                            radius: 100,
                          ),
                          padding: const EdgeInsets.all(.3),
                          child: ClipOval(
                            child: (avatar != null && avatar.isNotEmpty)
                                ? CommonImageView(
                                    url: avatar,
                                    cacheKey: me?.id,
                                    width: 66,
                                    height: 66,
                                    fit: BoxFit.cover,
                                    errorWidget: InitialsAvatar(
                                      name: name,
                                      size: 66,
                                      radius: 100,
                                    ),
                                  )
                                : InitialsAvatar(
                                    name: name,
                                    size: 66,
                                    radius: 100,
                                  ),
                          ),
                        ),
                      ),
                      if (_profile.uploadingAvatar.value)
                        const Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: kSecondaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: kPrimaryColor, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 12,
                            color: kWhiteColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: name,
                  size: 20,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                  paddingBottom: 4,
                ),
                MyText(
                  text: provider?.headline ?? 'No headline yet',
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
                    color: approved ? kLightOrangeColor : kTertiaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        approved
                            ? Icons.verified_rounded
                            : Icons.hourglass_empty_rounded,
                        size: 11,
                        color: approved ? kSecondaryColor : kGreyTextColor,
                      ),
                      const SizedBox(width: 3),
                      MyText(
                        text: approved
                            ? 'VERIFIED PROVIDER'
                            : 'AWAITING APPROVAL',
                        size: 10,
                        weight: FontWeight.w700,
                        color: approved ? kSecondaryColor : kGreyTextColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: AppStyling().myShadowStyle(),
      child: Obx(() {
        final provider = _profile.me?.electricianProfile;
        final dash = _dashboard.state.value;
        final completed = dash is Data<ProviderDashboard>
            ? '${dash.value.completedCount}'
            : '—';
        // A provider with no reviews yet has no rating; '0.0' would read as a
        // bad one, which is the opposite of the truth.
        final rating = (provider?.ratingCount ?? 0) == 0
            ? '—'
            : provider!.ratingAvg.toStringAsFixed(1);
        return Row(
          children: [
            _stat(rating, 'RATING'),
            _divider(),
            _stat(completed, 'JOBS DONE'),
            _divider(),
            // 'ACCEPTANCE 94%' is gone rather than replaced: nothing records a
            // declined booking as declined — a provider cancels, which is not
            // the same event — so there is no honest number to put here. The
            // review count is real and is what a buyer actually weighs.
            _stat('${provider?.ratingCount ?? 0}', 'REVIEWS'),
          ],
        );
      }),
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

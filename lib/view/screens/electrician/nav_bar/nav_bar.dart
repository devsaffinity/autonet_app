import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/chat/chat_home.dart';
import 'package:autonect/view/screens/electrician/home/booking_requests.dart';
import 'package:autonect/view/screens/electrician/home/electrician_booking.dart';
import 'package:autonect/view/screens/electrician/home/home.dart';
import 'package:autonect/view/screens/electrician/profile/profile.dart';
import 'package:autonect/view/widget/role_nav_bar.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The class name and file path are deliberately unchanged — routes.dart and
// the RoleGuard both reference them. The bar, the IndexedStack and the tab
// index now live in RoleShell/RoleNavBar so the buyer and supplier shells are
// the same widget with a different tab list.
//
// Per-role nav glyphs are a design deliverable: assets/images/ ships exactly
// one nav icon set (e_home / e_calender / e_setting / e_chat), so all three
// shells share it for now.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:autonect/controller/chat/chat_inbox_controller.dart';
import 'package:get/get.dart';

class ElectricianNavBar extends StatelessWidget {
  const ElectricianNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = ChatInboxController.ensure();
    return Obx(() {
      final unread = chat.totalUnreadCount;
      return RoleShell(
        items: [
          const NavItem(
            label: 'Home',
            iconFill: Assets.imagesEHomeFill,
            iconOutline: Assets.imagesEHomeOutline,
          ),
          const NavItem(
            label: 'Bookings',
            iconFill: Assets.imagesECalenderFill,
            iconOutline: Assets.imagesECalenderOutline,
          ),
          const NavItem(
            label: 'Requests',
            iconFill: Assets.imagesESettingFill,
            iconOutline: Assets.imagesESettingOutline,
          ),
          NavItem(
            label: 'Chat',
            iconFill: Assets.imagesEChatFill,
            iconOutline: Assets.imagesEChatOutline,
            badgeCount: unread,
          ),
          const NavItem(
            label: 'Profile',
            iconFill: Assets.imagesProfileImage,
            iconOutline: Assets.imagesProfileImage,
            isAvatar: true,
          ),
        ],
        screens: const [
          ElectricianHomePage(),
          ElectricianMyBookingsPage(),
          ElectricianBookingRequestPage(),
          ChatHomePage(),
          ElectricianProfilePage(),
        ],
      );
    });
  }
}

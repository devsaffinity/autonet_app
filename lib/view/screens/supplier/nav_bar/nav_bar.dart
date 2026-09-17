import 'package:autonect/constants/app_images.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/chat/chat_inbox_controller.dart';
import 'package:autonect/view/screens/chat/chat_home.dart';
import 'package:autonect/view/screens/supplier/home/home.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_offers.dart';
import 'package:autonect/view/screens/supplier/profile/profile.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_leads.dart';
import 'package:autonect/view/widget/role_nav_bar.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The supplier shell. Five tabs, five distinct screens — RoleShell's assert
/// forbids reusing one screen at two indexes.
class SupplierNavBar extends StatelessWidget {
  const SupplierNavBar({super.key});

  static const List<NavItem> _navItems = [
    NavItem(
      label: 'Home',
      iconFill: Assets.imagesEHomeFill,
      iconOutline: Assets.imagesEHomeOutline,
    ),
    NavItem(
      label: 'Leads',
      iconFill: Assets.imagesECalenderFill,
      iconOutline: Assets.imagesECalenderOutline,
    ),
    NavItem(
      label: 'Offers',
      iconFill: Assets.imagesESettingFill,
      iconOutline: Assets.imagesESettingOutline,
    ),
    NavItem(
      label: 'Chat',
      iconFill: Assets.imagesEChatFill,
      iconOutline: Assets.imagesEChatOutline,
    ),
    NavItem(
      label: 'Profile',
      iconFill: Assets.imagesProfileImage,
      iconOutline: Assets.imagesProfileImage,
      isAvatar: true,
    ),
  ];

  static const List<Widget> _screens = [
    SupplierHomePage(),
    SupplierLeadsPage(),
    SupplierOffersPage(),
    ChatHomePage(),
    SupplierProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final chat = ChatInboxController.ensure();
    final profile = ProfileController.ensure();
    return Obx(() {
      final unread = chat.totalUnreadCount;
      final avatarUrl = profile.me?.avatarUrl;
      final items = [
        _navItems[0],
        _navItems[1],
        _navItems[2],
        NavItem(
          label: 'Chat',
          iconFill: Assets.imagesEChatFill,
          iconOutline: Assets.imagesEChatOutline,
          badgeCount: unread,
        ),
        NavItem(
          label: 'Profile',
          iconFill: Assets.imagesProfileImage,
          iconOutline: Assets.imagesProfileImage,
          isAvatar: true,
          avatarUrl: avatarUrl,
        ),
      ];
      return RoleShell(items: items, screens: _screens);
    });
  }
}

import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/chat/chat_home.dart';
import 'package:autonect/view/screens/supplier/home/home.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_offers.dart';
import 'package:autonect/view/screens/supplier/profile/profile.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_leads.dart';
import 'package:autonect/view/widget/role_nav_bar.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';

/// The supplier shell. Five tabs, five distinct screens — RoleShell's assert
/// forbids reusing one screen at two indexes.
///
/// The icon set is the only nav glyph set in assets/images/; per-role glyphs
/// (a lead/offer icon rather than a calendar/cog) are a design deliverable and
/// are flagged at handover rather than invented here.
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
    return const RoleShell(items: _navItems, screens: _screens);
  }
}

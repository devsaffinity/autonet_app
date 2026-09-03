import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/buyer/home/home.dart';
import 'package:autonect/view/screens/buyer/profile/profile.dart';
import 'package:autonect/view/screens/buyer/request/request_status_tracking.dart';
import 'package:autonect/view/screens/buyer/services/services.dart';
import 'package:autonect/view/screens/chat/chat_home.dart';
import 'package:autonect/view/widget/role_nav_bar.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';

/// Buyer shell — the destination of `AppLinks.buyerShell`.
///
/// Five tabs, five DISTINCT screens: the `assert` inside `RoleShell` makes the
/// index-4-duplicates-index-0 bug that ElectricianNavBar shipped with
/// structurally impossible to reintroduce here.
///
/// Icon set note for design: assets/images/ currently holds exactly one nav
/// glyph set (e_home / e_calender / e_setting / e_chat), so all three shells
/// share it. Per-role glyphs are a design deliverable, not an invention for us
/// to make — do not add Assets keys that have no file behind them.
class BuyerNavBar extends StatelessWidget {
  const BuyerNavBar({super.key});

  // ── Tab config ─────────────────────────────────────────────────────────────
  static const List<NavItem> _navItems = [
    NavItem(
      label: 'Home',
      iconFill: Assets.imagesEHomeFill,
      iconOutline: Assets.imagesEHomeOutline,
    ),
    NavItem(
      label: 'Requests',
      iconFill: Assets.imagesECalenderFill,
      iconOutline: Assets.imagesECalenderOutline,
    ),
    NavItem(
      label: 'Services',
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

  // ── Screens list ───────────────────────────────────────────────────────────
  // This single list is what un-orphans the buyer tree. Everything else is
  // reachable from these four roots:
  //   RequestStatusTracking -> Comparison -> Report -> OfferDetail
  //                         -> OrderSummary -> OrderStatus -> Review
  //   Service -> ExpertProfile -> NewBooking -> BookingConfirmed -> MyBookings
  //   Home    -> AddPartRequest
  //   ChatHome -> ChatRoom
  static const List<Widget> _screens = [
    BuyerHomePage(),
    RequestStatusTrackingPage(),
    ServicePage(),
    ChatHomePage(),
    BuyerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return const RoleShell(items: _navItems, screens: _screens);
  }
}

import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/buyer/home/home.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/screens/buyer/orders/my_orders.dart';
import 'package:autonect/view/screens/buyer/request/request_status_tracking.dart';
import 'package:autonect/view/screens/chat/chat_home.dart';
import 'package:autonect/view/widget/role_nav_bar.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Buyer shell — the destination of `AppLinks.buyerShell`.
///
/// FOUR tabs, four DISTINCT screens, split 2 | 2 around the centre FAB: the
/// `assert` inside `RoleShell` makes the index-4-duplicates-index-0 bug that
/// ElectricianNavBar shipped with structurally impossible to reintroduce here.
///
/// Profile is deliberately NOT a tab. The design puts a centre action where the
/// fifth tab used to sit, and profile is a once-a-session destination, so it
/// moved to a tappable avatar in `BuyerHomePage`'s header and is pushed with
/// `Get.to`. Tab indices 0-3 kept their old meaning, so every existing
/// `goTo(1)` still lands on Requests.
///
/// Icon set note for design: assets/images/ currently holds exactly one nav
/// glyph set (e_home / e_calender / e_setting / e_chat), so all three shells
/// share it — and there is no orders glyph in it, which is why tab 2 keeps the
/// setting pair under an Orders label. Per-role glyphs are a design
/// deliverable, not an invention for us to make — do not add Assets keys that
/// have no file behind them.
class BuyerNavBar extends StatelessWidget {
  const BuyerNavBar({super.key, this.initialIndex = 0});

  /// Index of the Requests tab in [_navItems]/[_screens]. Named so a caller
  /// landing the buyer on their requests does not re-derive a tab position
  /// from a list it cannot see.
  static const int requestsTab = 1;

  /// Which tab the shell opens on. A recovery route — see `ConfirmStepView`,
  /// where an unconfirmed create sends the buyer to check their requests —
  /// re-enters the SHELL here rather than pushing the bare page, which would
  /// arrive with no back button and no nav bar.
  final int initialIndex;

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
      label: 'Orders',
      iconFill: Assets.imagesESettingFill,
      iconOutline: Assets.imagesESettingOutline,
    ),
    NavItem(
      label: 'Chat',
      iconFill: Assets.imagesEChatFill,
      iconOutline: Assets.imagesEChatOutline,
    ),
  ];

  // ── Screens list ───────────────────────────────────────────────────────────
  // This single list is what un-orphans the buyer tree. Everything else is
  // reachable from these four roots:
  //   RequestStatusTracking -> Comparison -> Report -> OfferDetail
  //                         -> OrderSummary -> OrderStatus -> Review
  //   MyOrders -> OrderStatus -> Review
  //   Home     -> AddPartRequest
  //   ChatHome -> ChatRoom
  //
  // Tab 3 was the services/booking journey, which has NO backend at all; the
  // orders list, which does, had no entry point anywhere in the app.
  static const List<Widget> _screens = [
    BuyerHomePage(),
    RequestStatusTrackingPage(),
    MyOrdersPage(),
    ChatHomePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      items: _navItems,
      screens: _screens,
      initialIndex: initialIndex,
      // Same call as Home's 'Request a Part' button and the two entry points on
      // RequestStatusTracking — one wizard, one way in. It pushes ON TOP of the
      // shell rather than replacing a tab, so the buyer keeps their place and
      // Get.back() returns them to whichever tab they left.
      centerAction: NavCenterAction(
        semanticLabel: 'New part request',
        onTap: () => Get.to(() => const AddPartRequestPage()),
      ),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/chat/chat_home.dart';
import 'package:autonect/view/screens/electrician/home/booking_requests.dart';
import 'package:autonect/view/screens/electrician/home/electrician_booking.dart';
import 'package:autonect/view/screens/electrician/home/home.dart';
import 'package:autonect/view/screens/electrician/home/upcoming_booking_details.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

// ── Screens ───────────────────────────────────────────────────────────────────

class ElectricianNavBar extends StatefulWidget {
  const ElectricianNavBar({super.key});

  @override
  State<ElectricianNavBar> createState() => _ElectricianNavBarState();
}

class _ElectricianNavBarState extends State<ElectricianNavBar> {
  int _currentIndex = 0;

  // ── Tab config ───────────────────────────────────────────────────────────
  final List<_NavItem> _navItems = const [
    _NavItem(
      label: 'Home',
      iconFill: Assets.imagesEHomeFill,
      iconOutline: Assets.imagesEHomeOutline,
    ),
    _NavItem(
      label: 'Calendar',
      iconFill: Assets.imagesECalenderFill,
      iconOutline: Assets.imagesECalenderOutline,
    ),
    _NavItem(
      label: 'Setting',
      iconFill: Assets.imagesESettingFill,
      iconOutline: Assets.imagesESettingOutline,
    ),
    _NavItem(
      label: 'Chat',
      iconFill: Assets.imagesEChatFill,
      iconOutline: Assets.imagesEChatOutline,
    ),
    _NavItem(
      label: 'Profile',
      iconFill: Assets.imagesProfileImage,
      iconOutline: Assets.imagesProfileImage,
    ),
  ];

  // ── Screens list ─────────────────────────────────────────────────────────
  final List<Widget> _screens = const [
    ElectricianHomePage(),
    ElectricianMyBookingsPage(),
    ElectricianBookingRequestPage(),
    ChatHomePage(),
    ElectricianHomePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom Nav Bar Widget ─────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: kGreyTextColor.withOpacity(0.4),
                  blurRadius: 7,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                return Expanded(
                  child: _NavTabItem(
                    item: items[i],
                    isSelected: i == currentIndex,
                    onTap: () => onTap(i),
                    index: i,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Tab Item ──────────────────────────────────────────────────────────────

class _NavTabItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kWhiteColor.withOpacity(0.15) : kTransperentColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CommonImageView(
              radius: 100,
              imagePath: isSelected ? item.iconFill : item.iconOutline,
              height: (index == 4) ? 22 : 22,
              width: 22,
              fit: (index == 4) ? BoxFit.cover : BoxFit.contain,
              // imageColor: isSelected
              //     ? kWhiteColor
              //     : kWhiteColor.withOpacity(0.5),
            ),
            // const SizedBox(height: 4),
            // MyText(
            //   text: item.label,
            //   size: 11,
            //   weight: isSelected ? FontWeight.w600 : FontWeight.w400,
            //   color: isSelected ? kWhiteColor : kWhiteColor.withOpacity(0.5),
            // ),
          ],
        ),
      ),
    );
  }
}

// ── Nav Item Model ────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final String iconFill;
  final String iconOutline;
  const _NavItem({
    required this.label,
    required this.iconFill,
    required this.iconOutline,
  });
}

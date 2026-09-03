import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:flutter/material.dart';

// Lifted verbatim out of electrician/nav_bar/nav_bar.dart so all three role
// shells share ONE bar. Every pixel value below is the original: 60 height,
// BorderRadius.circular(40), kPrimaryColor, kGreyTextColor.withOpacity(0.4)
// blurRadius 7, kWhiteColor.withOpacity(0.15) selected chip,
// BorderRadius.circular(30), 200ms AnimatedContainer,
// EdgeInsets.fromLTRB(16, 8, 16, 20), margin symmetric(horizontal: 6,
// vertical: 10) and 22px icons. Do not copy this bar into the buyer or
// supplier files.

// ── Bottom Nav Bar Widget ─────────────────────────────────────────────────────

class RoleNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const RoleNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                color: kGreyTextColor.withValues(alpha: 0.4),
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
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Nav Tab Item ──────────────────────────────────────────────────────────────

class _NavTabItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
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
          color: isSelected
              ? kWhiteColor.withValues(alpha: 0.15)
              : kTransperentColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CommonImageView(
              radius: 100,
              imagePath: isSelected ? item.iconFill : item.iconOutline,
              height: 22,
              width: 22,
              // The avatar tab is a photo, not a glyph, so it crops instead of
              // letterboxing. This used to be `index == 4`, which hard-coded
              // the tab position.
              fit: item.isAvatar ? BoxFit.cover : BoxFit.contain,
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

class NavItem {
  final String label;
  final String iconFill;
  final String iconOutline;

  /// True for the profile tab, whose icon is a user photo and must crop.
  final bool isAvatar;

  const NavItem({
    required this.label,
    required this.iconFill,
    required this.iconOutline,
    this.isAvatar = false,
  });
}

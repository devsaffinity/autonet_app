import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Icon + label + chevron row shared by the buyer, supplier and electrician
/// profile screens. `isDestructive` tints the Log out tile.
class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;
  final bool isDestructive;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color tint = isDestructive ? kRedColor : kSecondaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MyRippleEffect(
        onTap: onTap,
        radius: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: AppStyling().myShadowStyle(),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDestructive ? kTertiaryColor : kLightOrangeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
                  text: label,
                  size: 14,
                  weight: FontWeight.w600,
                  color: isDestructive ? kRedColor : kBlackColor,
                ),
              ),
              if (trailingText != null)
                MyText(
                  text: trailingText!,
                  size: 12,
                  weight: FontWeight.w500,
                  color: kGreyTextColor,
                  paddingRight: 6,
                ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDestructive ? kRedColor : kGreyTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

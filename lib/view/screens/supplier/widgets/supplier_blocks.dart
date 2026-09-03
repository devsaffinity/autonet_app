import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The 'Privacy First' reassurance panel from the electrician registration
/// wizard, with icon and copy exposed so the supplier KYC steps reuse it.
class SupplierNoteCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const SupplierNoteCard({
    super.key,
    this.icon = Icons.safety_check_outlined,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppStyling().myDecoration(
        color: kSecondaryColor.withValues(alpha: .1),
        borderColor: kTransperentColor,
        radius: 9,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kSecondaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  paddingBottom: 3,
                  text: title,
                  size: 12,
                  color: kBlackColor,
                  weight: FontWeight.w600,
                ),
                MyText(
                  text: body,
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// label — value on one line, the buyer's `_PriceRow`.
class SupplierPriceRow extends StatelessWidget {
  final String label, value;
  final bool isTotal;
  const SupplierPriceRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(
          text: label,
          size: 14,
          weight: isTotal ? FontWeight.w700 : FontWeight.w400,
          color: kBlackColor,
        ),
        MyText(
          text: value,
          size: 14,
          weight: isTotal ? FontWeight.w700 : FontWeight.w400,
          color: isTotal ? kSecondaryColor : kBlackColor,
        ),
      ],
    );
  }
}

/// Thumbnail + title + subtitle + trailing — the booking row the electrician
/// home renders inside a single shadowed card, generalised for leads and orders.
class SupplierListRow extends StatelessWidget {
  final String image;
  final String title, subtitle, trailing;
  final Widget? badge;
  final VoidCallback? onTap;
  const SupplierListRow({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    this.trailing = '',
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kTertiaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CommonImageView(
                  imagePath: image,
                  width: 48,
                  height: 48,
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
                    text: title,
                    size: 14,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                  MyText(
                    paddingTop: 2,
                    text: subtitle,
                    size: 12,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            badge ??
                MyText(
                  text: trailing,
                  size: 12,
                  weight: FontWeight.w600,
                  color: kSecondaryColor,
                ),
          ],
        ),
      ),
    );
  }
}

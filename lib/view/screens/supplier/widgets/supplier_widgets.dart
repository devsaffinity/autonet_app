import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared supplier building blocks. Every one of these is the same box the buyer
// and electrician screens already draw — no new styling primitives, only the
// existing AppStyling()/AppColors tokens re-composed so the nine supplier
// screens stay under 200 lines each.
// ─────────────────────────────────────────────────────────────────────────────

/// White shadow card — the same container as `_Card` in buyer/detail/offer_detail.dart.
class SupplierCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SupplierCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppStyling().myShadowStyle(),
      child: child,
    );
  }
}

/// Sticky wizard footer — mirrors `_BottomButton` in the electrician
/// registration wizard and in new_part_request.dart.
class SupplierBottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SupplierBottomButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: kPrimaryColor,
      child: MyButton(buttonText: label, onTap: onTap),
    );
  }
}

/// svg icon + title + subtitle — mirrors `_TitleRow` in the electrician
/// registration wizard, used by the KYC upload cards.
class SupplierTitleRow extends StatelessWidget {
  final String icon;
  final String title, subTitle;
  const SupplierTitleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonImageView(svgPath: icon, width: 26, height: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: title,
                size: 16,
                weight: FontWeight.w700,
                paddingBottom: 1,
              ),
              MyText(
                text: subTitle,
                size: 12,
                weight: FontWeight.w400,
                color: kGreyTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 'Section title  ·  View All' row — the same pair the electrician home draws
/// above Upcoming Bookings.
class SupplierSectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  const SupplierSectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'View All',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(
          text: title,
          size: 16,
          weight: FontWeight.w700,
          color: kBlackColor,
        ),
        if (onAction != null)
          MyRippleEffect(
            onTap: onAction!,
            radius: 6,
            child: MyText(
              text: actionLabel,
              size: 13,
              weight: FontWeight.w600,
              color: kSecondaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
      ],
    );
  }
}

/// Label over value — the buyer's `_DetailItem` from offer_detail.dart.
class SupplierDetailItem extends StatelessWidget {
  final String label, value;
  const SupplierDetailItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: label,
          size: 14,
          weight: FontWeight.w400,
          color: kGreyTextColor,
          paddingBottom: 4,
        ),
        MyText(
          text: value,
          size: 14,
          weight: FontWeight.w600,
          color: kBlackColor,
        ),
      ],
    );
  }
}

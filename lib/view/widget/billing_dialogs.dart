import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The plans screens' confirm dialog — one look for upgrade, cancel and
/// resume, on both roles. Resolves true only on the confirm button.
Future<bool> confirmBillingDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  String? headline,
  String? badge,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: kPrimaryColor,
      title: Row(
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xffFF9500), borderRadius: BorderRadius.circular(4)),
              child: MyText(text: badge, size: 11, weight: FontWeight.w800, color: kWhiteColor),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(child: MyText(text: title, size: 18, weight: FontWeight.w700, color: kBlackColor)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headline != null)
            MyText(text: headline, size: 24, weight: FontWeight.w800, color: kBlackColor, paddingBottom: 8),
          MyText(text: message, size: 14, weight: FontWeight.w400, color: kGreyTextColor, lineHeight: 1.5),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const MyText(text: 'Not now', size: 14, weight: FontWeight.w600, color: kGreyTextColor),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? kRedColor : kSecondaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: MyText(text: confirmText, size: 14, weight: FontWeight.w700, color: kWhiteColor),
        ),
      ],
    ),
  );
  return result == true;
}

/// Keep vs leave — returns a dialog that pops true for [leaveText].
Widget billingChoiceDialog(
  BuildContext ctx, {
  required String title,
  required String message,
  required String keepText,
  required String leaveText,
}) => AlertDialog(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  backgroundColor: kPrimaryColor,
  title: MyText(text: title, size: 18, weight: FontWeight.w700, color: kBlackColor),
  content: MyText(text: message, size: 14, weight: FontWeight.w400, color: kGreyTextColor),
  actions: [
    TextButton(
      onPressed: () => Navigator.of(ctx).pop(false),
      child: MyText(text: keepText, size: 14, weight: FontWeight.w600, color: kSecondaryColor),
    ),
    TextButton(
      onPressed: () => Navigator.of(ctx).pop(true),
      child: MyText(text: leaveText, size: 14, weight: FontWeight.w600, color: kRedColor),
    ),
  ],
);

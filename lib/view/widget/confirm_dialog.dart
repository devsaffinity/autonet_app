import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/view/widget/custom_dialog_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// THE confirm dialog for an action that cannot be undone: a verb, what it
/// costs, and two buttons that each fire AT MOST ONCE.
///
/// The one-shot half is why this is a widget rather than four lines inlined
/// wherever it is needed. Both buttons pop, and two taps inside one frame both
/// reach the callback the last build handed the InkWell — so the second pop
/// lands on the screen UNDERNEATH the dialog and takes the buyer off it.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.verb,
    required this.warning,
    this.keepLabel = 'Keep it open',
  });

  /// Doubles as the title and the confirming button's label, so the button the
  /// buyer presses says the same thing the question asked.
  final String verb;

  final String warning;
  final String keepLabel;

  @override
  Widget build(BuildContext context) => CustomDialog(
    child: Padding(
      padding: const EdgeInsets.all(AppSizes.s20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyText(
            text: verb,
            size: AppTextScale.title,
            weight: AppWeights.bold,
            textAlign: TextAlign.center,
            paddingBottom: AppSizes.s8,
          ),
          MyText(
            text: warning,
            size: AppTextScale.body,
            color: kGreyTextColor,
            textAlign: TextAlign.center,
            paddingBottom: AppSizes.s20,
          ),
          MyButton(
            buttonText: verb,
            fontSize: AppTextScale.body,
            oneShot: true,
            onTap: () => Get.back<bool>(result: true),
          ),
          MyButton(
            mTop: AppSizes.s12,
            buttonText: keepLabel,
            backgroundColor: kWhiteColor,
            outlineColor: kSecondaryColor,
            fontColor: kSecondaryColor,
            fontSize: AppTextScale.body,
            oneShot: true,
            onTap: () => Get.back<bool>(result: false),
          ),
        ],
      ),
    ),
  );
}

import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Withdraw confirmation, same MyBSheet shell as every other confirm in the app.
class WithdrawOfferBSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  const WithdrawOfferBSheet({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return MyBSheet(
      btnText: 'Withdraw Offer',
      onTap: () {
        Get.back();
        onConfirm();
      },
      body: Column(
        children: [
          CommonImageView(
            width: 60,
            height: 60,
            svgPath: Assets.imagesDeleteOferIcon,
          ),
          MyText(
            textAlign: TextAlign.center,
            paddingBottom: 20,
            paddingTop: 24,
            text: 'Withdraw this offer?',
            size: 20,
            weight: FontWeight.w700,
          ),
          MyText(
            paddingBottom: 24,
            textAlign: TextAlign.center,
            text:
                'The buyer will no longer see it on their comparison. The credits you spent unlocking the request are not refunded.',
            size: 16,
            weight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}

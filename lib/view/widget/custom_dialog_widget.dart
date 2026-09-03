import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDialog extends StatelessWidget {
  final Widget child;
  final double? horizontalMargin;
  final Color? borderColor;
  const CustomDialog({
    super.key,
    required this.child,
    this.horizontalMargin = 32,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: MediaQuery.of(Get.context!).size.width < 600
                ? EdgeInsets.symmetric(horizontal: horizontalMargin!)
                : EdgeInsets.symmetric(horizontal: 150),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              border: Border.all(
                color: borderColor ?? kSecondaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      child: Padding(
        padding: EdgeInsetsGeometry.all(20),
        child: Column(
          children: [
            // CommonImageView(width: 128, imagePath: Assets.imagesLogoutPIcon),
            MyText(
              paddingBottom: 8,
              paddingTop: 15,
              text: "Leaving already?",
              size: 22,
              weight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            MyText(
              paddingBottom: 24,

              text:
                  "You'll be signed out for now, but you can easily log back in whenever needed. ",
              size: 14,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              textAlign: TextAlign.center,
            ),

            MyButton(
              buttonText: "Log Out",
              onTap: () {
                // Get.offAll(() => LoginPage());
              },
            ),
            MyButton(
              mTop: 12,
              buttonText: "Cancel",
              isGradient: false,
              backgroundColor: kWhiteColor,
              outlineColor: kSecondaryColor,
              fontColor: kSecondaryColor,
              onTap: () {
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}

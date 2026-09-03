import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

// ignore: must_be_immutable
class MyButton extends StatelessWidget {
  MyButton({
    this.onTap,
    required this.buttonText,
    this.height = 48,
    this.backgroundColor = kSecondaryColor,
    this.fontColor = kWhiteColor,
    this.fontSize = 16,
    this.outlineColor = kTransperentColor,
    this.radius = 100,
    this.icon,
    this.svgIconColor,
    this.haveSvg = false,
    this.isGradient = false,
    this.mBottom = 0,
    this.mTop = 0,
    this.iconSize,
    this.fontWeight = FontWeight.w600,
  });

  final String buttonText;
  final VoidCallback? onTap;
  final double? height;
  final double radius;
  final double fontSize;
  final Color outlineColor;
  final Color backgroundColor, fontColor;
  final Color? svgIconColor;
  final String? icon;
  final bool haveSvg;
  final bool isGradient;
  final double? iconSize;
  final double mTop, mBottom;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: mTop, bottom: mBottom),
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: outlineColor),
        // boxShadow: [
        //   BoxShadow(
        //     offset: Offset(0, 4),
        //     color: kPrimaryColor.withOpacity(0.25),
        //     blurRadius: 15,
        //     spreadRadius: 0,
        //   ),
        // ],
        borderRadius: BorderRadius.circular(radius),
        gradient: isGradient
            ? LinearGradient(
                begin: AlignmentGeometry.topCenter,
                end: AlignmentGeometry.bottomCenter,
                colors: [
                  // kGradient1Color,
                  // kGradient2Color,
                  kSecondaryColor,
                  kTertiaryColor,
                ],
              )
            : null,
      ),
      child: Material(
        color: kTransperentColor,
        child: InkWell(
          onTap: onTap,
          splashColor: kPrimaryColor.withOpacity(0.1),
          highlightColor: kTertiaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              (haveSvg == true)
                  ? CommonImageView(
                      svgPath: icon,
                      //svgIconColor: svgIconColor,
                      // height: iconSize,
                      width: iconSize,
                    )
                  : SizedBox(),
              MyText(
                paddingLeft: (haveSvg == true) ? 10 : 0,
                text: buttonText,
                size: fontSize,
                color: fontColor,
                weight: fontWeight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavButton extends StatelessWidget {
  String buttonText;
  VoidCallback onTap;
  NavButton({super.key, required this.buttonText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 20, right: 20, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [MyButton(mBottom: 12, onTap: onTap, buttonText: buttonText)],
      ),
    );
  }
}

class MyBackButton extends StatelessWidget {
  const MyBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(bottom: 25),
      child: MyRippleEffect(
        radius: 100,
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 15),
        onTap: () {
          Get.back();
        },
      ),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AppStyling {
  BoxDecoration myDecoration({
    Color color = kQuaternaryColor,
    double radius = 10,
    Color borderColor = kQuaternaryColor,
    double thickness = 1,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: thickness),
    );
  }

  BoxDecoration allFourSideRaius({
    Color color = kPrimaryColor,
    double topLeft = 20,
    double topRight = 20,
    double bottomLeft = 0,
    double bottomRight = 0,
    Color borderColor = kTransperentColor,
    double thickness = 1,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(topLeft),
        topRight: Radius.circular(topRight),
        bottomLeft: Radius.circular(bottomLeft),
        bottomRight: Radius.circular(bottomRight),
      ),
      border: Border.all(color: borderColor, width: thickness),
    );
  }

  BoxDecoration myShadowDecoration({
    Color color = kSecondaryColor,
    double radius = 10,
    Color borderColor = kTransperentColor,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.1),
          spreadRadius: 0.2,
          blurRadius: 5,
        ),
      ],
    );
  }

  BoxDecoration bottomSheetStyle() {
    return const BoxDecoration(
      color: kPrimaryColor,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    );
  }

  BoxDecoration myShadowStyle() {
    return BoxDecoration(
      color: kWhiteColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kGreyTextColor.withValues(alpha: .1)),
      boxShadow: [
        BoxShadow(
          spreadRadius: .2,
          blurRadius: 3,
          color: kBlackColor.withValues(alpha: .1),
        ),
      ],
    );
  }

  // BoxDecoration background() {
  //   return BoxDecoration(
  //     borderRadius: BorderRadius.circular(12),
  //     image: DecorationImage(
  //       image: AssetImage(Assets.imagesBkImage),
  //       fit: BoxFit.cover,
  //     ),
  //   );
  // }
}

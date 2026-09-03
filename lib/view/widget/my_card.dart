import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyCard extends StatelessWidget {
  Widget child;
  double? verticalPadding, horizontalPadding, radius;
  Color? color, strokColor;
  MyCard({
    super.key,
    required this.child,
    this.horizontalPadding,
    this.verticalPadding,
    this.radius = 8.0,
    this.color,
    this.strokColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding ?? 18,
        horizontal: horizontalPadding ?? 12,
      ),
      decoration: AppStyling().myDecoration(
        color: color ?? kWhiteColor,
        radius: radius ?? 8.0,
        borderColor: strokColor ?? kTertiaryColor,
      ),
      child: child,
    );
  }
}

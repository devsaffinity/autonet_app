import 'package:autonect/constants/app_colors.dart';
import 'package:flutter/material.dart';

class MyRoundButton extends StatelessWidget {
  final double height, width, splashRadius;
  final Color color, splashColor, borderColor;
  final VoidCallback onTap;
  final Widget child;
  final double borderStroke;

  const MyRoundButton({
    super.key,
    this.height = 36,
    this.width = 36,
    this.color = kWhiteColor,
    required this.onTap,
    required this.child,
    this.splashColor = kSecondaryColor,
    this.splashRadius = 36,
    this.borderColor = kTertiaryColor,
    this.borderStroke = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: borderStroke),
      ),
      child: Material(
        color: kTransperentColor,
        child: InkWell(
          onTap: onTap,
          radius: splashRadius,
          splashColor: splashColor.withValues(alpha: .3),
          borderRadius: BorderRadius.circular(8),
          child: Center(child: child),
        ),
      ),
    );
  }
}

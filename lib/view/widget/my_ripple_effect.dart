import 'package:autonect/constants/app_colors.dart';
import 'package:flutter/material.dart';

class MyRippleEffect extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? splashColor;
  final double? radius;
  const MyRippleEffect({
    super.key,
    required this.child,
    required this.onTap,
    this.splashColor,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: splashColor ?? kSecondaryColor,
        highlightColor: splashColor ?? kSecondaryColor,
        borderRadius: BorderRadius.circular(radius!),
        child: child,
      ),
    );
  }
}

import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:flutter/material.dart';

/// The app's real card: shadowed, radius 12, hairline border.
///
/// It supersedes the deleted `MyCard`, which had zero importers and was
/// BORDERED where every shipped screen is shadowed — keeping both would have
/// let two different cards appear on one page.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.s16),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: padding,
    decoration: AppStyling().myShadowStyle(),
    child: child,
  );
}

import 'package:flutter/material.dart';

/// MyText takes `size` and `weight` as separate arguments rather than a
/// TextStyle, so the type scale is exposed as raw doubles and weights instead
/// of assembled styles. Downstream partitions use these names, never literals.
class AppTextScale {
  const AppTextScale._();

  static const double display = 22;
  static const double title = 18;
  static const double subtitle = 16;
  static const double body = 14;
  static const double label = 12;
  static const double caption = 10;
}

class AppWeights {
  const AppWeights._();

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

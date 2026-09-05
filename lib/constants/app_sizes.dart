import 'package:flutter/material.dart';

class AppSizes {
  static const DEFAULT = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const HORIZONTAL = EdgeInsets.symmetric(horizontal: 20);
  static const VERTICAL = EdgeInsets.symmetric(vertical: 16);

  /// Spacing scale. Every gap, padding and margin in the funnel comes from
  /// here — a raw number in a widget is a review defect.
  static const double s4 = 4,
      s8 = 8,
      s12 = 12,
      s16 = 16,
      s20 = 20,
      s24 = 24,
      s32 = 32;

  /// Corner radii. radiusPill is deliberately larger than any control height so
  /// it always resolves to a true pill.
  static const double radiusSm = 8, radiusMd = 12, radiusLg = 20, radiusPill = 100;
}

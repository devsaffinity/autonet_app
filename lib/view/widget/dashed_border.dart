import 'package:flutter/material.dart';

/// A dashed rounded-rectangle border around [child].
///
/// Flutter's `BoxDecoration` has no dash support and there is no reason to add
/// a package for one border. Promoted out of the brand chips when the KYC
/// upload zones needed the same thing.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    required this.radius,
    this.color,
    this.strokeWidth = 1.2,
    this.dashLength = 5,
    this.gapLength = 4,
  });

  final Widget child;
  final double radius;

  /// Defaults to the theme's outline so callers that just want "a dashed box"
  /// do not each pick their own grey.
  final Color? color;

  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedBorderPainter(
      color: color ?? Theme.of(context).colorScheme.outline,
      radius: radius,
      strokeWidth: strokeWidth,
      dashLength: dashLength,
      gapLength: gapLength,
    ),
    child: child,
  );
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius, strokeWidth, dashLength, gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    // Walk the outline and extract alternating on/off segments. computeMetrics
    // handles the corner arcs, so the dashes stay evenly spaced around them
    // rather than bunching where the curve starts.
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

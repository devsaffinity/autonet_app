import 'package:autonect/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// A premium gold badge displayed for electricians / providers on the PRO tier.
class ProBadge extends StatelessWidget {
  const ProBadge({
    super.key,
    this.compact = false,
    this.showIcon = true,
  });

  /// Compact mode for tight spaces (e.g. inside small cards or inline beside names).
  final bool compact;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 1.5 : 3,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFFF8A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A00).withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.workspace_premium_rounded,
              size: compact ? 10 : 12,
              color: Colors.white,
            ),
            SizedBox(width: compact ? 2 : 3),
          ],
          Text(
            compact ? 'PRO' : 'PRO SPECIALIST',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

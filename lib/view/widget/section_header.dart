import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// A section title with an optional trailing action.
///
/// One widget instead of the per-screen copies: the buyer's was a bare `MyText`
/// with an `onTap` and no ripple, no minimum target and no underline — a 10px
/// tap strip on the busiest control on the landing screen.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'View All',
    this.onAction,
  });

  final String title;
  final String actionLabel;

  /// Null hides the action entirely. A visible 'View All' that does nothing is
  /// worse than a section without one.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.s12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Flexible so a long section title ellipsizes instead of shoving the
        // action off the edge at large text scales.
        Flexible(
          child: MyText(
            text: title,
            size: AppTextScale.subtitle,
            weight: AppWeights.bold,
            color: kBlackColor,
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
        ),
        if (onAction != null)
          Semantics(
            button: true,
            label: '$actionLabel $title',
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              // The label is 10-12px tall; the padding IS the touch target.
              // Vertical 12 + the text lands just over the 48dp floor, and the
              // negative-space padding keeps it visually flush with the title.
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s8,
                  vertical: AppSizes.s16,
                ),
                child: ExcludeSemantics(
                  child: MyText(
                    text: actionLabel,
                    size: AppTextScale.label,
                    color: kSecondaryColor,
                    weight: AppWeights.medium,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/view/widget/dashed_border.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The manufacturer-focus chips.
///
/// Selected chips are solid orange; unselected are white with a grey border;
/// the trailing "+ Add Brand" chip has a dashed orange border, as drawn.
class BrandChips extends StatelessWidget {
  const BrandChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onAdd,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSizes.s8,
    runSpacing: AppSizes.s8,
    children: [
      for (final b in options)
        _Chip(
          label: b,
          selected: selected.contains(b),
          onTap: () => onToggle(b),
        ),
      _AddChip(onTap: onAdd),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: Container(
        // 10 vertical + the ~14px label clears the 32dp minimum for a chip in
        // a wrap; the row itself is not the only target, each chip is.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? kSecondaryColor : kPrimaryColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(
            color: selected
                ? kSecondaryColor
                : kGreyTextColor.withValues(alpha: .4),
          ),
        ),
        child: ExcludeSemantics(
          child: MyText(
            text: label,
            size: AppTextScale.label,
            weight: selected ? AppWeights.semibold : AppWeights.regular,
            color: selected ? kWhiteColor : kBlackColor,
          ),
        ),
      ),
    ),
  );
}

/// Dashed border, drawn with a CustomPainter: Flutter's BoxDecoration has no
/// dash support and pulling a package in for one border is not worth it.
class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Add a brand',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: DashedBorder(
        radius: AppSizes.radiusPill,
        color: kSecondaryColor,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s12,
            vertical: 10,
          ),
          child: ExcludeSemantics(
            child: MyText(
              text: '+ Add Brand',
              size: AppTextScale.label,
              weight: AppWeights.medium,
              color: kSecondaryColor,
            ),
          ),
        ),
      ),
    ),
  );
}

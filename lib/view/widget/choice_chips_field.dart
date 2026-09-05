import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Single-select pill Wrap for a small, fully-visible option set — urgency,
/// condition, a delivery option — where a dropdown would hide the choices.
///
/// PROMOTED from SupplierChoiceChips and genericised over [SelectOption] so it
/// returns the wire value rather than the label it painted. That widget stays
/// where it is (multi-select, String-keyed) and is out of this phase's scope.
class ChoiceChipsField<T> extends StatelessWidget {
  const ChoiceChipsField({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<SelectOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.s8,
      runSpacing: AppSizes.s8,
      children: [
        for (final o in options)
          MyRippleEffect(
            radius: AppSizes.radiusPill,
            onTap: () => onSelect(o.value),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s16, vertical: AppSizes.s8),
              decoration: AppStyling().myDecoration(
                color: o.value == selected ? kLightOrangeColor : kPrimaryColor,
                borderColor:
                    o.value == selected ? kSecondaryColor : kTertiaryColor,
                thickness: 2,
                radius: AppSizes.radiusPill,
              ),
              child: MyText(
                text: o.label,
                size: AppTextScale.label,
                weight: AppWeights.semibold,
                color: o.value == selected ? kSecondaryColor : kBlackColor,
              ),
            ),
          ),
      ],
    );
  }
}

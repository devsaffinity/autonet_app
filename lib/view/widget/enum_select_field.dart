import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

/// Control heights copied verbatim from MyDropDown so the two pickers line up
/// when they share a form. Deliberately not in AppSizes: they are this
/// widget's private geometry, not a spacing scale anyone else consumes.
const double _buttonHeight = 50, _menuItemHeight = 40;

/// A dropdown that renders [SelectOption.label] and returns [SelectOption.value].
///
/// WHY IT EXISTS: MyDropDown is a `DropdownButton2<String>` whose value IS the
/// visible string, so it can only ever hand back the label. Every picker in
/// this funnel needs the wire value behind it — a category uuid, a
/// SCREAMING_SNAKE Region, a PartCondition — which that widget cannot carry.
class EnumSelectField<T> extends StatelessWidget {
  const EnumSelectField({
    super.key, required this.options, required this.value,
    required this.onChanged, this.title, this.hint = 'Select',
    this.errorText, this.bottomPadding = AppSizes.s16,
  });

  final List<SelectOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String? title, hint, errorText;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    // A value with no matching option would trip DropdownButton2's own
    // assertion; a stale selection degrades to the hint instead.
    final selected = options.any((o) => o.value == value) ? value : null;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            MyText(text: title!, size: AppTextScale.subtitle,
                weight: AppWeights.semibold, color: kBlackColor,
                paddingBottom: AppSizes.s4),
          DropdownButton2<T>(
            isExpanded: true,
            value: selected,
            hint: MyText(text: hint ?? 'Select', size: AppTextScale.body,
                color: kGreyTextColor),
            items: [
              for (final o in options)
                DropdownMenuItem<T>(
                  value: o.value,
                  child: MyText(text: o.label, size: AppTextScale.body,
                      color: kBlackColor),
                ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            underline: const SizedBox.shrink(),
            iconStyleData: const IconStyleData(
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: kGreyTextColor),
            ),
            dropdownStyleData: DropdownStyleData(
              decoration: BoxDecoration(
                color: kWhiteColor,
                border: Border.all(color: kBlackColor.withValues(alpha: .1)),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            buttonStyleData: ButtonStyleData(
              height: _buttonHeight,
              padding: const EdgeInsets.only(right: AppSizes.s12),
              decoration: BoxDecoration(
                color: kWhiteColor,
                border: Border.all(
                  color: errorText == null
                      ? kBlackColor.withValues(alpha: .5)
                      : kRedColor,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(height: _menuItemHeight),
          ),
          if (errorText != null)
            MyText(text: errorText!, size: AppTextScale.label, color: kRedColor,
                paddingTop: AppSizes.s4, paddingLeft: AppSizes.s8),
        ],
      ),
    );
  }
}

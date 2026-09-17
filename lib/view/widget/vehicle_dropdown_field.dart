import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/domain/vehicle_catalog.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/field_label.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

/// A styled vehicle specification dropdown with automatic support for an "Other" option.
///
/// When the user selects "Other", an inline [MyTextField] is displayed immediately
/// underneath the dropdown to allow custom specification entry.
class VehicleDropdownField extends StatelessWidget {
  const VehicleDropdownField({
    super.key,
    required this.title,
    required this.hint,
    required this.items,
    required this.selectedValue,
    required this.isOtherSelected,
    required this.onDropdownChanged,
    required this.customController,
    required this.customLabel,
    required this.customHint,
    this.onCustomChanged,
    this.isRequired = false,
    this.errorText,
    this.keyboardType,
    this.bottomPadding = AppSizes.s16,
    this.borderColor,
    this.titleSize,
  });

  final String title;
  final String hint;
  final List<String> items;
  final String? selectedValue;
  final bool isOtherSelected;
  final ValueChanged<String?> onDropdownChanged;
  final TextEditingController customController;
  final String customLabel;
  final String customHint;
  final ValueChanged<String>? onCustomChanged;
  final bool isRequired;
  final String? errorText;
  final TextInputType? keyboardType;
  final double bottomPadding;
  final Color? borderColor;
  final double? titleSize;

  @override
  Widget build(BuildContext context) {
    // Ensure "Other" is always present at the end of the items list
    final allItems = [
      for (final item in items)
        if (item != VehicleCatalog.otherOption) item,
      VehicleCatalog.otherOption,
    ];

    // Ensure selected value exists in the dropdown options; otherwise fall back to null
    final currentSelection =
        allItems.contains(selectedValue) ? selectedValue : null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(
            text: title,
            isRequired: isRequired,
            size: titleSize ?? AppTextScale.body,
            weight: AppWeights.semibold,
            color: kBlackColor,
            paddingBottom: AppSizes.s4,
          ),
          DropdownButton2<String>(
            isExpanded: true,
            value: currentSelection,
            hint: MyText(
              text: hint,
              size: AppTextScale.body,
              color: kGreyTextColor,
            ),
            items: [
              for (final item in allItems)
                DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      if (item == VehicleCatalog.otherOption) ...[
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: kSecondaryColor,
                        ),
                        const SizedBox(width: AppSizes.s8),
                      ],
                      Expanded(
                        child: MyText(
                          text: item,
                          size: AppTextScale.body,
                          color: item == VehicleCatalog.otherOption
                              ? kSecondaryColor
                              : kBlackColor,
                          weight: item == VehicleCatalog.otherOption
                              ? AppWeights.bold
                              : AppWeights.regular,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: onDropdownChanged,
            underline: const SizedBox.shrink(),
            iconStyleData: const IconStyleData(
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: kGreyTextColor,
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 280,
              decoration: BoxDecoration(
                color: kWhiteColor,
                border: Border.all(color: kBlackColor.withValues(alpha: .1)),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            buttonStyleData: ButtonStyleData(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
              decoration: BoxDecoration(
                color: kWhiteColor,
                border: Border.all(
                  color: errorText == null
                      ? (borderColor ?? kBlackColor.withValues(alpha: .3))
                      : kRedColor,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
          ),
          if (errorText != null && !isOtherSelected) ...[
            const SizedBox(height: AppSizes.s4),
            MyText(
              text: errorText!,
              size: AppTextScale.label,
              color: kRedColor,
              paddingLeft: AppSizes.s4,
            ),
          ],
          if (isOtherSelected) ...[
            const SizedBox(height: AppSizes.s8),
            MyTextField(
              controller: customController,
              labelText: customLabel,
              hintText: customHint,
              isRequired: isRequired,
              keyboardType: keyboardType,
              radius: AppSizes.radiusSm,
              errorText: errorText,
              onChanged: onCustomChanged,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_fonts.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class MyDropDown extends StatelessWidget {
  final Function(dynamic)? onChanged;
  final List<String> itemsList;
  final String? selectedValue, title, hint;
  final double bottomPadding;
  final Color? bkColor, borderColor;
  final FontWeight titleFontWeight;
  const MyDropDown({
    super.key,
    this.onChanged,
    required this.itemsList,
    this.selectedValue,
    this.title,
    this.bottomPadding = 16.0,
    this.hint = 'Select',
    this.bkColor,
    this.borderColor,
    this.titleFontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title != null
              ? MyText(
                  text: '$title',
                  size: 16,
                  weight: titleFontWeight,
                  paddingBottom: 6,
                  color: kBlackColor,
                )
              : SizedBox(),
          DropdownButton2<String>(
            isExpanded: true,
            hint: Text(
              hint.toString(),
              style: TextStyle(
                fontFamily: AppFonts.Cairo,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: kGreyTextColor,
              ),
            ),
            items: itemsList
                .map(
                  (String item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: kBlackColor,
                      ),
                    ),
                  ),
                )
                .toList(),
            value: selectedValue,
            onChanged: onChanged,
            iconStyleData: IconStyleData(
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: kGreyTextColor,
              ),
            ),

            // ----------- Drop Down Style --------------------
            dropdownStyleData: DropdownStyleData(
              decoration: BoxDecoration(
                border: Border.all(color: kBlackColor.withValues(alpha: .1)),
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(9),
              ),
            ),

            // ----------- Button Style --------------------
            underline: SizedBox(),
            buttonStyleData: ButtonStyleData(
              decoration: BoxDecoration(
                color: bkColor ?? kWhiteColor,
                border: Border.all(
                  color: borderColor ?? kBlackColor.withValues(alpha: .5),
                ),
                borderRadius: BorderRadius.all(Radius.circular(9)),
              ),
              padding: EdgeInsets.only(left: 0, right: 15),
              height: 50,
            ),

            menuItemStyleData: MenuItemStyleData(height: 40),
          ),
        ],
      ),
    );
  }
}

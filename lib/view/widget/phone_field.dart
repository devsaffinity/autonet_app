import 'package:autonect/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class MyPhoneField extends StatefulWidget {
  MyPhoneField({
    Key? key,
    this.labelText,
    this.hintText,
    this.onChanged,
    this.controller,
    this.marginBottom = 16,
    this.radius = 13,
    this.labelSize,
    this.validator,
  }) : super(key: key);

  final String? labelText;
  final String? hintText;
  // final Function(String completeNumber)? onChanged;
  final Function(PhoneNumber phone)? onChanged;
  final TextEditingController? controller;
  final double marginBottom;
  final double radius;
  final double? labelSize;
  final String? Function(String?)? validator;

  @override
  State<MyPhoneField> createState() => _MyPhoneFieldState();
}

class _MyPhoneFieldState extends State<MyPhoneField> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.marginBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.labelText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                widget.labelText ?? '',
                style: TextStyle(
                  fontSize: widget.labelSize ?? 14,
                  fontWeight: FontWeight.w600,
                  color: kWhiteColor,
                ),
              ),
            ),

          Focus(
            onFocusChange: (focus) {
              setState(() {
                isFocused = focus;
              });
            },
            child: IntlPhoneField(
              controller: widget.controller,
              initialCountryCode: 'DE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kSecondaryColor,
              ),
              dropdownTextStyle: TextStyle(
                fontSize: 14,
                color: kSecondaryColor,
              ),
              cursorColor: isFocused ? kSecondaryColor : kTertiaryColor,
              onChanged: (phone) {
                // widget.onChanged?.call(phone.completeNumber);
                widget.onChanged?.call(phone);
              },
              validator: (phone) {
                if (widget.validator != null) {
                  return widget.validator!(phone?.number);
                }
                return null;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: isFocused
                    ? kQuaternaryColor.withOpacity(0.2)
                    : kWhiteColor.withOpacity(0.05),
                hintText: widget.hintText ?? 'Enter phone number',
                hintStyle: TextStyle(fontSize: 14, color: kGreyTextColor),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(
                    color: isFocused
                        ? kQuaternaryColor
                        : kTertiaryColor.withValues(alpha: .5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(
                    color: isFocused
                        ? kQuaternaryColor
                        : kTertiaryColor.withValues(alpha: .5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(color: kQuaternaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

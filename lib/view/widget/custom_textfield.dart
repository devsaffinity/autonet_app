// ignore: must_be_immutable
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_fonts.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

class MyTextField extends StatefulWidget {
  MyTextField({
    Key? key,
    this.controller,
    this.keyboardType,
    this.hintText,
    this.labelText,
    this.onChanged,
    this.isObSecure = false,
    this.marginBottom = 16.0,
    this.maxLines = 1,
    this.radius = 100,
    this.labelSize,
    this.prefix,
    this.suffix,
    this.isReadOnly,
    this.onTap,
    this.validator,
  }) : super(key: key);

  TextInputType? keyboardType;
  String? labelText, hintText;
  TextEditingController? controller;
  ValueChanged<String>? onChanged;
  bool? isObSecure, isReadOnly;
  double? marginBottom;
  int? maxLines;
  double? labelSize;
  double? radius;
  Widget? prefix, suffix;
  final VoidCallback? onTap;
  String? Function(String?)? validator;

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.marginBottom!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.labelText != null)
            MyText(
              text: widget.labelText?.tr ?? '',
              size: widget.labelSize ?? 16,
              paddingBottom: 6,
              weight: FontWeight.w600,
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius!),
            child: Focus(
              onFocusChange: (focus) {
                setState(() {
                  isFocused = focus;
                });
              },
              child: TextFormField(
                textCapitalization: TextCapitalization.sentences,
                keyboardType: widget.keyboardType,
                onTap: widget.onTap,
                validator: widget.validator,
                textAlignVertical:
                    widget.prefix != null || widget.suffix != null
                    ? TextAlignVertical.center
                    : null,
                cursorColor: isFocused ? kSecondaryColor : kTertiaryColor,
                maxLines: widget.maxLines,
                readOnly: widget.isReadOnly ?? false,
                controller: widget.controller,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.next,
                obscureText: widget.isObSecure!,
                obscuringCharacter: '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isFocused ? kSecondaryColor : kBlackColor,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isFocused
                      ? kSecondaryColor.withOpacity(0.05)
                      : kWhiteColor,
                  prefixIcon: widget.prefix,
                  suffixIcon: widget.suffix,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: widget.maxLines! > 1 ? 15 : 0,
                  ),
                  hintText: widget.hintText?.tr,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: kGreyTextColor,
                    fontFamily: AppFonts.Cairo,
                  ),
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isFocused
                          ? kSecondaryColor
                          : kBlackColor.withValues(alpha: .3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isFocused
                          ? kSecondaryColor
                          : kBlackColor.withValues(alpha: .3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  errorBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// PASSWORD TEXT FIELD

class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    super.key,
    required this.isObSecure,
    required this.labelText,
    required this.onTap,
  });

  final bool isObSecure;
  final String labelText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MyTextField(
      // isObSecure: isObSecure,
      marginBottom: 10,
      labelText: labelText,
      hintText: "Must have at least 6 characters",
      suffix: MyRippleEffect(
        radius: 5,
        onTap: onTap,

        child: SizedBox(
          width: 50,
          child: Center(
            child: isObSecure
                ? Icon(Icons.remove_red_eye, color: kSecondaryColor)
                : Icon(Icons.remove_red_eye, color: kSecondaryColor),
            // : CommonImageView(height: 20, imagePath: Assets.imagesEyeIcon),
          ),
        ),
      ),
    );
  }
}

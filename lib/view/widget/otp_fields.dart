import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_fonts.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

/// SIX boxes, not four. The server's OTP.LENGTH is 6 (constants.ts:16) and the
/// DTO regex is /^\d{6}$/, so a 4-box field could never produce a code that
/// validates. Digits only, for the same reason.
///
/// This replaces 38 lines of commented-out `flutter_otp_text_field` code that
/// imported `package:love_stories`. pinput is already a pinned dependency.
class OtpFields extends StatelessWidget {
  const OtpFields({
    super.key,
    required this.controller,
    this.onCompleted,
    this.errorText,
    this.validator,
    this.autofocus = true,
  });

  final TextEditingController controller;

  /// Fired when the sixth digit lands. Screens use it to enable Verify, NOT to
  /// auto-submit: every /v1/auth route is rate-limited and a fat-fingered code
  /// firing on completion burns an attempt.
  final ValueChanged<String>? onCompleted;

  /// Server-side complaint (OTP_INVALID / OTP_EXPIRED), painted under the row.
  final String? errorText;
  final String? Function(String?)? validator;
  final bool autofocus;

  PinTheme get _base => PinTheme(
    width: 52,
    height: 56,
    textStyle: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: kBlackColor,
      fontFamily: AppFonts.Cairo,
    ),
    decoration: BoxDecoration(
      color: kWhiteColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBlackColor.withValues(alpha: .3)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pinput(
          length: 6,
          controller: controller,
          autofocus: autofocus,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: validator,
          onCompleted: onCompleted,
          // Suppressed: the message is drawn below by hand so it matches the
          // rest of the form's error styling.
          errorTextStyle: const TextStyle(height: 0, fontSize: 0),
          defaultPinTheme: _base,
          focusedPinTheme: _base.copyWith(
            decoration: _base.decoration!.copyWith(
              border: Border.all(color: kSecondaryColor, width: 1.5),
              color: kSecondaryColor.withValues(alpha: .05),
            ),
          ),
          submittedPinTheme: _base.copyWith(
            decoration: _base.decoration!.copyWith(
              border: Border.all(color: kSecondaryColor),
            ),
          ),
          errorPinTheme: _base.copyWith(
            decoration: _base.decoration!.copyWith(
              border: Border.all(color: kRedColor),
            ),
          ),
        ),
        if (errorText != null)
          MyText(
            text: errorText!,
            size: 12,
            weight: FontWeight.w400,
            color: kRedColor,
            paddingTop: 8,
            paddingLeft: 4,
          ),
      ],
    );
  }
}

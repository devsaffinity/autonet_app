// ignore: must_be_immutable
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_fonts.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.errorText,
    this.textCapitalization = TextCapitalization.sentences,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.borderColor,
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

  /// Rendered OUTSIDE the ClipRRect below. TextFormField's own error text is
  /// clipped away by the pill (borderRadius 100) and can never be read, so a
  /// server-side field error has to be drawn by hand.
  final String? errorText;

  /// Defaults to .sentences so no existing screen changes. EMAIL FIELDS MUST
  /// PASS .none: a soft keyboard capitalising the first letter against the
  /// server's z.email().toLowerCase() makes the OTP row lookup miss.
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// The unfocused outline. Null keeps the historical grey, so none of the
  /// twelve existing call sites move; a screen reconciled against the design
  /// passes [kFieldBorderColor]. The FOCUSED outline is deliberately NOT
  /// overridable — orange-on-focus is the app's focus signal, not a per-screen
  /// choice.
  final Color? borderColor;

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  bool isFocused = false;

  /// The validator's message, mirrored out so it can be painted below the
  /// ClipRRect instead of inside it (where the pill eats it).
  String? _validationError;

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
                textCapitalization: widget.textCapitalization,
                inputFormatters: widget.inputFormatters,
                keyboardType: widget.keyboardType,
                onTap: widget.onTap,
                validator: widget.validator == null
                    ? null
                    : (v) {
                        final m = widget.validator!(v);
                        // Mirror out of the clipped subtree. Deferred because
                        // validate() runs during a build.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _validationError != m) {
                            setState(() => _validationError = m);
                          }
                        });
                        // '' is still a failure to FormField (only null is
                        // valid) but leaves InputDecoration nothing to draw, so
                        // the message exists exactly once in the tree — below,
                        // outside the ClipRRect. Returning `m` here would emit
                        // it twice and have a screen reader say it twice.
                        return m == null ? null : '';
                      },
                textAlignVertical:
                    widget.prefix != null || widget.suffix != null
                    ? TextAlignVertical.center
                    : null,
                cursorColor: isFocused ? kSecondaryColor : kTertiaryColor,
                maxLines: widget.maxLines,
                readOnly: widget.isReadOnly ?? false,
                controller: widget.controller,
                onChanged: widget.onChanged,
                textInputAction: widget.textInputAction,
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
                          : (widget.borderColor ??
                                kBlackColor.withValues(alpha: .3)),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isFocused
                          ? kSecondaryColor
                          : (widget.borderColor ??
                                kBlackColor.withValues(alpha: .3)),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  // An invalid field turns its pill red rather than losing its
                  // outline entirely, which is what InputBorder.none did here.
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: kRedColor, width: 1),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: kRedColor, width: 1),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  // Collapse the built-in error slot: it lives inside the
                  // ClipRRect and the pill would only half-draw it.
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
              ),
            ),
          ),
          // OUTSIDE the clip. A server field error (errorText) outranks the
          // local validator message, because it is the more specific news.
          if ((widget.errorText ?? _validationError) != null)
            MyText(
              text: (widget.errorText ?? _validationError)!,
              size: 12,
              weight: FontWeight.w400,
              color: kRedColor,
              paddingTop: 6,
              paddingLeft: 16,
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
    this.controller,
    this.validator,
    this.onChanged,
    this.errorText,
    this.hintText,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
  });

  /// true means "currently revealed". The eye toggles it; the field below
  /// obscures on the inverse.
  final bool isObSecure;
  final String labelText;
  final VoidCallback onTap;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return MyTextField(
      // Was commented out, so the field never obscured and every password was
      // rendered in clear text.
      isObSecure: !isObSecure,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      errorText: errorText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      // A password is never a sentence.
      textCapitalization: TextCapitalization.none,
      marginBottom: 10,
      labelText: labelText,
      // Mirrors auth.dto.ts; the old "at least 6" understated the real rule.
      hintText: hintText ?? "8+ chars, with a capital and a number",
      suffix: MyRippleEffect(
        radius: 5,
        onTap: onTap,

        child: SizedBox(
          width: 50,
          child: Center(
            child: Icon(
              isObSecure ? Icons.visibility : Icons.visibility_off,
              color: kSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

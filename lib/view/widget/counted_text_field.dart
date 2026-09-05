import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// MyTextField plus a live 'n/max' counter and a hard length cap.
///
/// The cap is a formatter, not a validator, because every one of these limits
/// is enforced server-side (description 2000, partName 2..150, partNumber 80,
/// review text 1000, cancel note 500): letting the buyer type past it only
/// buys them a 400 after they press submit. Counting is `String.length`
/// (UTF-16 units) to match both the formatter and the backend's zod `.max()`.
class CountedTextField extends StatefulWidget {
  const CountedTextField({
    super.key, required this.controller, required this.maxLength,
    this.labelText, this.hintText, this.errorText, this.maxLines = 1,
    this.onChanged, this.textCapitalization = TextCapitalization.sentences,
    this.marginBottom = AppSizes.s16,
  });

  final TextEditingController controller;
  final int maxLength, maxLines;
  final String? labelText, hintText, errorText;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final double marginBottom;

  @override
  State<CountedTextField> createState() => _CountedTextFieldState();
}

class _CountedTextFieldState extends State<CountedTextField> {
  /// The controller, not onChanged: a programmatic `controller.text = ...`
  /// (draft restore) fires no onChanged and would leave the counter lying.
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final used = widget.controller.text.length;
    final multiline = widget.maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MyTextField(
          controller: widget.controller, labelText: widget.labelText,
          hintText: widget.hintText, errorText: widget.errorText,
          maxLines: widget.maxLines, onChanged: widget.onChanged,
          textCapitalization: widget.textCapitalization,
          textInputAction:
              multiline ? TextInputAction.newline : TextInputAction.next,
          // Never null: MyTextField force-unwraps radius. radiusPill == its default.
          radius: multiline ? AppSizes.radiusMd : AppSizes.radiusPill,
          marginBottom: AppSizes.s4,
          inputFormatters: [LengthLimitingTextInputFormatter(widget.maxLength)],
        ),
        MyText(
          text: '$used/${widget.maxLength}', size: AppTextScale.caption,
          color: used >= widget.maxLength ? kRedColor : kGreyTextColor,
          paddingRight: AppSizes.s8, paddingBottom: widget.marginBottom,
        ),
      ],
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The share of the cap a field may reach before [CountedTextField.quietCounter]
/// stops suppressing the counter. 0.9 of 150 is 135, of 80 is 72, of 2000 is
/// 1800 — always far enough out to be a warning rather than a surprise.
const double _kCounterRevealFraction = 0.9;

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
    this.marginBottom = AppSizes.s16, this.radius, this.borderColor,
    this.labelSize, this.quietCounter = false, this.isRequired = false,
  });

  final TextEditingController controller;
  final int maxLength, maxLines;
  final String? labelText, hintText, errorText;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final double marginBottom;

  /// Null keeps the historical shape — a pill for one line, [AppSizes.radiusMd]
  /// for many. A screen reconciled against the design passes an explicit radius.
  final double? radius;

  /// Forwarded to [MyTextField.borderColor]; null keeps the historical grey.
  final Color? borderColor;

  /// Forwarded to [MyTextField.labelSize]; null keeps that widget's own 16.
  final double? labelSize;

  /// Forwarded to [MyTextField.isRequired] — draws the label's asterisk.
  final bool isRequired;

  /// Suppress the counter until the text is within [_kCounterRevealFraction] of
  /// the cap.
  ///
  /// The counter is not decoration — it is the only thing that explains why
  /// typing stopped — so this hides it, never removes it, and the formatter
  /// that does the capping is untouched either way. Off by default: the three
  /// call sites outside the request wizard show their counter from the first
  /// character and none of them has been reconciled against a comp.
  final bool quietCounter;

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
    final showCounter = !widget.quietCounter ||
        used >= widget.maxLength * _kCounterRevealFraction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MyTextField(
          controller: widget.controller, labelText: widget.labelText,
          hintText: widget.hintText, errorText: widget.errorText,
          maxLines: widget.maxLines, onChanged: widget.onChanged,
          textCapitalization: widget.textCapitalization,
          labelSize: widget.labelSize, isRequired: widget.isRequired,
          textInputAction:
              multiline ? TextInputAction.newline : TextInputAction.next,
          // Never null: MyTextField force-unwraps radius. radiusPill == its default.
          radius: widget.radius ??
              (multiline ? AppSizes.radiusMd : AppSizes.radiusPill),
          borderColor: widget.borderColor,
          marginBottom: AppSizes.s4,
          inputFormatters: [LengthLimitingTextInputFormatter(widget.maxLength)],
        ),
        // The hidden branch reserves the field's normal bottom margin but NOT
        // the counter's own line, so crossing the reveal threshold does grow
        // this column by one caption row. That is a single reflow at 90% of a
        // cap, at the moment the buyer most needs their eye drawn there;
        // reserving the row permanently would cost every field a dead 14px the
        // design does not have.
        if (showCounter)
          MyText(
            text: '$used/${widget.maxLength}', size: AppTextScale.caption,
            color: used >= widget.maxLength ? kRedColor : kGreyTextColor,
            paddingRight: AppSizes.s8, paddingBottom: widget.marginBottom,
          )
        else
          SizedBox(height: widget.marginBottom),
      ],
    );
  }
}

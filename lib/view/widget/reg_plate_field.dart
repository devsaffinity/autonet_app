import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Normalises a UK registration to the shape the lookup expects, on EVERY
/// keystroke.
///
/// TextCapitalization.characters is a soft-keyboard HINT only: it is defeated
/// by a paste, by a hardware keyboard and by most third-party keyboards, so
/// 'ab 12 cde' would reach `POST /v1/vehicles/lookup` verbatim and 404.
class _RegPlateFormatter extends TextInputFormatter {
  const _RegPlateFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.toUpperCase().replaceAll(RegExp(r'\s'), '');
    if (cleaned == newValue.text) return newValue;
    // Rebase the caret onto the stripped string: the number of surviving
    // characters before it, not its old index.
    final head = newValue.selection.baseOffset;
    final cursor = head < 0
        ? cleaned.length
        : newValue.text.substring(0, head).replaceAll(RegExp(r'\s'), '').length;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cursor.clamp(0, cleaned.length)),
    );
  }
}

class RegPlateField extends StatelessWidget {
  const RegPlateField({
    super.key,
    required this.controller,
    this.labelText = 'Registration number',
    this.hintText = 'AB12 CDE',
    this.errorText,
    this.onChanged,
    this.marginBottom = AppSizes.s16,
  });

  final TextEditingController controller;
  final String? labelText, hintText, errorText;
  final ValueChanged<String>? onChanged;
  final double marginBottom;

  @override
  Widget build(BuildContext context) => MyTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    errorText: errorText,
    onChanged: onChanged,
    marginBottom: marginBottom,
    textCapitalization: TextCapitalization.characters,
    textInputAction: TextInputAction.done,
    inputFormatters: const [_RegPlateFormatter()],
  );
}

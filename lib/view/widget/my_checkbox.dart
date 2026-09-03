import 'package:autonect/constants/app_colors.dart';
import 'package:flutter/material.dart';

class MyCheckBox extends StatelessWidget {
  final bool isChecked;
  final Function(bool?)? onChanged;
  final Color kborderColor;
  final bool haveCheckBoxTrue = false;

  MyCheckBox({
    super.key,
    this.isChecked = false,
    required this.onChanged,
    this.kborderColor = kTertiaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: Checkbox(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        side: BorderSide(
          color: (isChecked == true)
              ? kSecondaryColor
              : const Color.fromARGB(255, 209, 210, 211),
        ),
        checkColor: Colors.white,
        activeColor: Colors.red,
        focusColor: Colors.amber,
        fillColor: MaterialStatePropertyAll(
          (isChecked == true) ? kSecondaryColor : kPrimaryColor,
        ),
        value: isChecked,
        onChanged: onChanged,
      ),
    );
  }
}

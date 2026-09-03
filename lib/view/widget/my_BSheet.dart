import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:flutter/material.dart';

class MyBSheet extends StatelessWidget {
  final Widget body;
  final double? horizontalPadding;
  final VoidCallback? onTap;
  final String? btnText;
  const MyBSheet({
    super.key,
    required this.body,
    this.horizontalPadding,
    this.btnText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 150),
      decoration: AppStyling().bottomSheetStyle(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding ?? 20,
          vertical: 17,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(bottom: 18),
                height: 5,
                width: 68,
                decoration: AppStyling().myDecoration(
                  radius: 100,
                  color: kBlackColor.withValues(alpha: 0.1),
                  borderColor: kTransperentColor,
                ),
              ),
            ),
            body,
            SizedBox(height: 10),
            MyButton(onTap: onTap, buttonText: btnText ?? "Assign Penalty"),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

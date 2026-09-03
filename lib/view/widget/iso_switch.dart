import 'package:autonect/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

class IosSwitch extends StatelessWidget {
  final Function(dynamic)? onChange;
  final bool value;
  final Color activeColor, inActiveColor;
  const IosSwitch({
    super.key,
    this.onChange,
    this.value = true,
    this.activeColor = kSecondaryColor,
    this.inActiveColor = kGreyTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45, // CupertinoSwitch default width (51) * 0.6
      height: 27, // CupertinoSwitch default height (31) * 0.6
      child: FittedBox(
        fit: BoxFit.fill,
        child: CupertinoSwitch(
          activeColor: activeColor,
          thumbColor: kWhiteColor,
          value: value,
          onChanged: onChange,
        ),
      ),
    );
  }
}

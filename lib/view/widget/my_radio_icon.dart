import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:flutter/material.dart';

class MyRadioIcon extends StatelessWidget {
  final bool isSelected;
  const MyRadioIcon({super.key, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2),
      height: 20,
      width: 20,
      decoration: AppStyling().myDecoration(
        color: kTransperentColor,
        radius: 100,
        borderColor: isSelected ? kSecondaryColor : kTertiaryColor,
      ),
      child: Container(
        decoration: AppStyling().myDecoration(
          radius: 100,
          color: isSelected ? kSecondaryColor : kTransperentColor,
          borderColor: isSelected ? kSecondaryColor : kTransperentColor,
        ),
      ),
    );
  }
}

class MyDoneIcon extends StatelessWidget {
  final bool isSelected;
  const MyDoneIcon({super.key, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isSelected ? null : EdgeInsets.all(2),
      height: 25,
      width: 25,
      decoration: AppStyling().myDecoration(
        color: kTransperentColor,
        radius: 100,
        borderColor: isSelected ? kTransperentColor : kTertiaryColor,
      ),
      // child: isSelected
      //     ? CommonImageView(imagePath: Assets.imagesGradientDone)
      //     : SizedBox.shrink(),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Lifted out of electrician/home/booking_requests.dart so there is ONE pill
/// tab bar in the app, not a copy per screen. kLightBlueColor track, white
/// AnimatedContainer thumb, 220ms easeInOut — the original values.
class MyPillTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  const MyPillTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: kLightBlueColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = selectedIndex == i;
          return Expanded(
            child: MyRippleEffect(
              onTap: () => onChanged(i),
              radius: 100,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? kWhiteColor : kTransperentColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: MyText(
                  text: labels[i],
                  size: 14,
                  weight: FontWeight.w600,
                  color: isSelected ? kSecondaryColor : kBlackColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Muted label over a black value — the vehicle, part and delivery blocks on
/// every detail screen in the funnel.
class DetailItem extends StatelessWidget {
  const DetailItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.s12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(text: label, size: AppTextScale.label, color: kGreyTextColor),
        MyText(text: value, size: AppTextScale.body,
            weight: AppWeights.semibold, color: kBlackColor,
            paddingTop: AppSizes.s4),
      ],
    ),
  );
}

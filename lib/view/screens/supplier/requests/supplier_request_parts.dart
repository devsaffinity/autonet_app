import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The tinted vehicle header ComparisonPage draws for the buyer, reused so the
/// supplier's view of a request is visibly the same object.
class SupplierVehicleHero extends StatelessWidget {
  final String title;
  const SupplierVehicleHero({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
      width: double.infinity,
      height: 250,
      decoration: AppStyling().allFourSideRaius(
        color: const Color(0xffFCECEA),
        topLeft: 0,
        topRight: 0,
        bottomLeft: 30,
        bottomRight: 30,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              MyRippleEffect(
                onTap: () => Get.back(),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: kBlackColor,
                ),
              ),
              const SizedBox(width: 10),
              MyText(
                text: title,
                size: 16,
                weight: FontWeight.w600,
                color: kBlackColor,
              ),
            ],
          ),
          CommonImageView(
            imagePath: Assets.imagesCar1,
            width: 300,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

/// icon + label + value, the buyer's `_SummaryRow` from new_part_request.dart.
class SupplierSummaryRow extends StatelessWidget {
  final String icon, label, value;
  const SupplierSummaryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonImageView(width: 50, height: 50, imagePath: icon),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(text: label, size: 16, weight: FontWeight.w600),
            MyText(
              text: value,
              size: 14,
              weight: FontWeight.w400,
              color: kGreyTextColor,
            ),
          ],
        ),
      ],
    );
  }
}

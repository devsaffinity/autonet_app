import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Avatar + greeting + ACCEPTING LEADS / PAUSED toggle. The supplier twin of
/// the electrician home's ONLINE / OFFLINE header row.
class SupplierHomeTopBar extends StatefulWidget {
  const SupplierHomeTopBar({super.key});

  @override
  State<SupplierHomeTopBar> createState() => _SupplierHomeTopBarState();
}

class _SupplierHomeTopBarState extends State<SupplierHomeTopBar> {
  bool _accepting = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(.3),
          decoration: AppStyling().myDecoration(
            color: kSecondaryColor,
            borderColor: kSecondaryColor,
            radius: 100,
          ),
          child: ClipOval(
            child: CommonImageView(
              imagePath: Assets.imagesProfileImage,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Good morning,',
                size: 14,
                weight: FontWeight.w400,
                color: kGreyTextColor,
              ),
              MyText(
                text: 'AutoParts Hub',
                size: 16,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
            ],
          ),
        ),
        MyRippleEffect(
          onTap: () => setState(() => _accepting = !_accepting),
          radius: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: AppStyling().myDecoration(
              color: kSecondaryColor.withValues(alpha: .1),
              radius: 100,
              borderColor: kTransperentColor,
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accepting ? const Color(0xff34C759) : kGreyTextColor,
                  ),
                ),
                const SizedBox(width: 5),
                MyText(
                  text: _accepting ? 'ACCEPTING LEADS' : 'PAUSED',
                  size: 12,
                  weight: FontWeight.w600,
                  color: kBlackColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

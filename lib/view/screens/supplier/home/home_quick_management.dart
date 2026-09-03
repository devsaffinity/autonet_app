import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/supplier/dash_board/supplier_credits.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_orders.dart';
import 'package:autonect/view/screens/supplier/profile/profile.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The Quick Management Wrap, re-pointed at the supplier dashboards.
class SupplierQuickManagement extends StatelessWidget {
  const SupplierQuickManagement({super.key});

  static const List<Map<String, String>> _actions = [
    {'label': 'Manage Orders', 'icon': Assets.imagesQmA},
    {'label': 'Buy Credits', 'icon': Assets.imagesQmB},
    {'label': 'Business Profile', 'icon': Assets.imagesQmC},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_actions.length, (i) {
        final action = _actions[i];
        return MyRippleEffect(
          radius: 12,
          onTap: () {
            switch (i) {
              case 0:
                Get.to(() => const SupplierOrdersPage());
                break;
              case 1:
                Get.to(() => const SupplierCreditsPage());
                break;
              case 2:
                Get.to(() => const SupplierProfilePage());
                break;
            }
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 32 - 12) / 2,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: AppStyling().myShadowDecoration(
              color: kPrimaryColor,
              radius: 12,
              borderColor: kTransperentColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonImageView(svgPath: action['icon']),
                const SizedBox(height: 10),
                MyText(
                  text: action['label']!,
                  size: 12,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

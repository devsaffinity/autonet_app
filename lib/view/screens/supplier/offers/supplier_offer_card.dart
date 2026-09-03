import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_create_offer.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_order_detail.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_offer_sheets.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One row of the supplier's own offers, tab-aware. This is the seller-side
/// twin of the buyer's `_OfferCard` in buyer/detail/comparison.dart.
class SupplierOfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final int statusIndex; // 0 Pending, 1 Accepted, 2 Rejected
  final VoidCallback onWithdraw;
  const SupplierOfferCard({
    super.key,
    required this.offer,
    required this.statusIndex,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SupplierCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CommonImageView(
                  imagePath: Assets.imagesProfileImage,
                  height: 24,
                  width: 24,
                  radius: 16,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MyText(
                    text: offer['buyer'] as String,
                    size: 16,
                    weight: FontWeight.w600,
                    color: kSecondaryColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ),
                SupplierStatusBadge(
                  label: offer['status'] as String,
                  color: statusIndex == 1
                      ? const Color(0xff34C759)
                      : statusIndex == 2
                      ? kRedColor
                      : kSecondaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CommonImageView(svgPath: Assets.imagesCpA),
                const SizedBox(width: 4),
                MyText(
                  text: offer['price'] as String,
                  size: 14,
                  weight: FontWeight.w400,
                  color: kBlackColor,
                ),
                const Spacer(),
                CommonImageView(svgPath: Assets.imagesCpD),
                const SizedBox(width: 4),
                MyText(
                  text: offer['delivery'] as String,
                  size: 14,
                  weight: FontWeight.w400,
                  color: kBlackColor,
                ),
              ],
            ),
            MyText(
              paddingTop: 6,
              text: offer['vehicle'] as String,
              size: 12,
              weight: FontWeight.w500,
              color: kGreyTextColor,
            ),
            const SizedBox(height: 12),
            if (statusIndex == 0) _buildPendingActions(),
            if (statusIndex == 1)
              MyButton(
                buttonText: 'View Order',
                height: 36,
                fontSize: 12,
                radius: 9,
                onTap: () => Get.to(() => const SupplierOrderDetailPage()),
              ),
            if (statusIndex == 2)
              MyText(
                text: 'The buyer chose another supplier on this request.',
                size: 12,
                weight: FontWeight.w400,
                color: kGreyTextColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingActions() {
    return Row(
      children: [
        Expanded(
          child: MyButton(
            buttonText: 'Edit Offer',
            height: 36,
            fontSize: 12,
            radius: 9,
            haveSvg: true,
            icon: Assets.imagesMsEdit,
            iconSize: 16,
            backgroundColor: kPrimaryColor,
            outlineColor: kSecondaryColor,
            fontColor: kSecondaryColor,
            onTap: () =>
                Get.to(() => SupplierCreateOfferPage(existingOffer: offer)),
          ),
        ),
        const SizedBox(width: 10),
        MyRippleEffect(
          radius: 9,
          onTap: () => Get.bottomSheet(
            WithdrawOfferBSheet(onConfirm: onWithdraw),
            isScrollControlled: true,
          ),
          child: Container(
            height: 36,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kRedColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: CommonImageView(
              svgPath: Assets.imagesDeleteOferIcon,
              width: 18,
              height: 18,
            ),
          ),
        ),
      ],
    );
  }
}

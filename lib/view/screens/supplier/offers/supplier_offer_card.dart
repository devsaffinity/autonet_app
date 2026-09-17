import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_create_offer.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_offer_sheets.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_orders.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupplierOfferCard extends StatelessWidget {
  final SupplierOffer offer;
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
    final title = offer.request?.partName ?? 'Part Quote';
    final priceStr = '£${(offer.pricePence / 100).toStringAsFixed(2)}';
    final deliveryStr =
        '${offer.deliveryOption?.label ?? 'Delivery'} (${offer.deliveryTimeDays ?? 2}d)';
    final regionStr =
        offer.request?.region != null ? ' - ${offer.request!.region!.label}' : '';
    final statusLabel = switch (statusIndex) {
      1 => 'Accepted',
      2 => 'Rejected',
      _ => 'Pending',
    };

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
                    text: title,
                    size: 16,
                    weight: FontWeight.w600,
                    color: kSecondaryColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ),
                SupplierStatusBadge(
                  label: statusLabel,
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
                  text: priceStr,
                  size: 14,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                const Spacer(),
                CommonImageView(svgPath: Assets.imagesCpD),
                const SizedBox(width: 4),
                MyText(
                  text: deliveryStr,
                  size: 14,
                  weight: FontWeight.w400,
                  color: kBlackColor,
                ),
              ],
            ),
            MyText(
              paddingTop: 6,
              text:
                  '${offer.condition?.label ?? 'Condition unspecified'}${offer.warrantyMonths != null ? ' • ${offer.warrantyMonths}m warranty' : ''}$regionStr',
              size: 12,
              weight: FontWeight.w500,
              color: kGreyTextColor,
            ),
            const SizedBox(height: 12),
            if (statusIndex == 0) _buildPendingActions(),
            if (statusIndex == 1)
              Row(
                children: [
                  Expanded(
                    child: MyButton(
                      buttonText: 'View Orders',
                      height: 36,
                      fontSize: 12,
                      radius: 9,
                      onTap: () => Get.to(() => const SupplierOrdersPage()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MyRippleEffect(
                    radius: 9,
                    onTap: () => Get.to(
                      () => ChatRoomPage(
                        contextId: offer.id,
                        type: ConversationType.offer,
                        title: offer.request?.partName ?? 'Chat with Buyer',
                      ),
                    ),
                    child: Container(
                      height: 36,
                      width: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kSecondaryColor.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: kSecondaryColor,
                      ),
                    ),
                  ),
                ],
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
            onTap: () => Get.to(
              () => SupplierCreateOfferPage(existingOffer: offer),
            ),
          ),
        ),
        const SizedBox(width: 8),
        MyRippleEffect(
          radius: 9,
          onTap: () => Get.to(
            () => ChatRoomPage(
              contextId: offer.id,
              type: ConversationType.offer,
              title: offer.request?.partName ?? 'Chat with Buyer',
            ),
          ),
          child: Container(
            height: 36,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kSecondaryColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 18,
              color: kSecondaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
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

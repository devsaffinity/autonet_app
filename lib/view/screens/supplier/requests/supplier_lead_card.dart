import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_request_detail.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum LeadState { locked, unlocked, offered }

class SupplierLeadCard extends StatelessWidget {
  final SupplierLead lead;
  final VoidCallback? onUnlock;

  const SupplierLeadCard({
    super.key,
    required this.lead,
    this.onUnlock,
  });

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = !lead.isUnlocked;
    final brand = lead.vehicleMake ?? 'VEHICLE';
    final vehicleModel = [
      if (lead.vehicleMake != null) lead.vehicleMake,
      if (lead.vehicleYear != null) '${lead.vehicleYear}',
    ].join(' ');
    final title = vehicleModel.isNotEmpty ? vehicleModel : lead.partName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SupplierCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MyText(
                  text: brand.toUpperCase(),
                  size: 11,
                  color: kGreyTextColor,
                  weight: FontWeight.w700,
                ),
                const Spacer(),
                MyText(
                  text: _timeAgo(lead.createdAt),
                  size: 12,
                  color: kGreyTextColor,
                  weight: FontWeight.w500,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        paddingTop: 2,
                        text: title,
                        size: 14,
                        weight: FontWeight.w700,
                        color: kBlackColor,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                      MyText(
                        paddingTop: 4,
                        text: lead.partName,
                        size: 13,
                        weight: FontWeight.w600,
                        color: kSecondaryColor,
                      ),
                      MyText(
                        paddingTop: 4,
                        text: isLocked
                            ? 'Reg  ••• •••'
                            : 'Reg  Unlocked',
                        size: 12,
                        weight: FontWeight.w500,
                        color: isLocked ? kGreyTextColor : kBlackColor,
                      ),
                      MyText(
                        paddingTop: 2,
                        text: isLocked
                            ? 'Buyer hidden until unlocked'
                            : 'Buyer details unlocked',
                        size: 12,
                        weight: FontWeight.w500,
                        color: isLocked ? kGreyTextColor : kBlackColor,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (lead.category != null)
                            SupplierStatusBadge(
                              label: lead.category!.name,
                              color: kQuaternaryColor,
                            ),
                          if (lead.region != null)
                            SupplierStatusBadge(label: lead.region!.label),
                          if (lead.urgency != null)
                            SupplierStatusBadge(
                              label: lead.urgency!.label,
                              color: lead.urgency!.label.toLowerCase() == 'urgent'
                                  ? kRedColor
                                  : kSecondaryColor,
                            ),
                          if (lead.offerCount > 0)
                            SupplierStatusBadge(
                              label: '${lead.offerCount} offers',
                              color: kTertiaryColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                CommonImageView(
                  imagePath: Assets.imagesCar1,
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLocked)
              MyButton(
                buttonText: 'Unlock Request',
                height: 34,
                fontSize: 12,
                radius: 9,
                onTap: () {
                  final isSubscribed = Get.isRegistered<SupplierHomeController>()
                      ? SupplierHomeController.ensure().isSubscribed
                      : false;
                  Get.bottomSheet(
                    UnlockLeadBSheet(
                      isSubscribed: isSubscribed,
                      onConfirm: () {
                        onUnlock?.call();
                        Get.to(() => SupplierRequestDetailPage(requestId: lead.id));
                      },
                    ),
                    isScrollControlled: true,
                  );
                },
              )
            else
              MyButton(
                buttonText: 'View Request',
                height: 34,
                fontSize: 12,
                radius: 9,
                backgroundColor: kPrimaryColor,
                outlineColor: kSecondaryColor,
                fontColor: kSecondaryColor,
                onTap: () => Get.to(
                  () => SupplierRequestDetailPage(requestId: lead.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Spend-credits confirmation, dynamic based on Pro subscription status.
class UnlockLeadBSheet extends StatelessWidget {
  final bool isSubscribed;
  final VoidCallback onConfirm;
  const UnlockLeadBSheet({
    super.key,
    required this.onConfirm,
    this.isSubscribed = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnText = isSubscribed ? 'Unlock (Included in Pro)' : 'Spend 1 credit';
    final descText = isSubscribed
        ? 'As a Pro subscriber, request unlocking is included in your plan at no extra charge. Unlocking reveals registration plate, photos, and buyer contact.'
        : 'Unlocking reveals the vehicle registration plate, photos, and buyer contact so you can send an offer. 1 credit will be deducted from your balance.';

    return MyBSheet(
      btnText: btnText,
      onTap: () {
        Get.back();
        onConfirm();
      },
      body: Column(
        children: [
          CommonImageView(width: 150, imagePath: Assets.imagesRequestPartIcon),
          MyText(
            textAlign: TextAlign.center,
            paddingBottom: 16,
            paddingTop: 24,
            text: 'Unlock this request?',
            size: 20,
            weight: FontWeight.w700,
          ),
          MyText(
            paddingBottom: 24,
            textAlign: TextAlign.center,
            text: descText,
            size: 15,
            weight: FontWeight.w400,
            color: kGreyTextColor,
          ),
        ],
      ),
    );
  }
}

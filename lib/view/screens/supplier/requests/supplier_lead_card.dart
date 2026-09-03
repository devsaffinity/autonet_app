import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_request_detail.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The three states a lead can be in for a supplier, driven by the backend's
/// RequestView credit model:
///   locked   — the buyer's registration plate and contact are masked
///   unlocked — credits already spent, full detail readable
///   offered  — this supplier already has an Offer on the request
enum LeadState { locked, unlocked, offered }

/// One buyer part request as the supplier sees it. Mirrors the buyer's request
/// card in request_status_tracking.dart so both sides read as one app.
class SupplierLeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  final VoidCallback onUnlock;
  const SupplierLeadCard({
    super.key,
    required this.lead,
    required this.onUnlock,
  });

  LeadState get _state => lead['state'] as LeadState;

  @override
  Widget build(BuildContext context) {
    final isLocked = _state == LeadState.locked;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SupplierCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MyText(
                  text: lead['brand'] as String,
                  size: 11,
                  color: kGreyTextColor,
                  weight: FontWeight.w700,
                ),
                const Spacer(),
                if (_state == LeadState.offered)
                  const SupplierStatusBadge(label: 'Offer sent')
                else
                  MyText(
                    text: lead['posted'] as String,
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
                        text: lead['model'] as String,
                        size: 14,
                        weight: FontWeight.w700,
                        color: kBlackColor,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                      MyText(
                        paddingTop: 6,
                        text: isLocked
                            ? 'Reg  ••• •••'
                            : 'Reg  ${lead['plate']}',
                        size: 12,
                        weight: FontWeight.w500,
                        color: isLocked ? kGreyTextColor : kBlackColor,
                      ),
                      MyText(
                        paddingTop: 4,
                        text: isLocked
                            ? 'Buyer hidden until unlocked'
                            : lead['buyer'] as String,
                        size: 12,
                        weight: FontWeight.w500,
                        color: isLocked ? kGreyTextColor : kBlackColor,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          SupplierStatusBadge(
                            label: lead['category'] as String,
                            color: kQuaternaryColor,
                          ),
                          SupplierStatusBadge(label: lead['region'] as String),
                          SupplierStatusBadge(
                            label: lead['urgency'] as String,
                            color: kRedColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                CommonImageView(
                  imagePath: Assets.imagesCar1,
                  width: 110,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLocked)
              MyButton(
                buttonText: 'Unlock for 2 credits',
                height: 34,
                fontSize: 12,
                radius: 9,
                onTap: () => Get.bottomSheet(
                  UnlockLeadBSheet(onConfirm: onUnlock),
                  isScrollControlled: true,
                ),
              )
            else
              MyButton(
                buttonText: _state == LeadState.offered
                    ? 'View my offer'
                    : 'View request',
                height: 34,
                fontSize: 12,
                radius: 9,
                backgroundColor: kPrimaryColor,
                outlineColor: kSecondaryColor,
                fontColor: kSecondaryColor,
                onTap: () => Get.to(() => const SupplierRequestDetailPage()),
              ),
          ],
        ),
      ),
    );
  }
}

/// Spend-credits confirmation, modelled on RequestSendBSheet.
class UnlockLeadBSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  const UnlockLeadBSheet({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return MyBSheet(
      btnText: 'Spend 2 credits',
      onTap: () {
        Get.back();
        onConfirm();
      },
      body: Column(
        children: [
          CommonImageView(width: 150, imagePath: Assets.imagesRequestPartIcon),
          MyText(
            textAlign: TextAlign.center,
            paddingBottom: 20,
            paddingTop: 24,
            text: 'Unlock this request?',
            size: 20,
            weight: FontWeight.w700,
          ),
          MyText(
            paddingBottom: 24,
            textAlign: TextAlign.center,
            text:
                'Unlocking reveals the registration plate and the buyer contact so you can send an offer. 2 credits will be deducted from your balance.',
            size: 16,
            weight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}

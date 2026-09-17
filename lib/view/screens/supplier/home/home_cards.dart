import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// kSecondaryColor hero card displaying real-time matching leads and active negotiations.
class SupplierPerformanceCard extends StatelessWidget {
  const SupplierPerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SupplierHomeController.ensure();

    return Obx(() {
      final incoming = controller.incomingRequests;
      final active = controller.activeNegotiations;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: AppStyling().myDecoration(
          color: kSecondaryColor,
          borderColor: kTransperentColor,
          radius: 12,
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              right: -10,
              top: -4,
              child: Icon(
                Icons.inventory_2_outlined,
                size: 90,
                color: kWhiteColor.withValues(alpha: 0.1),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: "Incoming Leads",
                  size: 12,
                  weight: FontWeight.w600,
                  color: kWhiteColor.withValues(alpha: 0.8),
                  paddingBottom: 6,
                ),
                MyText(
                  text: incoming == 1 ? '1 New Request' : '$incoming New Requests',
                  size: 24,
                  weight: FontWeight.w700,
                  color: kWhiteColor,
                  paddingBottom: 8,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: kWhiteColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    MyText(
                      text: active == 1
                          ? '1 active negotiation'
                          : '$active active negotiations',
                      size: 14,
                      weight: FontWeight.w500,
                      color: kWhiteColor.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// Credit Balance card showing real balance and Pro status.
class SupplierCreditCard extends StatelessWidget {
  const SupplierCreditCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SupplierHomeController.ensure();

    return Obx(() {
      final isSubscribed = controller.isSubscribed;
      final balance = controller.creditBalance;
      final progress = isSubscribed ? 1.0 : (balance / 100).clamp(0.0, 1.0);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: AppStyling().myShadowDecoration(
          color: kWhiteColor,
          radius: 16,
          borderColor: kTransperentColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(
                  text: isSubscribed ? 'Plan Status' : 'Credit Balance',
                  size: 12,
                  weight: FontWeight.w500,
                  color: kGreyTextColor,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kLightOrangeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: kSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            MyText(
              text: isSubscribed ? 'Pro Unlimited' : '$balance credits',
              size: 28,
              weight: FontWeight.w800,
              color: kBlackColor,
              paddingBottom: 12,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: kTertiaryColor,
                valueColor: const AlwaysStoppedAnimation<Color>(kSecondaryColor),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: MyText(
                text: isSubscribed
                    ? 'Unlimited responses included'
                    : '$balance credits available',
                size: 11,
                weight: FontWeight.w400,
                color: kGreyTextColor,
              ),
            ),
          ],
        ),
      );
    });
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/view/screens/electrician/profile/electrician_access_tier_page.dart';
import 'package:autonect/view/screens/supplier/dash_board/supplier_credits.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The 3-column light-peach Metrics Banner Card matching Figma (Credits Balance, Plan, Today's Earnings).
class SupplierHighlightsCard extends StatelessWidget {
  const SupplierHighlightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SupplierHomeController.ensure();

    return Obx(() {
      final balance = controller.creditBalance;
      final isSubscribed = controller.isSubscribed;
      final earningsPence = controller.todaysEarningsPence;
      final earningsStr = '£${(earningsPence / 100).toStringAsFixed(2)}';
      final planStr = isSubscribed ? 'Pro Supplier' : 'Standard';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0EC), // Figma soft peach background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFDDD4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // ── Column 1: Credits Balance ────────────────────────────
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_outlined,
                    size: 22,
                    color: kSecondaryColor,
                  ),
                  const SizedBox(height: 3),
                  MyText(
                    text: 'Credits Balance',
                    size: 11,
                    weight: FontWeight.w500,
                    color: const Color(0xFF4A4A4A),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  MyText(
                    text: '$balance',
                    size: 18,
                    weight: FontWeight.w800,
                    color: kBlackColor,
                  ),
                  const SizedBox(height: 6),
                  MyRippleEffect(
                    radius: 14,
                    onTap: () async {
                      await Get.to(() => const ElectricianAccessTierPage());
                      controller.load();
                    },
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kSecondaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Buy Credits',
                        style: TextStyle(
                          color: kWhiteColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Vertical Divider
            Container(
              height: 70,
              width: 1,
              color: const Color(0xFFFFD4C8),
            ),
            // ── Column 2: Plan ───────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 22,
                    color: kSecondaryColor,
                  ),
                  const SizedBox(height: 3),
                  MyText(
                    text: 'Plan',
                    size: 11,
                    weight: FontWeight.w500,
                    color: const Color(0xFF4A4A4A),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  MyText(
                    text: planStr,
                    size: 13,
                    weight: FontWeight.w800,
                    color: kBlackColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  MyRippleEffect(
                    radius: 14,
                    onTap: () async {
                      await Get.to(() => const ElectricianAccessTierPage());
                      controller.load();
                    },
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kWhiteColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: kSecondaryColor.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Manage Plan',
                        style: TextStyle(
                          color: Color(0xFF2C2C2C),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Vertical Divider
            Container(
              height: 70,
              width: 1,
              color: const Color(0xFFFFD4C8),
            ),
            // ── Column 3: Today's Earnings ───────────────────────────
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 22,
                    color: kSecondaryColor,
                  ),
                  const SizedBox(height: 3),
                  MyText(
                    text: "Today's Earnings",
                    size: 11,
                    weight: FontWeight.w500,
                    color: const Color(0xFF4A4A4A),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  MyText(
                    text: earningsStr,
                    size: 15,
                    weight: FontWeight.w800,
                    color: kBlackColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  MyRippleEffect(
                    radius: 14,
                    onTap: () => Get.to(() => const SupplierCreditsPage()),
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kWhiteColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: kSecondaryColor.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'View Reports',
                        style: TextStyle(
                          color: Color(0xFF2C2C2C),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Fallback / alias for existing performance card callers.
class SupplierPerformanceCard extends StatelessWidget {
  const SupplierPerformanceCard({super.key});

  @override
  Widget build(BuildContext context) => const SupplierHighlightsCard();
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

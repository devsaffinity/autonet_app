import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// kSecondaryColor hero card — the electrician home's Today's Performance card
/// re-labelled for the supplier's lead funnel.
class SupplierPerformanceCard extends StatelessWidget {
  const SupplierPerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
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
                text: "Today's Leads",
                size: 12,
                weight: FontWeight.w600,
                color: kWhiteColor.withValues(alpha: 0.8),
                paddingBottom: 6,
              ),
              MyText(
                text: '7 New Requests',
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
                    text: '3 offers accepted this week',
                    size: 16,
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
  }
}

/// Credit Balance — the Weekly Earnings card, with the progress bar running
/// toward the plan allowance instead of an earnings goal.
class SupplierCreditCard extends StatelessWidget {
  const SupplierCreditCard({super.key});

  @override
  Widget build(BuildContext context) {
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
                text: 'Credit Balance',
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
            text: '48 credits',
            size: 28,
            weight: FontWeight.w800,
            color: kBlackColor,
            paddingBottom: 12,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: const LinearProgressIndicator(
              value: 0.48,
              backgroundColor: kTertiaryColor,
              valueColor: AlwaysStoppedAnimation<Color>(kSecondaryColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: MyText(
              text: '48 of 100 monthly allowance',
              size: 11,
              weight: FontWeight.w400,
              color: kGreyTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/electrician/registration/service_provider_registration.dart'
    show AccessTier;
import 'package:autonect/view/screens/supplier/dash_board/supplier_credit_chart.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Credits dashboard. Deliberately NOT a reuse of TotalBalancePage — that
/// screen navigates to ElectricianReviewPage, which would drop a supplier onto
/// an electrician screen.
class SupplierCreditsPage extends StatelessWidget {
  const SupplierCreditsPage({super.key});

  /// One row per backend LedgerReason.
  static const List<Map<String, dynamic>> _ledger = [
    {
      'label': 'Monthly allowance',
      'amount': '+100',
      'icon': Icons.autorenew_rounded,
    },
    {
      'label': 'Lead unlock - Toyota Yaris',
      'amount': '-2',
      'icon': Icons.lock_open_rounded,
    },
    {
      'label': 'Credit purchase',
      'amount': '+50',
      'icon': Icons.add_card_outlined,
    },
    {
      'label': 'Refund - expired request',
      'amount': '+2',
      'icon': Icons.undo_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MyBackButton(),
              MyText(
                text: 'AVAILABLE CREDITS',
                size: 11,
                weight: FontWeight.w700,
                color: kGreyTextColor,
                paddingBottom: 4,
              ),
              MyText(
                text: '48 credits',
                size: 32,
                weight: FontWeight.w800,
                color: kBlackColor,
              ),
              const SizedBox(height: 20),
              _statCard('LEADS UNLOCKED', '36', Icons.lock_open_rounded),
              const SizedBox(height: 12),
              _statCard('OFFERS SENT', '31', Icons.local_offer_outlined),
              const SizedBox(height: 12),
              _statCard('WIN RATE', '42%', Icons.trending_up_rounded),
              const SizedBox(height: 28),
              const SupplierCreditChart(),
              const SizedBox(height: 24),
              MyText(
                text: 'Credit Ledger',
                size: 16,
                weight: FontWeight.w700,
                color: kBlackColor,
                paddingBottom: 12,
              ),
              SupplierCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Column(children: _ledger.map(_ledgerRow).toList()),
              ),
              const SizedBox(height: 24),
              MyButton(
                buttonText: 'Buy Credits',
                onTap: () => Get.bottomSheet(
                  MyBSheet(
                    btnText: 'Close',
                    onTap: Get.back,
                    body: AccessTier(),
                  ),
                  isScrollControlled: true,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: AppStyling().myShadowDecoration(
        color: kPrimaryColor,
        borderColor: kTertiaryColor,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text: label,
                size: 12,
                weight: FontWeight.w700,
                color: kGreyTextColor,
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: kLightOrangeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: kSecondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MyText(
            text: value,
            size: 30,
            weight: FontWeight.w800,
            color: kBlackColor,
          ),
        ],
      ),
    );
  }

  Widget _ledgerRow(Map<String, dynamic> entry) {
    final amount = entry['amount'] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kLightOrangeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              entry['icon'] as IconData,
              size: 18,
              color: kSecondaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MyText(
              text: entry['label'] as String,
              size: 14,
              weight: FontWeight.w600,
              color: kBlackColor,
            ),
          ),
          MyText(
            text: amount,
            size: 14,
            weight: FontWeight.w700,
            color: amount.startsWith('-')
                ? kRedColor
                : const Color(0xff34C759),
          ),
        ],
      ),
    );
  }
}

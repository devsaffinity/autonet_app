import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/view/screens/supplier/profile/supplier_access_tier_page.dart';
import 'package:autonect/view/screens/supplier/dash_board/supplier_credit_chart.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Credits dashboard with real balance, metrics, spend chart, and transaction ledger.
class SupplierCreditsPage extends StatefulWidget {
  const SupplierCreditsPage({super.key});

  @override
  State<SupplierCreditsPage> createState() => _SupplierCreditsPageState();
}

class _SupplierCreditsPageState extends State<SupplierCreditsPage> {
  late final BillingRepository _billing;
  bool _loadingLedger = true;
  List<Map<String, dynamic>> _ledger = [];

  @override
  void initState() {
    super.initState();
    _billing = Get.isRegistered<BillingRepository>()
        ? Get.find<BillingRepository>()
        : throw StateError('BillingRepository not registered');
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() => _loadingLedger = true);
    final res = await _billing.wallet();
    if (!mounted) return;
    if (res case Ok(:final value)) {
      final rawList = value['ledger'] as List? ?? [];
      final parsed = <Map<String, dynamic>>[];
      for (final item in rawList) {
        if (item is Map) {
          final delta = (item['delta'] as num?)?.toInt() ?? 0;
          final reason = (item['reason'] as String?) ?? '';
          parsed.add({
            'label': _reasonToLabel(reason),
            'amount': '${delta > 0 ? '+' : ''}$delta',
            'delta': delta,
            'icon': _reasonToIcon(reason),
            'at': item['at'],
          });
        }
      }
      setState(() {
        _ledger = parsed;
        _loadingLedger = false;
      });
    } else {
      setState(() {
        _ledger = [];
        _loadingLedger = false;
      });
    }
  }

  static String _reasonToLabel(String reason) {
    switch (reason.toUpperCase()) {
      case 'PURCHASE':
        return 'Credit purchase';
      case 'REQUEST_VIEW':
        return 'Request unlock';
      case 'OFFER_RESPONSE':
        return 'Offer submission';
      case 'LEAD':
        return 'Lead unlock';
      case 'REFUND':
        return 'Refund';
      case 'ADMIN_ADJUSTMENT':
        return 'Account adjustment';
      case 'TRIAL_GRANT':
        return 'Monthly / Trial allowance';
      default:
        return reason.isNotEmpty ? reason : 'Credit transaction';
    }
  }

  static IconData _reasonToIcon(String reason) {
    switch (reason.toUpperCase()) {
      case 'PURCHASE':
        return Icons.add_card_outlined;
      case 'REQUEST_VIEW':
      case 'LEAD':
        return Icons.lock_open_rounded;
      case 'REFUND':
        return Icons.undo_rounded;
      case 'TRIAL_GRANT':
        return Icons.autorenew_rounded;
      default:
        return Icons.monetization_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              SupplierHomeController.ensure().load(),
              _loadLedger(),
            ]);
          },
          color: kSecondaryColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            physics: const AlwaysScrollableScrollPhysics(),
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
                Obx(() {
                  final c = SupplierHomeController.ensure();
                  final balance = c.creditBalance;
                  final isPro = c.isSubscribed;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MyText(
                            text: isPro ? 'UNLIMITED' : '$balance credits',
                            size: 32,
                            weight: FontWeight.w800,
                            color: kBlackColor,
                          ),
                          if (isPro) ...[
                            const SizedBox(width: 10),
                            const SupplierStatusBadge(
                              label: 'PRO PLAN',
                              color: Color(0xff34C759),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      _statCard(
                        'ACTIVE NEGOTIATIONS',
                        '${c.activeNegotiations}',
                        Icons.local_offer_outlined,
                      ),
                      const SizedBox(height: 12),
                      _statCard(
                        'INCOMING REQUESTS',
                        '${c.incomingRequests}',
                        Icons.lock_open_rounded,
                      ),
                      const SizedBox(height: 12),
                      _statCard(
                        'TODAY\'S EARNINGS',
                        '£${(c.todaysEarningsPence / 100).toStringAsFixed(2)}',
                        Icons.trending_up_rounded,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 28),
                SupplierCreditChart(ledger: _ledger),
                const SizedBox(height: 24),
                MyText(
                  text: 'Credit Ledger',
                  size: 16,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                  paddingBottom: 12,
                ),
                if (_loadingLedger)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: kSecondaryColor),
                    ),
                  )
                else if (_ledger.isEmpty)
                  SupplierCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 32,
                            color: kGreyTextColor,
                          ),
                          const SizedBox(height: 8),
                          MyText(
                            text: 'No credit transactions yet',
                            size: 14,
                            weight: FontWeight.w600,
                            color: kBlackColor,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          MyText(
                            text:
                                'Purchased credits and lead unlocks will appear here.',
                            size: 12,
                            weight: FontWeight.w400,
                            color: kGreyTextColor,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SupplierCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(children: _ledger.map(_ledgerRow).toList()),
                  ),
                const SizedBox(height: 24),
                MyButton(
                  buttonText: 'Buy Credits & Manage Plans',
                  onTap: () async {
                    await Get.to(() => const SupplierAccessTierPage());
                    if (!mounted) return;
                    await Future.wait([
                      SupplierHomeController.ensure().load(),
                      _loadLedger(),
                    ]);
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
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

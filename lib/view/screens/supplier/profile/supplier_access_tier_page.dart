import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dedicated Supplier Access Tier and Subscription management screen.
///
/// Fully wired with backend `/v1/billing` endpoints:
/// - Fetches live supplier plans ('supplier-monthly', 'credits-10')
/// - Launches Stripe checkout sessions for monthly subscription & credit packs
/// - Allows cancellation of active pro subscription at period end
/// - Refreshes SupplierHomeController and ProfileController on return
class SupplierAccessTierPage extends StatefulWidget {
  const SupplierAccessTierPage({super.key});

  @override
  State<SupplierAccessTierPage> createState() => _SupplierAccessTierPageState();
}

class _SupplierAccessTierPageState extends State<SupplierAccessTierPage> {
  final ProfileController _profile = ProfileController.ensure();
  final SupplierHomeController _home = SupplierHomeController.ensure();

  BillingRepository? _billing;
  List<BillingPlan> _plans = const [];
  bool _loadingPlans = false;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<BillingRepository>()) {
      _billing = Get.find<BillingRepository>();
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loadingPlans = true);
    try {
      await Future.wait([
        _profile.load(),
        _home.load(),
        _fetchPlans(),
      ]);
    } finally {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  Future<void> _fetchPlans() async {
    final repo = _billing;
    if (repo == null) return;
    final res = await repo.plans();
    if (res case Ok(:final value)) {
      if (mounted) {
        setState(() => _plans = value);
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _profile.load(),
      _home.load(),
      _fetchPlans(),
    ]);
  }

  Future<void> _subscribeMonthly(String lookupKey) async {
    final repo = _billing;
    if (repo == null) {
      displayToast(msg: 'Billing service currently unavailable');
      return;
    }

    setState(() => _actionInProgress = true);
    try {
      final res = await repo.subscribe(lookupKey);
      switch (res) {
        case Ok(:final value):
          final url = value['url'] as String?;
          if (url != null && url.isNotEmpty) {
            displayToast(msg: 'Opening secure Stripe checkout...');
            final uri = Uri.parse(url);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            // Refresh on return
            await _refreshAll();
          } else {
            displayToast(msg: 'Could not generate checkout session');
          }
        case Err(:final error):
          displayToast(msg: error.message);
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _purchaseCredits(String lookupKey) async {
    final repo = _billing;
    if (repo == null) {
      displayToast(msg: 'Billing service currently unavailable');
      return;
    }

    setState(() => _actionInProgress = true);
    try {
      final res = await repo.purchaseCredits(lookupKey);
      switch (res) {
        case Ok(:final value):
          final url = value['url'] as String?;
          if (url != null && url.isNotEmpty) {
            displayToast(msg: 'Opening secure Stripe checkout...');
            final uri = Uri.parse(url);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            await _refreshAll();
          } else {
            displayToast(msg: 'Could not generate checkout session');
          }
        case Err(:final error):
          displayToast(msg: error.message);
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: kPrimaryColor,
        title: const MyText(
          text: 'Cancel Pro Subscription',
          size: 18,
          weight: FontWeight.w700,
          color: kBlackColor,
        ),
        content: const MyText(
          text:
              'Your Pro features will remain active until the end of the current billing cycle. After that, your account will switch to pay-per-lead credits.',
          size: 14,
          weight: FontWeight.w400,
          color: kGreyTextColor,
          lineHeight: 1.4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const MyText(
              text: 'Keep Pro',
              size: 14,
              weight: FontWeight.w600,
              color: kGreyTextColor,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRedColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const MyText(
              text: 'Confirm Cancellation',
              size: 14,
              weight: FontWeight.w700,
              color: kWhiteColor,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final repo = _billing;
    if (repo == null) return;

    setState(() => _actionInProgress = true);
    try {
      final res = await repo.cancelSubscription();
      switch (res) {
        case Ok():
          displayToast(
            msg: 'Subscription scheduled to cancel at end of billing cycle',
          );
          await _refreshAll();
        case Err(:final error):
          displayToast(msg: error.message);
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Plans & Billing'),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshAll,
            color: kSecondaryColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentStatusBanner(),
                  const SizedBox(height: 24),
                  MyText(
                    text: 'Available Plans',
                    size: 18,
                    weight: FontWeight.w800,
                    color: kBlackColor,
                  ),
                  const SizedBox(height: 6),
                  MyText(
                    text:
                        'Choose the model that aligns with your parts inventory volume and sales targets.',
                    size: 13,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                    lineHeight: 1.4,
                  ),
                  const SizedBox(height: 18),
                  _buildProPlanCard(),
                  const SizedBox(height: 20),
                  _buildCreditsPlanCard(),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
          if (_actionInProgress)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: CircularProgressIndicator(color: kSecondaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusBanner() {
    return Obx(() {
      final isSubscribed = _home.isSubscribed;
      final balance = _home.creditBalance;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0EC), // Soft peach matching highlights card
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFDDD4), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSubscribed
                          ? Icons.workspace_premium_rounded
                          : Icons.monetization_on_outlined,
                      color: kSecondaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    MyText(
                      text: 'CURRENT ACTIVE PLAN',
                      size: 11,
                      weight: FontWeight.w800,
                      color: const Color(0xFF88402A),
                      letterSpacing: 0.5,
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSubscribed
                        ? const Color(0xFF34C759)
                        : const Color(0xFF666666),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isSubscribed ? 'ACTIVE PRO' : 'STANDARD',
                    style: const TextStyle(
                      color: kWhiteColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: isSubscribed ? 'Pro Unlimited' : 'Pay-Per-Lead',
                      size: 20,
                      weight: FontWeight.w800,
                      color: kBlackColor,
                    ),
                    const SizedBox(height: 2),
                    MyText(
                      text: isSubscribed
                          ? 'Unlimited lead unlocks with £0 lead fees'
                          : '$balance credits available in your wallet',
                      size: 13,
                      weight: FontWeight.w500,
                      color: const Color(0xFF555555),
                    ),
                  ],
                ),
                if (isSubscribed)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF34C759),
                    size: 26,
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProPlanCard() {
    return Obx(() {
      final isSubscribed = _home.isSubscribed;
      final monthlyPlan = _plans
          .where((p) => !p.isCreditPack && p.interval == PlanInterval.month)
          .firstOrNull;
      final priceStr = monthlyPlan != null
          ? '£${(monthlyPlan.pricePence / 100).toStringAsFixed(0)}'
          : '£299';
      final lookupKey = monthlyPlan?.lookupKey ?? 'supplier-monthly';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSubscribed ? kSecondaryColor : const Color(0xFFFFCCBA),
            width: isSubscribed ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: kSecondaryColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'RECOMMENDED FOR VOLUME',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (isSubscribed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8EE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 12, color: Color(0xFF34C759)),
                        SizedBox(width: 4),
                        Text(
                          'YOUR CURRENT PLAN',
                          style: TextStyle(
                            color: Color(0xFF28A745),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            MyText(
              text: 'Supplier Unlimited',
              size: 20,
              weight: FontWeight.w800,
              color: kBlackColor,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MyText(
                  text: priceStr,
                  size: 28,
                  weight: FontWeight.w900,
                  color: kBlackColor,
                ),
                MyText(
                  text: ' / month',
                  size: 14,
                  weight: FontWeight.w500,
                  color: kGreyTextColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 14),
            _featureRow('Unlimited part request unlocks (0 credits deducted)'),
            _featureRow('Verified Supplier badge on quotes and profile'),
            _featureRow('Direct messaging & negotiation channels with buyers'),
            _featureRow('Priority lead distribution matching registered catalogue'),
            _featureRow('Detailed revenue analytics and transaction tracking'),
            _featureRow('Dedicated 24/7 seller support'),
            const SizedBox(height: 20),
            if (isSubscribed) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  side: const BorderSide(color: kRedColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _actionInProgress ? null : _showCancelDialog,
                child: const Text(
                  'Manage / Cancel Subscription',
                  style: TextStyle(
                    color: kRedColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ] else ...[
              MyButton(
                buttonText: 'Upgrade to Pro ($priceStr/mo)',
                onTap: _actionInProgress
                    ? null
                    : () => _subscribeMonthly(lookupKey),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildCreditsPlanCard() {
    return Obx(() {
      final isSubscribed = _home.isSubscribed;
      final creditPlan = _plans.where((p) => p.isCreditPack).firstOrNull;
      final priceStr = creditPlan != null
          ? '£${(creditPlan.pricePence / 100).toStringAsFixed(2)}'
          : '£10.00';
      final creditsCount = creditPlan?.credits ?? 10;
      final lookupKey = creditPlan?.lookupKey ?? 'credits-10';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (!isSubscribed)
                ? const Color(0xFFDCDCDC)
                : const Color(0xFFEEEEEE),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PAY AS YOU GO',
                    style: TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (!isSubscribed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'STANDARD TIER',
                      style: TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            MyText(
              text: '$creditsCount Credits Pack',
              size: 20,
              weight: FontWeight.w800,
              color: kBlackColor,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MyText(
                  text: priceStr,
                  size: 28,
                  weight: FontWeight.w900,
                  color: kBlackColor,
                ),
                MyText(
                  text: ' one-off (£1.00 / lead)',
                  size: 14,
                  weight: FontWeight.w500,
                  color: kGreyTextColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 14),
            _featureRow('$creditsCount full lead unlocks across UK regions'),
            _featureRow('Credits never expire - keep them until you use them'),
            _featureRow('Unlocks registration number, VIN and buyer details'),
            _featureRow('Send competitive quotes and negotiate prices'),
            _featureRow('Top up your balance instantly whenever needed'),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kSecondaryColor,
                elevation: 0,
                side: const BorderSide(color: kSecondaryColor, width: 1.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _actionInProgress
                  ? null
                  : () => _purchaseCredits(lookupKey),
              child: Text(
                'Buy $creditsCount Credits Pack ($priceStr)',
                style: const TextStyle(
                  color: kSecondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              color: kSecondaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MyText(
              text: text,
              size: 13,
              weight: FontWeight.w500,
              color: const Color(0xFF333333),
              lineHeight: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

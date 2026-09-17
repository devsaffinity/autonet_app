import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/view/screens/supplier/widgets/access_tier.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen accessible from Electrician Profile Settings allowing providers to
/// review, choose, and upgrade their Access Tier at any time with live Stripe payments.
class ElectricianAccessTierPage extends StatefulWidget {
  const ElectricianAccessTierPage({super.key});

  @override
  State<ElectricianAccessTierPage> createState() =>
      _ElectricianAccessTierPageState();
}

class _ElectricianAccessTierPageState extends State<ElectricianAccessTierPage> {
  final ProfileController _profile = ProfileController.ensure();
  late final BillingRepository _billing;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _billing = Get.isRegistered<BillingRepository>()
        ? Get.find<BillingRepository>()
        : throw StateError('BillingRepository not registered');
    _profile.load();
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'PRO':
        return 'Pro (Monthly)';
      case 'PAY_PER_LEAD':
        return 'Pay-Per-Lead';
      default:
        return 'Free';
    }
  }

  Future<void> _onSelectTier(String newTier) async {
    final current = _profile.me?.electricianProfile?.tier ?? 'FREE';

    if (newTier == 'PRO') {
      if (current == 'PRO') {
        _showManageProDialog();
      } else {
        await _showUpgradeProDialog();
      }
      return;
    }

    if (newTier == 'PAY_PER_LEAD') {
      if (current != 'PAY_PER_LEAD') {
        final confirmed = await _showConfirmDialog(
          title: 'Switch to Pay-Per-Lead',
          message:
              'Switch to flexible pay-per-lead model (£12 per lead unlocked with no monthly fees).',
        );
        if (confirmed != true || !mounted) return;
        setState(() => _updating = true);
        try {
          await _profile.updateElectricianTier('PAY_PER_LEAD');
          displayToast(msg: 'Switched to Pay-Per-Lead plan');
        } finally {
          if (mounted) setState(() => _updating = false);
        }
      }
      if (mounted) _showBuyCreditsSheet();
      return;
    }

    // FREE tier selection
    if (current == 'FREE') {
      displayToast(msg: 'You are currently on the Free plan');
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Switch to Free Tier',
      message:
          'Switching to Free will disable direct client lead acceptance. Are you sure you want to switch?',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);
    try {
      final success = await _profile.updateElectricianTier('FREE');
      if (success) {
        displayToast(msg: 'Switched to Free plan');
      } else {
        displayToast(msg: 'Failed to update access tier');
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: kPrimaryColor,
          title: MyText(
            text: title,
            size: 18,
            weight: FontWeight.w700,
            color: kBlackColor,
          ),
          content: MyText(
            text: message,
            size: 14,
            weight: FontWeight.w400,
            color: kGreyTextColor,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const MyText(
                text: 'Cancel',
                size: 14,
                weight: FontWeight.w600,
                color: kGreyTextColor,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const MyText(
                text: 'Confirm',
                size: 14,
                weight: FontWeight.w700,
                color: kWhiteColor,
              ),
            ),
          ],
        ),
      );

  Future<void> _showUpgradeProDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: kPrimaryColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xffFF9500),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const MyText(
                text: 'PRO',
                size: 11,
                weight: FontWeight.w800,
                color: kWhiteColor,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: MyText(
                text: 'Upgrade to Pro',
                size: 18,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              text: '£149 / month',
              size: 24,
              weight: FontWeight.w800,
              color: kBlackColor,
              paddingBottom: 8,
            ),
            MyText(
              text:
                  '• Unlimited high-intent booking leads\n• Gold PRO Specialist badge in search directory\n• Advanced analytics & performance dashboard\n• 24/7 Priority concierge support',
              size: 13,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              lineHeight: 1.5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const MyText(
              text: 'Cancel',
              size: 14,
              weight: FontWeight.w600,
              color: kGreyTextColor,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const MyText(
              text: 'Continue to Stripe',
              size: 14,
              weight: FontWeight.w700,
              color: kWhiteColor,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);
    try {
      final res = await _billing.subscribe('electrician-pro-monthly');
      switch (res) {
        case Ok(:final value):
          final url = value['url'] as String?;
          if (url != null && url.isNotEmpty) {
            displayToast(msg: 'Opening secure Stripe checkout...');
            final uri = Uri.parse(url);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            displayToast(msg: 'Could not generate checkout link');
          }
        case Err(:final error):
          displayToast(msg: error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
        _profile.load();
      }
    }
  }

  void _showManageProDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: kPrimaryColor,
        title: const MyText(
          text: 'Active Pro Subscription',
          size: 18,
          weight: FontWeight.w700,
          color: kBlackColor,
        ),
        content: const MyText(
          text:
              'You currently have an active Pro (Monthly) subscription with unlimited leads and PRO directory status.',
          size: 14,
          weight: FontWeight.w400,
          color: kGreyTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const MyText(
              text: 'Keep Subscription',
              size: 14,
              weight: FontWeight.w600,
              color: kSecondaryColor,
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final confirmCancel = await _showConfirmDialog(
                title: 'Cancel Pro Subscription',
                message:
                    'Your Pro subscription will be scheduled to cancel at the end of the billing cycle. You will keep your benefits until then.',
              );
              if (confirmCancel == true) {
                setState(() => _updating = true);
                try {
                  final res = await _billing.cancelSubscription();
                  switch (res) {
                    case Ok():
                      displayToast(msg: 'Cancellation scheduled at period end');
                    case Err(:final error):
                      displayToast(msg: error.message);
                  }
                } finally {
                  if (mounted) {
                    setState(() => _updating = false);
                    _profile.load();
                  }
                }
              }
            },
            child: const MyText(
              text: 'Cancel Pro',
              size: 14,
              weight: FontWeight.w600,
              color: kRedColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showBuyCreditsSheet() {
    Get.bottomSheet(
      MyBSheet(
        btnText: 'Close',
        onTap: Get.back,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MyText(
              text: 'Purchase Lead Credits',
              size: 20,
              weight: FontWeight.w800,
              color: kBlackColor,
              paddingBottom: 4,
            ),
            const MyText(
              text:
                  '1 credit unlocks 1 customer booking lead. Unused credits never expire.',
              size: 13,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              paddingBottom: 16,
            ),
            _CreditPackTile(
              title: '1 Lead Credit',
              price: '£12',
              savings: null,
              onTap: () => _purchaseCredits('electrician-lead-1'),
            ),
            const SizedBox(height: 10),
            _CreditPackTile(
              title: '5 Lead Credits',
              price: '£55',
              savings: 'Save £5',
              isPopular: true,
              onTap: () => _purchaseCredits('electrician-leads-5'),
            ),
            const SizedBox(height: 10),
            _CreditPackTile(
              title: '10 Lead Credits',
              price: '£100',
              savings: 'Save £20',
              onTap: () => _purchaseCredits('electrician-leads-10'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _purchaseCredits(String lookupKey) async {
    Get.back(); // close bottom sheet
    setState(() => _updating = true);
    try {
      final res = await _billing.purchaseCredits(lookupKey);
      switch (res) {
        case Ok(:final value):
          final url = value['url'] as String?;
          if (url != null && url.isNotEmpty) {
            displayToast(msg: 'Opening secure Stripe checkout...');
            final uri = Uri.parse(url);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            displayToast(msg: 'Could not generate checkout link');
          }
        case Err(:final error):
          displayToast(msg: error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
        _profile.load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Access Tier', hasBackButton: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s20,
              vertical: AppSizes.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final ep = _profile.me?.electricianProfile;
                  final current = ep?.tier ?? 'FREE';
                  final label = _tierLabel(current);
                  final credits = ep?.creditBalance ?? 0;
                  final isPro = current == 'PRO';
                  final isPayPerLead = current == 'PAY_PER_LEAD';

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: AppStyling().myShadowDecoration(
                      color: kPrimaryColor,
                      radius: 14,
                      borderColor: kTransperentColor,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isPro
                                    ? const Color(0xffFF9500).withValues(alpha: .15)
                                    : kSecondaryColor.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isPro
                                    ? Icons.workspace_premium_rounded
                                    : Icons.bolt_rounded,
                                color: isPro
                                    ? const Color(0xffFF9500)
                                    : kSecondaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const MyText(
                                    text: 'Current Active Tier',
                                    size: 12,
                                    weight: FontWeight.w500,
                                    color: kGreyTextColor,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      MyText(
                                        text: label,
                                        size: 16,
                                        weight: FontWeight.w700,
                                        color: kBlackColor,
                                      ),
                                      if (isPro) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xffFF9500),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const MyText(
                                            text: 'PRO',
                                            size: 9,
                                            weight: FontWeight.w800,
                                            color: kWhiteColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xff34C759).withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const MyText(
                                text: 'ACTIVE',
                                size: 11,
                                weight: FontWeight.w700,
                                color: Color(0xff34C759),
                              ),
                            ),
                          ],
                        ),
                        if (isPayPerLead) ...[
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const MyText(
                                    text: 'Available Lead Credits',
                                    size: 12,
                                    color: kGreyTextColor,
                                  ),
                                  const SizedBox(height: 2),
                                  MyText(
                                    text: '$credits credits',
                                    size: 18,
                                    weight: FontWeight.w800,
                                    color: kBlackColor,
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kSecondaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: _showBuyCreditsSheet,
                                icon: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                  size: 16,
                                  color: kWhiteColor,
                                ),
                                label: const MyText(
                                  text: 'Buy Credits',
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: kWhiteColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const MyText(
                  text: 'Select Your Plan',
                  size: 18,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                ),
                const SizedBox(height: 6),
                const MyText(
                  text:
                      "Configure how you'd like to receive leads and manage your service portfolio on the AutoVolt network.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  lineHeight: 1.4,
                  paddingBottom: 20,
                ),
                Obx(() {
                  final current =
                      _profile.me?.electricianProfile?.tier ?? 'FREE';
                  return AccessTier(
                    currentTier: current,
                    onPlanSelected: _onSelectTier,
                  );
                }),
              ],
            ),
          ),
          if (_updating)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: kSecondaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreditPackTile extends StatelessWidget {
  const _CreditPackTile({
    required this.title,
    required this.price,
    required this.onTap,
    this.savings,
    this.isPopular = false,
  });

  final String title;
  final String price;
  final String? savings;
  final bool isPopular;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        border: Border.all(
          color: isPopular ? kSecondaryColor : kBlackColor.withValues(alpha: .15),
          width: isPopular ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            MyText(
              text: title,
              size: 15,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
            if (savings != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xff34C759).withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: MyText(
                  text: savings!,
                  size: 11,
                  weight: FontWeight.w700,
                  color: const Color(0xff34C759),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(
              text: price,
              size: 18,
              weight: FontWeight.w800,
              color: kSecondaryColor,
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: kGreyTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

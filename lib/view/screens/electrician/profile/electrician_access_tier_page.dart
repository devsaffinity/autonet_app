import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/billing/provider_billing_controller.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/domain/billing_display.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/plan_cards.dart';
import 'package:autonect/view/screens/electrician/profile/electrician_tier_status_card.dart';
import 'package:autonect/view/screens/supplier/widgets/access_tier.dart';
import 'package:autonect/view/widget/billing_dialogs.dart';
import 'package:autonect/view/widget/credit_packs_sheet.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The electrician's plans screen: Free < Pay-Per-Lead < Pro.
///
/// Everything it shows and offers comes from `GET /v1/billing/status` through
/// [ProviderBillingController] — the server decides each plan's price and
/// whether it may be bought (upgrade-only), and buying happens in the Play
/// Store or App Store. Cancelling happens there too, so this screen links out
/// rather than pretending to do it.
class ElectricianAccessTierPage extends StatefulWidget {
  const ElectricianAccessTierPage({super.key});

  @override
  State<ElectricianAccessTierPage> createState() => _ElectricianAccessTierPageState();
}

class _ElectricianAccessTierPageState extends State<ElectricianAccessTierPage> {
  late final ProviderBillingController c;

  @override
  void initState() {
    super.initState();
    c = ProviderBillingController.ensure();
    c.load();
  }

  @override
  void dispose() {
    // The profile tile and the lead dialogs read /me: refresh it if the plan changed.
    if (c.changedThisVisit) ProfileController.maybeFind()?.load();
    super.dispose();
  }

  Future<void> _onAction(TierAction action) async {
    final s = c.current;
    if (s == null) return;
    switch (action) {
      case TierAction.subscribe:
        final offer = s.subscriptionOffer;
        if (offer == null) return;
        final ok = await confirmBillingDialog(
          context,
          badge: 'PRO',
          title: 'Upgrade to Pro',
          headline: '${formatPriceTag(offer.pricePence)} / month',
          message:
              '• Unlimited high-intent booking leads\n• Gold PRO Specialist badge in search directory\n'
              '• Advanced analytics & performance dashboard\n• 24/7 Priority concierge support\n\n'
              'Billed by the app store, renewing monthly until you cancel there.',
          confirmText: 'Continue',
        );
        if (ok && mounted) await c.buy(offer.lookupKey);
      case TierAction.manageInStore:
        await _manage(s);
      case TierAction.buyCredits:
        _openPacks();
      case TierAction.none:
      case TierAction.chooseFree:
      case TierAction.choosePayPerLead:
        break;
    }
  }

  /// Everything the store owns: cancel, resume, change card.
  Future<void> _manage(BillingStatus s) async {
    final cancelling = s.displayState == BillingDisplayState.activeCancelling;
    final pastDue = s.displayState == BillingDisplayState.pastDue;
    final ok = await confirmBillingDialog(
      context,
      title: pastDue
          ? 'Update Payment'
          : cancelling
              ? 'Resume Pro'
              : 'Manage Subscription',
      message: pastDue
          ? 'Your last payment failed. Update your payment method in the store to keep Pro.'
          : cancelling
              ? resumeWarning(s)
              : cancelWarning(s, BillingAudience.electrician),
      confirmText: 'Open Store',
    );
    if (ok && mounted) await c.openStoreManagement();
  }

  void _openPacks() => Get.bottomSheet(
    CreditPacksSheet(audience: BillingAudience.electrician, onSelect: c.buy),
    isScrollControlled: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Access Tier', hasBackButton: true),
      body: Obx(() {
        // Every Rx read here, inside the closure — StateView's builder runs
        // outside Obx's tracking zone and only uses the captured values.
        final state = c.status.value;
        final working = c.working.value;
        final awaiting = c.awaiting.value;
        final busy = working != null || awaiting != null;
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: c.reload,
              color: kSecondaryColor,
              child: StateView<BillingStatus>(
                state: state,
                onRetry: c.load,
                builder: (context, s) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20, vertical: AppSizes.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElectricianTierStatusCard(
                        status: s,
                        banner: describeBilling(s, BillingAudience.electrician, awaiting: awaiting),
                        enabled: !busy,
                        onManage: () => _manage(s),
                        onBuyCredits: _openPacks,
                      ),
                      const MyText(text: 'Select Your Plan', size: 18, weight: FontWeight.w800, color: kBlackColor),
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
                      AccessTier(cards: electricianTierCards(s, busy: busy), onAction: _onAction),
                      _RestoreRow(enabled: !busy, onTap: c.restorePurchases),
                    ],
                  ),
                ),
              ),
            ),
            // Talking to the store, before its sheet appears.
            if (working != null && awaiting == null)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator(color: kSecondaryColor)),
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// Apple requires a way to recover purchases already made; Android users hit
/// it after a reinstall or a new phone.
class _RestoreRow extends StatelessWidget {
  const _RestoreRow({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.restore_rounded, size: 18, color: kSecondaryColor),
        label: const MyText(text: 'Restore purchases', size: 13, weight: FontWeight.w600, color: kSecondaryColor),
      ),
    ),
  );
}

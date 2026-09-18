import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/billing/provider_billing_controller.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/domain/billing_display.dart';
import 'package:autonect/domain/date_format.dart';
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
/// whether it may be bought (upgrade-only), and payments happen in Stripe's
/// payment sheet INSIDE the app.
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
              '• Advanced analytics & performance dashboard\n• 24/7 Priority concierge support',
          confirmText: 'Continue to payment',
        );
        if (ok && mounted) await c.subscribe(offer.lookupKey);
      case TierAction.manage:
        await _manage(s);
      case TierAction.resume:
        await _resume(s);
      case TierAction.fixPayment:
        await c.retryPayment();
      case TierAction.buyCredits:
        _openPacks();
      case TierAction.none:
      case TierAction.chooseFree:
      case TierAction.choosePayPerLead:
        break;
    }
  }

  Future<void> _manage(BillingStatus s) async {
    final renews = s.subscription?.currentPeriodEnd;
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => billingChoiceDialog(
        ctx,
        title: 'Active Pro Subscription',
        message:
            'Unlimited leads and PRO directory status.${renews == null ? '' : ' Renews on ${formatLongDate(renews)}.'}',
        keepText: 'Keep Subscription',
        leaveText: 'Cancel Pro',
      ),
    );
    if (choice == true && mounted) await _cancel(s);
  }

  Future<void> _cancel(BillingStatus s) async {
    final ok = await confirmBillingDialog(
      context,
      title: 'Cancel Pro Subscription',
      message: cancelWarning(s, BillingAudience.electrician),
      confirmText: 'Confirm Cancellation',
      destructive: true,
    );
    if (ok && mounted) await c.cancelSubscription();
  }

  Future<void> _resume(BillingStatus s) async {
    final ok = await confirmBillingDialog(
      context,
      title: 'Resume Pro',
      message: resumeWarning(s),
      confirmText: 'Resume',
    );
    if (ok && mounted) await c.resumeSubscription();
  }

  void _openPacks() => Get.bottomSheet(
    CreditPacksSheet(audience: BillingAudience.electrician, onSelect: c.buyCredits),
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
                        onCancel: () => _cancel(s),
                        onResume: () => _resume(s),
                        onFixPayment: c.retryPayment,
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
                    ],
                  ),
                ),
              ),
            ),
            // Creating the payment on the server, before the sheet opens.
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

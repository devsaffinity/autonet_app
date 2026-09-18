import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/controller/billing/provider_billing_controller.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/domain/billing_display.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/screens/supplier/profile/supplier_plan_cards.dart';
import 'package:autonect/view/widget/billing_dialogs.dart';
import 'package:autonect/view/widget/credit_packs_sheet.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The supplier's Plans & Billing: none < credits < Pro subscription.
///
/// Driven entirely by `GET /v1/billing/status` through
/// [ProviderBillingController]: the server prices each plan and decides what
/// may be bought (upgrade-only). Payments open Stripe's payment sheet INSIDE
/// the app; cancel keeps Pro to the date shown, and can be resumed until then.
class SupplierAccessTierPage extends StatefulWidget {
  const SupplierAccessTierPage({super.key});

  @override
  State<SupplierAccessTierPage> createState() => _SupplierAccessTierPageState();
}

class _SupplierAccessTierPageState extends State<SupplierAccessTierPage> {
  late final ProviderBillingController c;

  @override
  void initState() {
    super.initState();
    c = ProviderBillingController.ensure();
    c.load();
  }

  @override
  void dispose() {
    // The dashboard and profile show the plan too: refresh them if it changed.
    if (c.changedThisVisit) {
      if (Get.isRegistered<SupplierHomeController>()) Get.find<SupplierHomeController>().load();
      ProfileController.maybeFind()?.load();
    }
    super.dispose();
  }

  Future<void> _upgrade(BillingOffer offer) async {
    final ok = await confirmBillingDialog(
      context,
      title: 'Upgrade to Pro',
      headline: '${formatPriceTag(offer.pricePence)} / month',
      message: 'Unlimited part request unlocks with no credits deducted, billed monthly until you cancel.',
      confirmText: 'Continue to payment',
    );
    if (ok && mounted) await c.subscribe(offer.lookupKey);
  }

  Future<void> _cancel(BillingStatus s) async {
    final ok = await confirmBillingDialog(
      context,
      title: 'Cancel Pro Subscription',
      message: cancelWarning(s, BillingAudience.supplier),
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

  void _buyCredits(BillingStatus s) {
    final packs = s.creditPacks.where((p) => p.allowed).toList();
    if (packs.length == 1) {
      c.buyCredits(packs.single.lookupKey);
      return;
    }
    Get.bottomSheet(
      CreditPacksSheet(audience: BillingAudience.supplier, onSelect: c.buyCredits),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Plans & Billing'),
      body: Obx(() {
        // Rx reads stay inside this closure; the builder uses the captured values.
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SupplierStatusBanner(banner: describeBilling(s, BillingAudience.supplier, awaiting: awaiting)),
                      const SizedBox(height: 24),
                      const MyText(text: 'Available Plans', size: 18, weight: FontWeight.w800, color: kBlackColor),
                      const SizedBox(height: 6),
                      const MyText(
                        text: 'Choose the model that aligns with your parts inventory volume and sales targets.',
                        size: 13,
                        weight: FontWeight.w400,
                        color: kGreyTextColor,
                        lineHeight: 1.4,
                      ),
                      const SizedBox(height: 18),
                      SupplierProCard(
                        status: s,
                        busy: busy,
                        onUpgrade: _upgrade,
                        onCancel: () => _cancel(s),
                        onResume: () => _resume(s),
                        onFixPayment: c.retryPayment,
                      ),
                      const SizedBox(height: 20),
                      SupplierCreditsCard(status: s, busy: busy, onBuy: () => _buyCredits(s)),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
            if (working != null && awaiting == null)
              Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(child: CircularProgressIndicator(color: kSecondaryColor)),
              ),
          ],
        );
      }),
    );
  }
}

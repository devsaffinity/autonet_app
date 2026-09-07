import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/supplier/supplier_plan_controller.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 5 of 5 — the monetization models.
///
/// INFORMATIONAL, not a checkout. Buying goes through Stripe Checkout, which
/// answers with a hosted URL, and the app has no url_launcher, no webview and
/// no registered URL scheme — so a "Subscribe" button here could not open
/// anything. Billing is arranged after approval, and the screen says so rather
/// than offering a control that fails.
///
/// Two models, not the design's three. Commission needs Stripe Connect, a
/// payout flow and a definition of "completed sale", and there is no money
/// movement on orders to take a percentage of. The backend's own standards
/// record the decision: "No commission — monetization is subscription + credit
/// packs."
class SupplierPlanStep extends StatefulWidget {
  final VoidCallback onFinish;
  const SupplierPlanStep({super.key, required this.onFinish});

  @override
  State<SupplierPlanStep> createState() => _SupplierPlanStepState();
}

class _SupplierPlanStepState extends State<SupplierPlanStep> {
  final _c = SupplierPlanController.ensure();

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Choose your growth model',
                  size: AppTextScale.title,
                  weight: AppWeights.bold,
                  color: kBlackColor,
                  paddingTop: AppSizes.s24,
                ),
                MyText(
                  text:
                      'Autonect offers two ways to pay for leads. You can pick '
                      'one after your account is approved, and switch later.',
                  size: AppTextScale.label,
                  color: kGreyTextColor,
                  lineHeight: 1.5,
                  paddingTop: AppSizes.s8,
                  paddingBottom: AppSizes.s20,
                ),
                Obx(() => StateView<List<BillingPlan>>(
                  state: _c.plans.value,
                  onRetry: _c.load,
                  emptyTitle: 'No plans available',
                  builder: (_, plans) => Column(
                    children: [
                      for (final p in plans) ...[
                        _PlanCard(plan: p),
                        const SizedBox(height: AppSizes.s12),
                      ],
                    ],
                  ),
                )),
                const SizedBox(height: AppSizes.s8),
                _billingNote(),
                const SizedBox(height: AppSizes.s24),
              ],
            ),
          ),
        ),
        // Never gated on picking a plan: nothing here is selectable, and
        // billing is arranged after approval.
        SupplierBottomButton(label: 'Submit for review', onTap: widget.onFinish),
      ],
    );
  }

  Widget _billingNote() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSizes.s12),
    decoration: BoxDecoration(
      color: kLightOrangeColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: AppSizes.s16,
            color: kSecondaryColor),
        const SizedBox(width: AppSizes.s8),
        Expanded(
          child: MyText(
            text: 'Nothing is charged now. Your account is reviewed first, '
                'and our team will set up billing with you before you receive '
                'any leads.',
            size: AppTextScale.caption,
            color: kGreyTextColor,
            lineHeight: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final BillingPlan plan;

  @override
  Widget build(BuildContext context) {
    // The credit pack is the recommended model in the design. It is also the
    // cheaper way in, so the badge is not just decoration.
    final recommended = plan.isCreditPack;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: recommended ? kSecondaryColor : kPrimaryColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: recommended
              ? kSecondaryColor
              : kGreyTextColor.withValues(alpha: .3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MyText(
                  text: plan.name,
                  size: AppTextScale.body,
                  weight: AppWeights.bold,
                  color: recommended ? kWhiteColor : kBlackColor,
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
              if (recommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s8, vertical: AppSizes.s4),
                  decoration: BoxDecoration(
                    color: kWhiteColor.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: MyText(text: 'RECOMMENDED',
                      size: AppTextScale.caption, color: kWhiteColor,
                      weight: AppWeights.bold),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.s8),
          MyText(
            text: plan.isCreditPack
                ? 'Pay only for the leads you want. Best for specialist parts.'
                : 'A flat monthly fee with no per-lead cost. Best for volume.',
            size: AppTextScale.label,
            color: recommended
                ? kWhiteColor.withValues(alpha: .85)
                : kGreyTextColor,
            lineHeight: 1.4,
          ),
          const SizedBox(height: AppSizes.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MyText(
                text: plan.displayPrice,
                size: AppTextScale.title,
                weight: AppWeights.bold,
                color: recommended ? kWhiteColor : kBlackColor,
              ),
              const SizedBox(width: AppSizes.s8),
              // The pack price is not the per-lead price: £10.00 buys TEN
              // credits, so a lead is £1.00. Omitting this reads as £10 a lead.
              if (plan.displayPerCredit case final perCredit?)
                Expanded(
                  child: MyText(
                    text: perCredit,
                    size: AppTextScale.caption,
                    color: recommended
                        ? kWhiteColor.withValues(alpha: .85)
                        : kGreyTextColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

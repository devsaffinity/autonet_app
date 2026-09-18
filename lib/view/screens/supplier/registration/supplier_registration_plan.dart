import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/billing/billing_plans_controller.dart';
import 'package:autonect/controller/supplier/supplier_registration_controller.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/domain/growth_model.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 3 of 3 — the monetization models.
///
/// The supplier PICKS one and it is sent with the registration, landing on
/// `SupplierProfile.monetizationModel`. It is a stated preference rather than a
/// purchase: nothing charges during registration. Paying happens after
/// approval, on Plans & Billing, in Stripe's in-app payment sheet — the note at
/// the bottom says so — and the reviewer gets an answer instead of having to ask.
class SupplierPlanStep extends StatefulWidget {
  final VoidCallback onFinish;

  /// The design's "Back to Home". Inside the wizard that is the previous step —
  /// an unapproved supplier has no home to return to.
  final VoidCallback? onBack;

  const SupplierPlanStep({super.key, required this.onFinish, this.onBack});

  @override
  State<SupplierPlanStep> createState() => _SupplierPlanStepState();
}

class _SupplierPlanStepState extends State<SupplierPlanStep> {
  final _c = BillingPlansController.ensure();
  // The wizard's controller owns the answer, because it is submitted with the
  // rest of the registration rather than on its own.
  final _reg = Get.find<SupplierRegistrationController>();

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
            padding: AppSizes.HORIZONTAL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Choose Your Growth Model',
                  size: AppTextScale.title,
                  weight: AppWeights.bold,
                  color: kBlackColor,
                  paddingTop: AppSizes.s20,
                ),
                MyText(
                  // "Velocity Supply" in the design is a template leftover from
                  // another product. Using it would put a different company's
                  // name in front of every supplier who signs up.
                  text: 'Autonect offers flexible monetization paths tailored '
                      'to your business scale. Select a model that best fits '
                      'your logistical capacity and revenue targets.',
                  size: AppTextScale.label,
                  color: kGreyTextColor,
                  lineHeight: 1.5,
                  paddingTop: AppSizes.s8,
                  paddingBottom: AppSizes.s20,
                ),
                // Only the PRICES need the server; the copy is presentation
                // data, so the cards render as soon as the screen opens and the
                // figures fill in.
                Obx(() {
                  // Read HERE, inside the Obx closure. From StateView.builder it
                  // would run in a different performRebuild with no tracking
                  // proxy installed, register no dependency, and tapping a card
                  // would change nothing on screen.
                  final chosen = _reg.growthModel.value;
                  return StateView<List<BillingPlan>>(
                  state: _c.plans.value,
                  onRetry: _c.load,
                  emptyTitle: 'Pricing unavailable',
                  builder: (_, plans) => Column(
                    children: [
                      for (final model in GrowthModel.values) ...[
                        _PlanCard(
                          model: model,
                          plans: plans,
                          selected: model == chosen,
                          onSelect: () => _reg.growthModel.value = model,
                        ),
                        const SizedBox(height: AppSizes.s12),
                      ],
                    ],
                  ),
                );
                }),
                const SizedBox(height: AppSizes.s8),
                const _RecommendationCard(),
                const SizedBox(height: AppSizes.s24),
              ],
            ),
          ),
        ),
        _actions(),
      ],
    );
  }

  Widget _actions() => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    color: kPrimaryColor,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onBack case final onBack?)
          MyButton(
            buttonText: '←  Back',
            backgroundColor: kPrimaryColor,
            outlineColor: kSecondaryColor,
            fontColor: kSecondaryColor,
            onTap: onBack,
            mBottom: AppSizes.s12,
          ),
        MyButton(buttonText: 'Proceed to Review', onTap: widget.onFinish),
      ],
    ),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.model,
    required this.plans,
    required this.selected,
    required this.onSelect,
  });

  final GrowthModel model;
  final List<BillingPlan> plans;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    // The orange fill means SELECTED, not "recommended". Those were the same
    // card in the design because the recommended one is preselected, but tying
    // the fill to `recommended` made the highlight a constant — tapping another
    // card changed nothing visible.
    final highlight = selected;
    final onCard = highlight ? kWhiteColor : kBlackColor;
    final muted = highlight
        ? kWhiteColor.withValues(alpha: .85)
        : kGreyTextColor;
    final note = model.priceNoteFrom(plans);

    return Semantics(
      button: true,
      selected: selected,
      label: model.title,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: ExcludeSemantics(
          child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: highlight ? kSecondaryColor : kPrimaryColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: highlight
              ? kSecondaryColor
              : kGreyTextColor.withValues(alpha: .25),
          width: highlight ? 1 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: highlight
                      ? kWhiteColor.withValues(alpha: .2)
                      : kLightOrangeColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(_glyph, size: AppSizes.s20,
                    color: highlight ? kWhiteColor : kSecondaryColor),
              ),
              const Spacer(),
              // Independent of selection: the recommendation does not move when
              // the supplier picks a different card.
              if (model.recommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s8, vertical: AppSizes.s4),
                  decoration: BoxDecoration(
                    color: highlight
                        ? kWhiteColor.withValues(alpha: .25)
                        : kLightOrangeColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: MyText(text: 'RECOMMENDED',
                      size: AppTextScale.caption,
                      color: highlight ? kWhiteColor : kSecondaryColor,
                      weight: AppWeights.bold, letterSpacing: .5),
                ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.s8),
                  child: Icon(Icons.check_circle_rounded,
                      size: AppSizes.s20, color: kWhiteColor),
                ),
            ],
          ),
          MyText(text: model.title, size: AppTextScale.subtitle,
              weight: AppWeights.bold, color: onCard,
              paddingTop: AppSizes.s12),
          MyText(text: model.description, size: AppTextScale.label,
              color: muted, lineHeight: 1.5, paddingTop: AppSizes.s4),
          const SizedBox(height: AppSizes.s12),
          for (final feature in model.features)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle,
                      size: AppSizes.s16,
                      color: highlight ? kWhiteColor : kSecondaryColor),
                  const SizedBox(width: AppSizes.s8),
                  Expanded(
                    child: MyText(text: feature, size: AppTextScale.label,
                        color: onCard, lineHeight: 1.4),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSizes.s12),
          // Baseline-aligned so the suffix sits on the figure's baseline as
          // drawn, rather than centred against a much taller number.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              MyText(text: model.priceLabelFrom(plans),
                  size: AppTextScale.display, weight: AppWeights.bold,
                  color: onCard),
              MyText(text: model.priceSuffixFrom(plans),
                  size: AppTextScale.label, color: muted,
                  paddingLeft: AppSizes.s4),
            ],
          ),
          // The pack price is not the per-lead price; without this the credits
          // card reads as ten times its real cost.
          if (note != null)
            MyText(text: note, size: AppTextScale.caption, color: muted,
                paddingTop: AppSizes.s4),
        ],
      ),
          ),
        ),
      ),
    );
  }

  IconData get _glyph => switch (model) {
    GrowthModel.subscription => Icons.calendar_month_outlined,
    GrowthModel.credits => Icons.confirmation_number_outlined,
    GrowthModel.commission => Icons.sell_outlined,
  };
}

/// The design's "Unsure which model to pick?" card.
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard();

  @override
  Widget build(BuildContext context) {
    // Reads the categories the supplier picked two steps ago, which are real
    // and already in memory. The design's "inventory size of 450+ components"
    // has no source — nothing anywhere counts a supplier's stock, and there is
    // no point in onboarding at which it could.
    final categories =
        Get.isRegistered<SupplierRegistrationController>()
            ? Get.find<SupplierRegistrationController>().categoryIds.length
            : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: kMutedSurfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(text: 'Unsure which model to pick?',
              size: AppTextScale.body, weight: AppWeights.bold,
              color: kBlackColor),
          MyText(
            text: categories > 0
                ? 'Credits suits most new suppliers, and with '
                    '$categories part ${categories == 1 ? 'category' : 'categories'} '
                    'selected you can start small and only pay for the leads '
                    'you want. You can change model later.'
                : 'Credits suits most new suppliers: start small and pay only '
                    'for the leads you want. You can change model later.',
            size: AppTextScale.label,
            color: kGreyTextColor,
            lineHeight: 1.5,
            paddingTop: AppSizes.s8,
            paddingBottom: AppSizes.s12,
          ),
          Wrap(
            spacing: AppSizes.s8,
            runSpacing: AppSizes.s8,
            children: [
              // "TAX INCLUSIVE PRICING" from the design is deliberately absent:
              // it is a tax-treatment claim on a B2B subscription, Stripe Tax
              // is not configured and Plan carries no tax flag. Encryption is a
              // fact about the transport and can stay.
              _chip(Icons.lock_outline, 'ENCRYPTED TRANSACTIONS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s8, vertical: AppSizes.s4),
    decoration: BoxDecoration(
      color: kPrimaryColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      border: Border.all(color: kGreyTextColor.withValues(alpha: .3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.s12, color: kGreyTextColor),
        const SizedBox(width: AppSizes.s4),
        MyText(text: label, size: AppTextScale.caption, color: kGreyTextColor,
            weight: AppWeights.medium, letterSpacing: .5),
      ],
    ),
  );
}

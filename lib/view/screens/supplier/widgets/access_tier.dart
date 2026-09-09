import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The plan picker.
///
/// LIVED IN THE ELECTRICIAN REGISTRATION WIZARD, which was the wrong home for
/// it twice over: billing is SUPPLIER-only by design — `ElectricianProfile`
/// has no credit balance and nothing bills a provider — and the only other
/// caller, `supplier_credits.dart`, had to reach across into an electrician
/// screen to use it. Moved here, where its one real caller lives.
class AccessTier extends StatelessWidget {
  /// Fired when a plan is chosen. Optional so `AccessTier()` still compiles
  /// wherever the widget is only being displayed (e.g. a pricing sheet).
  final ValueChanged<String>? onPlanSelected;

  const AccessTier({super.key, this.onPlanSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Free Card ─────────────────────────────────────────────────────
          _PricingCard(
            tag: 'Entry',
            tagColor: kGreyTextColor,
            title: 'Free',
            price: '\$0',
            period: '/Lifetime',
            features: const [
              _Feature(label: 'Basic Company Profile', enabled: true),
              _Feature(label: 'Public Listing In Directory', enabled: true),
              _Feature(label: 'Standard Email Support', enabled: true),
              _Feature(label: 'Direct Client Leads', enabled: false),
            ],
            buttonText: 'Choose Basic',
            isHighlighted: false,
            onTap: () => onPlanSelected?.call('FREE'),
          ),
          const SizedBox(height: 16),

          // ── Pro Card ──────────────────────────────────────────────────────
          _PricingCard(
            tag: 'Growth',
            tagColor: kWhiteColor,
            title: 'Pro (Monthly)',
            price: '\$149',
            period: '/Month',
            features: const [
              _Feature(label: 'Unlimited High-Intent Leads', enabled: true),
              _Feature(label: 'Premium Badge & Verified Status', enabled: true),
              _Feature(label: 'Advanced Analytics Dashboard', enabled: true),
              _Feature(label: '24/7 Priority Concierge', enabled: true),
            ],
            buttonText: 'Start Pro Trial',
            isHighlighted: true,
            showBestValue: true,
            onTap: () => onPlanSelected?.call('PRO'),
          ),
          const SizedBox(height: 16),

          // ── Pay-Per-Lead Card ─────────────────────────────────────────────
          _PricingCard(
            tag: 'Flexible',
            tagColor: kSecondaryColor,
            title: 'Pay-Per-Lead',
            price: '\$12',
            period: '/Per Lead',
            features: const [
              _Feature(label: 'Credit-Based System', enabled: true),
              _Feature(label: 'No Fixed Monthly Fees', enabled: true),
              _Feature(label: 'Select Leads Manually', enabled: true),
              _Feature(label: 'Top-Up Credits Anytime', enabled: true),
            ],
            buttonText: 'Choose Credits',
            isHighlighted: false,
            onTap: () => onPlanSelected?.call('PAY_PER_LEAD'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal feature model
// ─────────────────────────────────────────────────────────────────────────────
class _Feature {
  final String label;
  final bool enabled;
  const _Feature({required this.label, required this.enabled});
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Pricing Card
// ─────────────────────────────────────────────────────────────────────────────
class _PricingCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final String title;
  final String price;
  final String period;
  final List<_Feature> features;
  final String buttonText;
  final bool isHighlighted;
  final bool showBestValue;
  final VoidCallback onTap;

  const _PricingCard({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.buttonText,
    required this.isHighlighted,
    required this.onTap,
    this.showBestValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBg = isHighlighted ? kSecondaryColor : kPrimaryColor;
    final Color titleColor = isHighlighted ? kWhiteColor : kBlackColor;
    final Color priceColor = isHighlighted ? kWhiteColor : kBlackColor;
    final Color periodColor = isHighlighted
        ? kWhiteColor.withOpacity(0.75)
        : kGreyTextColor;
    final Color featureColor = isHighlighted ? kWhiteColor : kBlackColor;
    final Color iconColor = isHighlighted ? kWhiteColor : kSecondaryColor;
    final Color disabledColor = isHighlighted
        ? kWhiteColor.withOpacity(0.4)
        : kGreyTextColor;

    return Container(
      decoration: AppStyling().myShadowDecoration(
        color: cardBg,
        radius: 16,
        borderColor: kTransperentColor,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tag ─────────────────────────────────────────────────────
                MyText(
                  text: tag,
                  size: 12,
                  weight: FontWeight.w500,
                  color: tagColor,
                  paddingBottom: 6,
                ),

                // ── Title ────────────────────────────────────────────────────
                MyText(
                  text: title,
                  size: isHighlighted ? 26 : 22,
                  weight: FontWeight.w800,
                  color: titleColor,
                  paddingBottom: 12,
                ),

                // ── Price row ────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MyText(
                      text: price,
                      size: 36,
                      weight: FontWeight.w800,
                      color: priceColor,
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: MyText(
                        text: period,
                        size: 14,
                        weight: FontWeight.w400,
                        color: periodColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Features ─────────────────────────────────────────────────
                ...features.map(
                  (f) => _FeatureRow(
                    label: f.label,
                    enabled: f.enabled,
                    enabledColor: iconColor,
                    labelColor: f.enabled ? featureColor : disabledColor,
                    isHighlighted: isHighlighted,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Button ───────────────────────────────────────────────────
                MyButton(
                  buttonText: buttonText,
                  onTap: onTap,
                  backgroundColor: isHighlighted
                      ? kPrimaryColor
                      : kSecondaryColor,
                  fontColor: isHighlighted ? kSecondaryColor : kWhiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 50,
                  radius: 100,
                ),
              ],
            ),
          ),

          // ── "Best Value" badge ───────────────────────────────────────────
          if (showBestValue)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: MyText(
                  text: 'Best Value',
                  size: 12,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature row with check / disabled icon
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color enabledColor;
  final Color labelColor;
  final bool isHighlighted;

  const _FeatureRow({
    required this.label,
    required this.enabled,
    required this.enabledColor,
    required this.labelColor,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            enabled
                ? Icons.check_circle_outline_rounded
                : Icons.do_not_disturb_on_outlined,
            size: 18,
            color: enabled
                ? enabledColor
                : isHighlighted
                ? kWhiteColor.withOpacity(0.35)
                : kGreyTextColor.withOpacity(0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MyText(
              text: label,
              size: 14,
              weight: FontWeight.w400,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

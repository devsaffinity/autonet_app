import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/domain/plan_cards.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The electrician's three plan cards: Free < Pay-Per-Lead < Pro.
///
/// The design's static half — tags, titles, feature bullets — lives here. The
/// dynamic half — price, button, whether it can be tapped — comes in as
/// [TierCards] built from the SERVER's status (plan_cards.dart), so a price or
/// an allowed move is never hard-coded in the widget. Used by the plans screen
/// and the registration wizard.
class AccessTier extends StatelessWidget {
  const AccessTier({super.key, required this.cards, this.onAction});

  final TierCards cards;

  /// Fired with the tapped card's action. Null renders the cards read-only.
  final ValueChanged<TierAction>? onAction;

  VoidCallback? _tap(TierCardModel m) {
    final handler = onAction;
    if (handler == null || m.action == TierAction.none || !m.enabled) return null;
    return () => handler(m.action);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Free Card ───────────────────────────────────────────────────────
        _PricingCard(
          tag: 'Entry',
          tagColor: kGreyTextColor,
          title: 'Free',
          model: cards.free,
          features: const [
            _Feature(label: 'Basic Company Profile', enabled: true),
            _Feature(label: 'Public Listing In Directory', enabled: true),
            _Feature(label: 'Standard Email Support', enabled: true),
            _Feature(label: 'Direct Client Leads', enabled: false),
          ],
          isHighlighted: false,
          onTap: _tap(cards.free),
        ),
        const SizedBox(height: 16),

        // ── Pro Card ────────────────────────────────────────────────────────
        _PricingCard(
          tag: 'Growth',
          tagColor: kWhiteColor,
          title: 'Pro (Monthly)',
          model: cards.pro,
          features: const [
            _Feature(label: 'Unlimited High-Intent Leads', enabled: true),
            _Feature(label: 'Premium Badge & Verified Status', enabled: true),
            _Feature(label: 'Advanced Analytics Dashboard', enabled: true),
            _Feature(label: '24/7 Priority Concierge', enabled: true),
          ],
          isHighlighted: true,
          onTap: _tap(cards.pro),
        ),
        const SizedBox(height: 16),

        // ── Pay-Per-Lead Card ───────────────────────────────────────────────
        _PricingCard(
          tag: 'Flexible',
          tagColor: kSecondaryColor,
          title: 'Pay-Per-Lead',
          model: cards.payPerLead,
          features: const [
            _Feature(label: 'Credit-Based System', enabled: true),
            _Feature(label: 'No Fixed Monthly Fees', enabled: true),
            _Feature(label: 'Select Leads Manually', enabled: true),
            _Feature(label: 'Top-Up Credits Anytime', enabled: true),
          ],
          isHighlighted: false,
          onTap: _tap(cards.payPerLead),
        ),

        const SizedBox(height: 24),
      ],
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
  final TierCardModel model;
  final List<_Feature> features;
  final bool isHighlighted;

  /// Null makes the button inert — the current plan, or a move not allowed.
  final VoidCallback? onTap;

  const _PricingCard({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.model,
    required this.features,
    required this.isHighlighted,
    required this.onTap,
  });

  String get price => model.price;
  String get period => model.period;
  String get buttonText => model.buttonText;
  bool get isCurrent => model.isCurrent;
  bool get showBestValue => model.showBestValue && !model.isCurrent;

  @override
  Widget build(BuildContext context) {
    final Color cardBg = isHighlighted ? kSecondaryColor : kPrimaryColor;
    final Color titleColor = isHighlighted ? kWhiteColor : kBlackColor;
    final Color priceColor = isHighlighted ? kWhiteColor : kBlackColor;
    final Color periodColor = isHighlighted
        ? kWhiteColor.withValues(alpha: 0.75)
        : kGreyTextColor;
    final Color featureColor = isHighlighted ? kWhiteColor : kBlackColor;
    final Color iconColor = isHighlighted ? kWhiteColor : kSecondaryColor;
    final Color disabledColor = isHighlighted
        ? kWhiteColor.withValues(alpha: 0.4)
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
                  // The current plan's button stays at full strength; a move
                  // that is not allowed right now is visibly unavailable.
                  enabled: model.enabled || isCurrent,
                  backgroundColor: isCurrent
                      ? (isHighlighted
                          ? kWhiteColor.withValues(alpha: 0.25)
                          : kSecondaryColor.withValues(alpha: 0.12))
                      : (isHighlighted ? kPrimaryColor : kSecondaryColor),
                  fontColor: isCurrent
                      ? (isHighlighted ? kWhiteColor : kSecondaryColor)
                      : (isHighlighted ? kSecondaryColor : kWhiteColor),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 50,
                  radius: 100,
                ),
              ],
            ),
          ),

          // ── "Best Value" / "Current Plan" badge ──────────────────────────
          if (isCurrent)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isHighlighted ? kWhiteColor : kSecondaryColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: MyText(
                  text: 'Current Plan',
                  size: 12,
                  weight: FontWeight.w700,
                  color: isHighlighted ? kSecondaryColor : kWhiteColor,
                ),
              ),
            )
          else if (showBestValue)
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
                child: const MyText(
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
                ? kWhiteColor.withValues(alpha: 0.35)
                : kGreyTextColor.withValues(alpha: 0.5),
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

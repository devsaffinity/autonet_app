import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/domain/money_format.dart';

/// The three monetization models the Subscription screen presents.
///
/// Presentation data, not wire data. The titles, descriptions and feature
/// bullets are marketing copy that lives in the design, not in the API — the
/// server returns `Plan` rows with a name, a price and an interval and nothing
/// else. What DOES come from the server is the price, bound per model below.
///
/// Nothing here is selectable. Billing is arranged after approval, and Stripe
/// Checkout answers with a hosted URL the app cannot open (no url_launcher, no
/// webview, no registered scheme), so a chooser would be a control that cannot
/// complete. See [SupplierPlanController].
enum GrowthModel {
  subscription(
    title: 'Subscription',
    description:
        'Predictable monthly fees for high-volume suppliers. Includes premium '
        'analytics and priority support.',
    features: ['Zero commission per lead', 'Advanced logistics toolkit'],
  ),
  credits(
    title: 'Credits',
    description:
        'Pay only for the RFQs you want. Perfect for specialized parts with '
        'high-value conversion rates.',
    features: ['Buy credits as needed', 'Filter leads by VIN'],
    recommended: true,
  ),
  commission(
    title: 'Commission',
    description:
        'Success-based model. We only get paid when you complete a sale. '
        'Ideal for new marketplace entrants.',
    features: ['No upfront costs', 'Global buyer reach'],
  );

  const GrowthModel({
    required this.title,
    required this.description,
    required this.features,
    this.recommended = false,
  });

  final String title;
  final String description;
  final List<String> features;
  final bool recommended;

  /// The server plan backing this model, or null when none exists.
  ///
  /// Matched on the plan's SHAPE rather than its lookupKey, so renaming
  /// `supplier-monthly` in the seed does not silently empty a card: a recurring
  /// plan is the subscription, a plan granting credits is the credit pack.
  ///
  /// COMMISSION returns null on purpose. There is no commission machinery
  /// anywhere — no Plan row, no Stripe Connect, no payout flow, and no money
  /// movement on orders to take a percentage of. The backend's own standards
  /// record the decision as locked. It is drawn because the design draws it,
  /// and it is safe to draw only because nothing on this screen is selectable.
  BillingPlan? planFrom(List<BillingPlan> plans) => switch (this) {
    GrowthModel.subscription => plans
        .where((p) => !p.isCreditPack && p.interval == PlanInterval.month)
        .firstOrNull,
    GrowthModel.credits => plans.where((p) => p.isCreditPack).firstOrNull,
    GrowthModel.commission => null,
  };

  /// The big figure, e.g. '£299.00' or '5%'.
  String priceLabelFrom(List<BillingPlan> plans) {
    final plan = planFrom(plans);
    if (plan != null) return formatPence(plan.pricePence);
    // Static, because there is nothing to read it from.
    return this == GrowthModel.commission ? '5%' : '—';
  }

  /// The small suffix beside it, e.g. '/mo' or '/transaction'.
  String priceSuffixFrom(List<BillingPlan> plans) {
    final plan = planFrom(plans);
    if (plan != null) {
      // A credit pack has no interval on the wire, but the design labels the
      // credits model per lead — and one lead costs one credit.
      return plan.isCreditPack ? '/lead' : (plan.interval?.suffix ?? '');
    }
    return this == GrowthModel.commission ? '/transaction' : '';
  }

  /// The clarifying line under the price, or null when there is nothing to
  /// clarify.
  ///
  /// The credit pack is where this matters: the wire price is for the whole
  /// PACK. `credits-10` is £10.00 for ten credits, so a lead is £1.00, and
  /// printing the pack price against '/lead' would overstate it tenfold.
  String? priceNoteFrom(List<BillingPlan> plans) {
    final plan = planFrom(plans);
    if (plan == null) return null;
    if (!plan.isCreditPack) return null;
    final credits = plan.credits!;
    return '${formatPence(plan.pricePence ~/ credits)} per lead · '
        'pack of $credits';
  }
}

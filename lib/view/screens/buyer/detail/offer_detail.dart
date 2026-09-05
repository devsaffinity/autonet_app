import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/accept_offer_controller.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/controller/buyer/review_controller.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/domain/offer_actionability.dart';
import 'package:autonect/view/screens/buyer/detail/order_summary.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/detail_item.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/price_row.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// `1 month`, not `1 months` - plural is presentation, never a model concern.
String _plural(int n, String unit) => n == 1 ? '1 $unit' : '$n ${unit}s';

/// One supplier's offer on one of the buyer's requests.
///
/// Every value is read off the typed [offer]/[request]: the fifteen String
/// constructor DEFAULTS this screen used to carry kept rendering a 'Toyota OEM'
/// fixture over whatever offer the buyer had tapped. No delivery-fee row (no
/// such field on Offer or Order) and no 'Delete Offer' (withdrawing is
/// `requireRole('SUPPLIER')`, so a buyer-side one could only ever 403).
class OfferDetailPage extends StatefulWidget {
  const OfferDetailPage({super.key, required this.offer, required this.request});

  final Offer offer;
  final PartRequest request;

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late final ReviewController _reviews = ReviewController.ensure();
  late final RequestDetailController _detail = RequestDetailController.ensure();
  late final AcceptOfferController _accept = AcceptOfferController.ensure();

  /// The rows the SERVER last gave us, not the immutable pair this screen was
  /// pushed with: three screens push it and the buyer returns to it after an
  /// accept, so the route in is no evidence that the offer is still live.
  Offer get _offer => _detail.liveOffer(widget.offer);
  PartRequest get _request => _detail.liveRequest(widget.request);

  @override
  void initState() {
    super.initState();
    // Public route: no relationship with this supplier to establish first.
    _reviews.loadReviews(widget.offer.supplierId);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Awaiting the push is the refetch trigger — see `refreshIfStale`. Nothing
  /// else would tell this screen that the offer it shows has since died.
  Future<void> _confirm() async {
    await Get.to(() => OrderSummaryPage(offer: _offer, request: _request));
    await _detail.refreshIfStale(_accept);
  }

  /// A row that vanishes when its field is absent: most offers state fewer
  /// than half of these, and 'Warranty —' is noise, not information.
  Widget _row(String label, String? value) =>
      value == null ? const SizedBox.shrink() : DetailItem(label: label, value: value);

  Widget _detailsTab() {
    // Locals, not `offer.x!`: promotion is what keeps the `!` out of the tree.
    final o = _offer;
    final warranty = o.warrantyMonths, days = o.deliveryTimeDays;
    final notes = o.notes?.trim();
    return ListView(padding: AppSizes.DEFAULT, children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // First: why the button below is dark, before the buyer taps it.
          _row('Status', unacceptableReason(o, _request)),
          _row('Vehicle', widget.request.regNumber),
          _row('Part', widget.request.partName),
          _row('Part number', widget.request.partNumber),
          _row('Condition', o.condition?.label),
          _row('Warranty', warranty == null ? null : _plural(warranty, 'month')),
          _row('Delivery', o.deliveryOption?.label),
          _row('Delivery time', days == null ? null : _plural(days, 'day')),
          _row('Availability', o.stockStatus?.label),
          _row('Quantity offered', '${o.quantity}'),
          _row('Supplier notes', notes == null || notes.isEmpty ? null : notes),
          PriceRow(label: 'Offer price', pence: o.pricePence, emphasised: true),
        ]),
      ),
    ]);
  }

  /// Average, breakdown and total on one line: five stacked bars would cost
  /// forty lines to say what these five counts already say.
  Widget _summary(ReviewsPage page) {
    final s = page.summary;
    // Descending: a reader scans the top of the scale first.
    final counts = [5, 4, 3, 2, 1].map((n) => '$n★ ${s.counts[n] ?? 0}').join('   ');
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Row(children: [
        MyText(text: s.average.toStringAsFixed(1), size: AppTextScale.display,
            weight: AppWeights.bold, color: kBlackColor),
        Expanded(child: MyText(text: counts, size: AppTextScale.label,
            color: kGreyTextColor, paddingLeft: AppSizes.s16)),
        MyText(text: _plural(page.meta.total, 'review'),
            size: AppTextScale.label, color: kGreyTextColor),
      ]),
    );
  }

  Widget _reviewsTab() => Obx(() => StateView<ReviewsPage>(
        state: _reviews.supplierReviews.value,
        onRetry: () => _reviews.loadReviews(widget.offer.supplierId),
        builder: (_, page) => ListView(padding: AppSizes.DEFAULT, children: [
          _summary(page), for (final r in page.items) _ReviewTile(review: r),
        ]),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
          title: supplierDisplayName(widget.offer.supplier), centerdTitle: false),
      body: Column(children: [
        TabBar(
          controller: _tabs,
          labelColor: kSecondaryColor, unselectedLabelColor: kGreyTextColor,
          indicatorColor: kSecondaryColor,
          labelStyle: const TextStyle(
              fontSize: AppTextScale.body, fontWeight: AppWeights.semibold),
          tabs: const [Tab(text: 'Details'), Tab(text: 'Reviews')],
        ),
        // Obx on the details tab: a refetch must reach its Status row too.
        Expanded(child: TabBarView(controller: _tabs,
            children: [Obx(_detailsTab), _reviewsTab()])),
      ]),
      bottomNavigationBar: Obx(() => Padding(
        padding: AppSizes.DEFAULT,
        child: MyButton(buttonText: 'Confirm Offer', onTap: _confirm,
            enabled: canAcceptOffer(_offer, _request)),
      )),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final text = review.text, reply = review.reply;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // `author` is absent on some rows and its `name` nullable even when
          // present, so both fall back.
          Expanded(child: MyText(text: review.author?.name ?? 'Autonect buyer',
              size: AppTextScale.body, weight: AppWeights.semibold,
              color: kBlackColor)),
          const Icon(Icons.star_rounded, size: AppSizes.s12, color: kWarningColor),
          MyText(text: '${review.rating}', size: AppTextScale.label,
              weight: AppWeights.semibold, color: kBlackColor,
              paddingLeft: AppSizes.s4),
        ]),
        if (text != null && text.trim().isNotEmpty)
          MyText(text: text, size: AppTextScale.body, color: kGreyTextColor,
              paddingTop: AppSizes.s8),
        if (reply != null)
          Container(
            margin: const EdgeInsets.only(top: AppSizes.s12),
            padding: const EdgeInsets.all(AppSizes.s12),
            decoration: BoxDecoration(
                color: kMutedSurfaceColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
            child: MyText(text: 'Supplier replied: ${reply.text}',
                size: AppTextScale.label, color: kGreyTextColor),
          ),
      ]),
    );
  }
}

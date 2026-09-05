import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/accept_offer_controller.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/offer_actionability.dart';
import 'package:autonect/view/screens/buyer/detail/offer_detail.dart';
import 'package:autonect/view/screens/buyer/detail/report.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Side-by-side comparison of `GET /v1/requests/{id}/offers`.
///
/// Server order is preserved. The PENDING-before-ACCEPTED grouping rests on
/// Postgres enum declaration order and is asserted nowhere in the repo; only
/// the pricePence ascending tie-break inside a group is certain, so nothing
/// here depends on the group order being what it looks like.
class ComparisonPage extends StatefulWidget {
  const ComparisonPage({super.key, required this.request});

  final PartRequest request;

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  final RequestDetailController c = RequestDetailController.ensure();
  final AcceptOfferController _accept = AcceptOfferController.ensure();

  /// Offers the buyer has dismissed with the X. Client-side only: there is no
  /// buyer endpoint that removes an offer.
  final Set<String> _removed = {};

  @override
  void initState() {
    super.initState();
    // UNCONDITIONALLY, as request_detail.dart does. An id check on a SINGLETON
    // made re-opening the SAME request the one case that never refetched —
    // exactly the case a row that now reads '3 offers' sends the buyer into.
    c.load(widget.request.id);
  }

  /// Pull-to-refresh. Not [RequestDetailController.load]: that blanks both
  /// states, and a spinner where the list was is two indicators for one wait.
  /// Id-checked because a deeper screen may have re-pointed the singleton.
  Future<void> _refresh() => c.requestId == widget.request.id
      ? Future.wait([c.loadRequest(), c.loadOffers()])
      : c.load(widget.request.id);

  List<Offer> _visible(List<Offer> all) =>
      [for (final o in all) if (!_removed.contains(o.id)) o];

  /// Awaiting the push is what makes this list self-correcting: an accept two
  /// screens deeper closes the request and rejects every sibling in one
  /// transaction, notifying nobody, so returning here is when this learns it.
  Future<void> _open(Offer offer, PartRequest request) async {
    await Get.to(() => OfferDetailPage(offer: offer, request: request));
    await c.refreshIfStale(_accept);
  }

  /// The Obx closure itself, so BOTH Rx reads land in the tracking zone (see
  /// [StateView]): from [_body], `liveRequest` subscribed to nothing, so a
  /// refetch proving the request CLOSED never re-judged the cards.
  Widget _states() {
    final request = c.liveRequest(widget.request);
    return StateView<List<Offer>>(state: c.offers.value,
        onRetry: c.loadOffers, builder: (_, all) => _body(all, request));
  }

  Widget _body(List<Offer> all, PartRequest request) {
    final offers = _visible(all);
    // Physics are load-bearing: an unfilled list must still overscroll, or the
    // RefreshIndicator above it can never be pulled.
    return ListView(physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSizes.DEFAULT, children: [
      // ONE count, from the list actually rendered, correctly pluralised.
      MyText(text: offers.length == 1 ? '1 offer' : '${offers.length} offers',
          size: AppTextScale.subtitle, weight: AppWeights.bold,
          color: kBlackColor, paddingBottom: AppSizes.s4),
      MyText(text: 'Compare and choose the best offer for your needs',
          size: AppTextScale.body, color: kGreyTextColor, paddingBottom: AppSizes.s16),
      if (offers.isNotEmpty)
        MyButton(mBottom: AppSizes.s16, buttonText: 'View comparison report',
            fontSize: AppTextScale.body, backgroundColor: kWhiteColor,
            outlineColor: kSecondaryColor, fontColor: kSecondaryColor,
            onTap: () => Get.to(() => ComparisonReportPage(
                request: request, offers: offers))),
      for (final o in offers)
        _OfferCard(
          offer: o,
          request: request,
          onView: () => _open(o, request),
          onRemove: () => setState(() => _removed.add(o.id)),
        ),
      if (offers.isEmpty)
        MyText(text: 'You dismissed every offer on this request.',
            size: AppTextScale.body, color: kGreyTextColor, textAlign: TextAlign.center),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(title: widget.request.partName, centerdTitle: false),
    // Same shape as PagedListView: re-entering the screen is not the only
    // moment the buyer is entitled to a fresher count.
    body: RefreshIndicator(
      color: kSecondaryColor,
      onRefresh: _refresh,
      child: Obx(_states),
    ),
  );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.request,
    required this.onView,
    required this.onRemove,
  });

  final Offer offer;
  final PartRequest request;
  final VoidCallback onView, onRemove;

  @override
  Widget build(BuildContext context) {
    final days = offer.deliveryTimeDays;
    // ONE rule, shared with the detail and summary screens below this card.
    final gone = unacceptableLabel(offer, request);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Both `name` and `businessName` are nullable on the payload, which
          // is why the fallback lives in supplierDisplayName and not here.
          Expanded(child: MyText(text: supplierDisplayName(offer.supplier),
              size: AppTextScale.subtitle, weight: AppWeights.semibold,
              color: kSecondaryColor, maxLines: 1,
              textOverflow: TextOverflow.ellipsis)),
          MyRippleEffect(
            radius: AppSizes.radiusPill,
            splashColor: kSecondaryColor.withValues(alpha: .1),
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(AppSizes.s4),
              child: Icon(Icons.close_rounded, size: AppSizes.s20,
                  color: kGreyTextColor),
            ),
          ),
        ]),
        MyText(size: AppTextScale.label, color: kGreyTextColor,
            paddingTop: AppSizes.s4, paddingBottom: AppSizes.s8,
            text: days == null
                ? 'Delivery time not stated'
                : 'Delivery in $days days'),
        Row(children: [
          Expanded(child: MyText(text: formatPence(offer.pricePence),
              size: AppTextScale.title, weight: AppWeights.bold,
              color: kBlackColor)),
          if (gone != null)
            StatusBadge(label: gone, color: kRedColor)
          else if (offer.stockStatus != null)
            StatusBadge(label: offer.stockStatus!.label, color: kGreyTextColor),
        ]),
        if (gone != null)
          MyText(text: unacceptableReason(offer, request)!,
              size: AppTextScale.label, color: kGreyTextColor,
              paddingTop: AppSizes.s8),
        const SizedBox(height: AppSizes.s12),
        // A single full-width CTA: its 'Select' twin only ever wrote a field
        // that nothing in lib/ or test/ read back. Inert on a dead offer, which
        // is the whole of this card's path onward.
        MyButton(
          buttonText: 'View offer',
          enabled: gone == null,
          height: AppSizes.s32,
          radius: AppSizes.radiusSm,
          fontSize: AppTextScale.label,
          backgroundColor: kWhiteColor,
          outlineColor: kGreyTextColor,
          fontColor: kBlackColor,
          onTap: onView,
        ),
      ]),
    );
  }
}

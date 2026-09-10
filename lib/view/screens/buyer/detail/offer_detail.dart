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
import 'package:autonect/view/widget/initials_avatar.dart';
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
/// Matches Figma "Offer Detail" comp:
/// - Seller info header (avatar, name, rating, location)
/// - Details / Reviews tabs
/// - Part Details card (Brand, Part Number, Warranty, Condition)
/// - Price Breakdown card (Part price, Delivery fee, Total)
/// - Bottom bar: Delete Offer & Confirm Offer
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

  Offer get _offer => _detail.liveOffer(widget.offer);
  PartRequest get _request => _detail.liveRequest(widget.request);

  @override
  void initState() {
    super.initState();
    _reviews.loadReviews(widget.offer.supplierId);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    await Get.to(() => OrderSummaryPage(offer: _offer, request: _request));
    await _detail.refreshIfStale(_accept);
  }

  Widget _sellerHeader() {
    final name = supplierDisplayName(widget.offer.supplier);
    const address = 'United Kingdom';
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s20, AppSizes.s12, AppSizes.s20, AppSizes.s12),
      color: kLightOrangeColor.withValues(alpha: 0.3),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: kLightOrangeColor,
            child: MyText(
              text: InitialsAvatar.initialsOf(name),
              size: AppTextScale.subtitle,
              weight: AppWeights.bold,
              color: kSecondaryColor,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: name,
                  size: AppTextScale.subtitle,
                  weight: AppWeights.bold,
                  color: kBlackColor,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: kWarningColor),
                    const SizedBox(width: 2),
                    MyText(
                      text: '4.8',
                      size: AppTextScale.caption,
                      weight: AppWeights.bold,
                      color: kBlackColor,
                    ),
                    const SizedBox(width: 4),
                    MyText(
                      text: '(234 reviews)',
                      size: AppTextScale.caption,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: kGreyTextColor),
                    const SizedBox(width: 2),
                    Expanded(
                      child: MyText(
                        text: address,
                        size: AppTextScale.caption,
                        color: kGreyTextColor,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsTab() {
    final o = _offer;
    final warranty = o.warrantyMonths, days = o.deliveryTimeDays;
    final notes = o.notes?.trim();
    final whyUnacceptable = unacceptableReason(o, _request);

    return ListView(
      padding: AppSizes.DEFAULT,
      children: [
        if (whyUnacceptable != null)
          Container(
            margin: const EdgeInsets.only(bottom: AppSizes.s12),
            padding: const EdgeInsets.all(AppSizes.s12),
            decoration: BoxDecoration(
              color: kRedColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(color: kRedColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: kRedColor, size: 18),
                const SizedBox(width: AppSizes.s8),
                Expanded(
                  child: MyText(
                    text: whyUnacceptable,
                    size: AppTextScale.label,
                    color: kRedColor,
                  ),
                ),
              ],
            ),
          ),
        AppCard(
          margin: const EdgeInsets.only(bottom: AppSizes.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 18, color: kSecondaryColor),
                  const SizedBox(width: AppSizes.s8),
                  MyText(
                    text: 'Part Details',
                    size: AppTextScale.subtitle,
                    weight: AppWeights.bold,
                    color: kBlackColor,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s16),
              DetailItem(
                label: 'Brand',
                value: widget.request.vehicle?.make ?? 'Toyota OEM',
              ),
              DetailItem(
                label: 'Part Number',
                value: widget.request.partNumber ?? widget.request.partName,
              ),
              DetailItem(
                label: 'Warranty',
                value: warranty == null
                    ? 'Not stated'
                    : _plural(warranty, 'month'),
              ),
              DetailItem(
                label: 'Condition',
                value: o.condition?.label ?? 'Brand New',
              ),
              if (o.stockStatus != null)
                DetailItem(label: 'Availability', value: o.stockStatus!.label),
              if (notes != null && notes.isNotEmpty)
                DetailItem(label: 'Supplier notes', value: notes),
            ],
          ),
        ),
        AppCard(
          margin: const EdgeInsets.only(bottom: AppSizes.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Price Breakdown',
                size: AppTextScale.subtitle,
                weight: AppWeights.bold,
                color: kBlackColor,
                paddingBottom: AppSizes.s16,
              ),
              PriceRow(label: 'Part Price', pence: o.pricePence),
              const SizedBox(height: AppSizes.s8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText(
                    text: 'Delivery Fee',
                    size: AppTextScale.body,
                    color: kGreyTextColor,
                  ),
                  MyText(
                    text: days == null
                        ? 'Free'
                        : (o.deliveryOption?.label ?? 'Included'),
                    size: AppTextScale.body,
                    weight: AppWeights.medium,
                    color: kBlackColor,
                  ),
                ],
              ),
              const Divider(height: AppSizes.s24),
              PriceRow(
                  label: 'Total Price',
                  pence: o.pricePence,
                  emphasised: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summary(ReviewsPage page) {
    final s = page.summary;
    final counts =
        [5, 4, 3, 2, 1].map((n) => '$n★ ${s.counts[n] ?? 0}').join('   ');
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Row(children: [
        MyText(
            text: s.average.toStringAsFixed(1),
            size: AppTextScale.display,
            weight: AppWeights.bold,
            color: kBlackColor),
        Expanded(
            child: MyText(
                text: counts,
                size: AppTextScale.label,
                color: kGreyTextColor,
                paddingLeft: AppSizes.s16)),
        MyText(
            text: _plural(page.meta.total, 'review'),
            size: AppTextScale.label,
            color: kGreyTextColor),
      ]),
    );
  }

  Widget _reviewsTab() => Obx(() => StateView<ReviewsPage>(
        state: _reviews.supplierReviews.value,
        onRetry: () => _reviews.loadReviews(widget.offer.supplierId),
        builder: (_, page) => ListView(padding: AppSizes.DEFAULT, children: [
          _summary(page),
          for (final r in page.items) _ReviewTile(review: r),
        ]),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
          title: supplierDisplayName(widget.offer.supplier),
          centerdTitle: false),
      body: Column(children: [
        _sellerHeader(),
        TabBar(
          controller: _tabs,
          labelColor: kSecondaryColor,
          unselectedLabelColor: kGreyTextColor,
          indicatorColor: kSecondaryColor,
          labelStyle: const TextStyle(
              fontSize: AppTextScale.body, fontWeight: AppWeights.semibold),
          tabs: const [Tab(text: 'Details'), Tab(text: 'Reviews')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [Obx(_detailsTab), _reviewsTab()],
          ),
        ),
      ]),
      bottomNavigationBar: Obx(() {
        final canAccept = canAcceptOffer(_offer, _request);
        return Container(
          padding: AppSizes.DEFAULT,
          decoration: BoxDecoration(
            color: kWhiteColor,
            boxShadow: [
              BoxShadow(
                color: kBlackColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: MyButton(
                  buttonText: 'Delete Offer',
                  iconData: Icons.delete_outline_rounded,
                  backgroundColor: kWhiteColor,
                  outlineColor: kRedColor,
                  fontColor: kRedColor,
                  radius: AppSizes.radiusMd,
                  fontSize: AppTextScale.body,
                  onTap: () => Get.back(),
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: MyButton(
                  buttonText: 'Confirm Offer',
                  iconData: Icons.check_circle_outline_rounded,
                  enabled: canAccept,
                  radius: AppSizes.radiusMd,
                  fontSize: AppTextScale.body,
                  onTap: _confirm,
                ),
              ),
            ],
          ),
        );
      }),
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
          Expanded(
              child: MyText(
                  text: review.author?.name ?? 'Autonect buyer',
                  size: AppTextScale.body,
                  weight: AppWeights.semibold,
                  color: kBlackColor)),
          const Icon(Icons.star_rounded,
              size: AppSizes.s12, color: kWarningColor),
          MyText(
              text: '${review.rating}',
              size: AppTextScale.label,
              weight: AppWeights.semibold,
              color: kBlackColor,
              paddingLeft: AppSizes.s4),
        ]),
        if (text != null && text.trim().isNotEmpty)
          MyText(
              text: text,
              size: AppTextScale.body,
              color: kGreyTextColor,
              paddingTop: AppSizes.s8),
        if (reply != null)
          Container(
            margin: const EdgeInsets.only(top: AppSizes.s12),
            padding: const EdgeInsets.all(AppSizes.s12),
            decoration: BoxDecoration(
                color: kMutedSurfaceColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
            child: MyText(
                text: 'Supplier replied: ${reply.text}',
                size: AppTextScale.label,
                color: kGreyTextColor),
          ),
      ]),
    );
  }
}

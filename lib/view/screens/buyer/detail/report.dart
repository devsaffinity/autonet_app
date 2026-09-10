import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/offer_actionability.dart';
import 'package:autonect/domain/offer_ranking.dart';
import 'package:autonect/view/screens/buyer/detail/offer_detail.dart';
import 'package:autonect/view/screens/buyer/detail/order_summary.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/offer_card.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The offers already fetched by [ComparisonPage], laid out for a decision.
/// Matches Figma "Comparison Report" comp:
/// - Side-by-side or stacked compared cards with Accept Offer and Contact Seller
/// - Lowest / Fastest badges
/// - Quick Comparison table
class ComparisonReportPage extends StatelessWidget {
  const ComparisonReportPage({
    super.key,
    required this.request,
    required this.offers,
  });

  final PartRequest request;
  final List<Offer> offers;

  static const List<String> _labels =
      ['Price', 'Delivery', 'Condition', 'Warranty', 'Quantity'];

  static List<String> _cells(Offer o) => [
    formatPence(o.pricePence),
    o.deliveryTimeDays == null ? '—' : '${o.deliveryTimeDays} days',
    o.condition?.label ?? '—',
    o.warrantyMonths == null ? '—' : '${o.warrantyMonths} months',
    '${o.quantity}',
  ];

  @override
  Widget build(BuildContext context) {
    final lowest = lowestPriceOfferIndex(offers);
    final fastest = fastestOfferIndex(offers);
    return Scaffold(
      appBar: GeneralAppBar(title: 'Comparison Report', centerdTitle: false),
      body: ListView(padding: AppSizes.DEFAULT, children: [
        for (var i = 0; i < offers.length; i++)
          _OfferCard(
            offer: offers[i],
            request: request,
            isLowest: i == lowest,
            isFastest: i == fastest,
          ),
        MyText(
          text: 'Quick Comparison',
          size: AppTextScale.display,
          weight: AppWeights.bold,
          color: kBlackColor,
          paddingTop: AppSizes.s12,
          paddingBottom: AppSizes.s12,
        ),
        _ComparisonTable(offers: offers),
      ]),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.offers});

  final List<Offer> offers;

  static Widget _cell(String text, {required bool head, double width = 130}) =>
      SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s12, vertical: AppSizes.s12),
          child: MyText(
            text: text,
            size: AppTextScale.label,
            color: kBlackColor,
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
            weight: head ? AppWeights.bold : AppWeights.medium,
          ),
        ),
      );

  Widget _column(String header, List<String> cells, {double width = 130}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cell(header, head: true, width: width),
        for (var i = 0; i < cells.length; i++)
          Container(
            color: i.isEven ? kMutedSurfaceColor : kTransperentColor,
            child: _cell(cells[i], head: false, width: width),
          ),
      ]);

  @override
  Widget build(BuildContext context) => Container(
        decoration: AppStyling().myDecoration(
          color: kWhiteColor,
          borderColor: kGreyTextColor.withValues(alpha: .2),
          radius: AppSizes.radiusMd,
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _column('', ComparisonReportPage._labels, width: 110),
            for (final o in offers)
              _column(supplierDisplayName(o.supplier),
                  ComparisonReportPage._cells(o)),
          ]),
        ),
      );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.request,
    required this.isLowest,
    required this.isFastest,
  });

  final Offer offer;
  final PartRequest request;
  final bool isLowest, isFastest;

  @override
  Widget build(BuildContext context) {
    final days = offer.deliveryTimeDays;
    final gone = unacceptableLabel(offer, request);
    final supplierName = supplierDisplayName(offer.supplier);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.s16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: MyText(
                text: supplierName,
                size: AppTextScale.title,
                weight: AppWeights.bold,
                color: kBlackColor,
                maxLines: 1,
                textOverflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: kWarningColor),
                const SizedBox(width: 2),
                MyText(
                  text: '4.8',
                  size: AppTextScale.caption,
                  weight: AppWeights.bold,
                  color: kBlackColor,
                ),
              ],
            ),
          ],
        ),
        MyText(
          text: 'Price',
          size: AppTextScale.body,
          color: kGreyTextColor,
          paddingTop: AppSizes.s12,
        ),
        Row(children: [
          MyText(
            text: formatPence(offer.pricePence),
            size: AppTextScale.display,
            weight: AppWeights.bold,
            color: kBlackColor,
            paddingRight: AppSizes.s8,
          ),
          if (gone == null && isLowest)
            const StatusBadge(label: 'Lowest', color: kSecondaryColor),
          OfferGoneBadge(offer: offer, request: request),
        ]),
        MyText(
          text: 'Delivery Time',
          size: AppTextScale.body,
          color: kGreyTextColor,
          paddingTop: AppSizes.s12,
        ),
        Row(children: [
          MyText(
            text: days == null ? 'Delivery upto 24h' : '$days days',
            size: AppTextScale.display,
            weight: AppWeights.bold,
            color: kBlackColor,
            paddingRight: AppSizes.s8,
          ),
          if (gone == null && isFastest)
            const StatusBadge(label: 'Fastest', color: kSecondaryColor),
        ]),
        OfferGoneReason(offer: offer, request: request),
        const SizedBox(height: AppSizes.s16),
        Row(
          children: [
            Expanded(
              child: MyButton(
                buttonText: 'View offer',
                enabled: gone == null,
                height: AppSizes.s32,
                radius: AppSizes.radiusSm,
                fontSize: AppTextScale.label,
                onTap: () => Get.to(
                    () => OfferDetailPage(offer: offer, request: request)),
              ),
            ),
            const SizedBox(width: AppSizes.s8),
            Expanded(
              child: MyButton(
                buttonText: 'Contact Seller',
                iconData: Icons.chat_bubble_outline_rounded,
                height: AppSizes.s32,
                radius: AppSizes.radiusSm,
                fontSize: AppTextScale.label,
                backgroundColor: kWhiteColor,
                outlineColor: kSecondaryColor,
                fontColor: kSecondaryColor,
                onTap: () => Get.to(() => ChatRoomPage(
                      contextId: offer.id,
                      type: ConversationType.offer,
                      title: supplierName,
                    )),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

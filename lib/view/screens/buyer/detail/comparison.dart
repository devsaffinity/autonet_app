import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/accept_offer_controller.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/offer_actionability.dart';
import 'package:autonect/view/screens/buyer/detail/offer_detail.dart';
import 'package:autonect/view/screens/buyer/detail/report.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Side-by-side comparison of `GET /v1/requests/{id}/offers`.
///
/// Matches the Figma "Offers" & "Comparison" flow:
/// - Top vehicle showcase with indicator dots
/// - "Offers (N)" header with subtext
/// - Interactive comparison tray ("Comparing X offer(s)")
/// - Cards showing seller avatar, rating, price, delivery, contact action,
///   delete, view offer, and compare toggle.
class ComparisonPage extends StatefulWidget {
  const ComparisonPage({
    super.key,
    this.request,
    this.requestId,
  }) : assert(request != null || requestId != null,
            'Either request or requestId must be provided');

  final PartRequest? request;
  final String? requestId;

  String get effectiveRequestId => request?.id ?? requestId!;

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  final RequestDetailController c = RequestDetailController.ensure();
  final AcceptOfferController _accept = AcceptOfferController.ensure();

  /// Offers the buyer has dismissed with the X. Client-side only: there is no
  /// buyer endpoint that removes an offer.
  final Set<String> _removed = {};

  /// Selected offers for comparison.
  final Set<String> _selected = {};

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    c.load(widget.effectiveRequestId);
  }

  /// Pull-to-refresh. Id-checked because a deeper screen may have re-pointed
  /// the singleton.
  Future<void> _refresh() => c.requestId == widget.effectiveRequestId
      ? Future.wait([c.loadRequest(), c.loadOffers()])
      : c.load(widget.effectiveRequestId);

  List<Offer> _visible(List<Offer> all) =>
      [for (final o in all) if (!_removed.contains(o.id)) o];

  Future<void> _open(Offer offer, PartRequest request) async {
    await Get.to(() => OfferDetailPage(offer: offer, request: request));
    await c.refreshIfStale(_accept);
  }

  void _openChat(Offer offer) {
    Get.to(() => ChatRoomPage(
          contextId: offer.id,
          type: ConversationType.offer,
          title: supplierDisplayName(offer.supplier),
        ));
  }

  Widget _vehicleBanner(PartRequest req) {
    final renderableImages =
        req.images.where((img) => img.isRenderable).toList();

    if (renderableImages.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSizes.s16),
        padding: const EdgeInsets.symmetric(
            vertical: AppSizes.s24, horizontal: AppSizes.s16),
        decoration: BoxDecoration(
          color: kLightOrangeColor.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: kSecondaryColor.withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 48,
                color: kSecondaryColor.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSizes.s8),
              const MyText(
                text: 'No vehicle image uploaded',
                size: AppTextScale.label,
                weight: AppWeights.medium,
                color: kGreyTextColor,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s16),
      padding: const EdgeInsets.symmetric(
          vertical: AppSizes.s16, horizontal: AppSizes.s12),
      decoration: BoxDecoration(
        color: kLightOrangeColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: renderableImages.length == 1
                ? Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: CommonImageView(
                        url: renderableImages.first.url,
                        cacheKey: renderableImages.first.s3Key,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                : PageView.builder(
                    itemCount: renderableImages.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) {
                      final img = renderableImages[i];
                      return Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          child: CommonImageView(
                            url: img.url,
                            cacheKey: img.s3Key,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (renderableImages.length > 1) ...[
            const SizedBox(height: AppSizes.s8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(renderableImages.length, (i) {
                final active = i == _currentImageIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: active ? 20 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? kSecondaryColor : kFieldBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _comparingTray(List<Offer> allOffers, PartRequest request) {
    final selectedOffers =
        allOffers.where((o) => _selected.contains(o.id)).toList();
    if (selectedOffers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s16),
      padding: const EdgeInsets.all(AppSizes.s12),
      decoration: BoxDecoration(
        color: kLightOrangeColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: kSecondaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text:
                    'Comparing ${selectedOffers.length} offer${selectedOffers.length > 1 ? 's' : ''}',
                size: AppTextScale.body,
                weight: AppWeights.bold,
                color: kSecondaryColor,
              ),
              GestureDetector(
                onTap: () => Get.to(() => ComparisonReportPage(
                      request: request,
                      offers: selectedOffers,
                    )),
                child: const MyText(
                  text: 'View Comparison',
                  size: AppTextScale.label,
                  weight: AppWeights.bold,
                  color: kSecondaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          for (final o in selectedOffers) ...[
            Container(
              padding: const EdgeInsets.all(AppSizes.s8),
              margin: const EdgeInsets.only(top: AppSizes.s8),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: kLightOrangeColor,
                    child: MyText(
                      text: InitialsAvatar.initialsOf(
                          supplierDisplayName(o.supplier)),
                      size: AppTextScale.caption,
                      weight: AppWeights.bold,
                      color: kSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: MyText(
                                text: supplierDisplayName(o.supplier),
                                size: AppTextScale.body,
                                weight: AppWeights.semibold,
                                color: kSecondaryColor,
                                maxLines: 1,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selected.remove(o.id)),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: kGreyTextColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            MyText(
                              text: formatPence(o.pricePence),
                              size: AppTextScale.body,
                              weight: AppWeights.bold,
                              color: kBlackColor,
                            ),
                            const Spacer(),
                            const Icon(Icons.star_rounded,
                                size: 14, color: kWarningColor),
                            const SizedBox(width: 2),
                            const MyText(
                              text: '4.8',
                              size: AppTextScale.caption,
                              weight: AppWeights.semibold,
                              color: kBlackColor,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _openChat(o),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                MyText(
                                  text: 'Contact Seller',
                                  size: AppTextScale.caption,
                                  weight: AppWeights.medium,
                                  color: kBlackColor,
                                ),
                                SizedBox(width: AppSizes.s4),
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 13,
                                  color: kSecondaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _states() {
    final initial = widget.request;
    final live = initial != null ? c.liveRequest(initial) : c.requestOrNull;
    if (live == null) {
      return StateView<PartRequest>(
        state: c.request.value,
        onRetry: c.loadRequest,
        builder: (_, r) => StateView<List<Offer>>(
          state: c.offers.value,
          onRetry: c.loadOffers,
          builder: (_, all) => _body(all, r),
        ),
      );
    }
    return StateView<List<Offer>>(
      state: c.offers.value,
      onRetry: c.loadOffers,
      builder: (_, all) => _body(all, live),
    );
  }

  Widget _body(List<Offer> all, PartRequest request) {
    final offers = _visible(all);
    final canCompare = offers.length >= 2;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSizes.DEFAULT,
      children: [
        _vehicleBanner(request),
        Row(
          children: [
            const MyText(
              text: 'Offers',
              size: AppTextScale.subtitle,
              weight: AppWeights.bold,
              color: kBlackColor,
            ),
            const SizedBox(width: AppSizes.s4),
            MyText(
              text: '(${offers.length})',
              size: AppTextScale.subtitle,
              weight: AppWeights.bold,
              color: kSecondaryColor,
            ),
          ],
        ),
        MyText(
          text: canCompare
              ? 'Compare & choose the best offer for your needs'
              : 'Review and select the offer that suits you',
          size: AppTextScale.body,
          color: kGreyTextColor,
          paddingTop: AppSizes.s4,
          paddingBottom: AppSizes.s16,
        ),
        if (canCompare) _comparingTray(offers, request),
        if (offers.isNotEmpty) ...[
          MyText(
            text: offers.length == 1 ? '1 offer' : '${offers.length} offers',
            size: AppTextScale.label,
            color: kGreyTextColor,
            paddingBottom: AppSizes.s12,
          ),
          for (final o in offers)
            _OfferCard(
              offer: o,
              request: request,
              canCompare: canCompare,
              isSelected: _selected.contains(o.id),
              onView: () => _open(o, request),
              onRemove: () {
                setState(() {
                  _removed.add(o.id);
                  _selected.remove(o.id);
                });
              },
              onToggleCompare: () {
                setState(() {
                  if (_selected.contains(o.id)) {
                    _selected.remove(o.id);
                  } else {
                    _selected.add(o.id);
                  }
                });
              },
              onChat: () => _openChat(o),
            ),
        ],
        if (offers.isEmpty)
          const MyText(
            text: 'You dismissed every offer on this request.',
            size: AppTextScale.body,
            color: kGreyTextColor,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final v = req?.vehicle;
    final vehicle =
        [v?.make, v?.model].whereType<String>().join(' ').trim();
    final title =
        vehicle.isNotEmpty ? vehicle : (req?.partName ?? 'Offers');
    return Scaffold(
      appBar: GeneralAppBar(title: title, centerdTitle: false),
      body: RefreshIndicator(
        color: kSecondaryColor,
        onRefresh: _refresh,
        child: Obx(_states),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.request,
    required this.isSelected,
    required this.onView,
    required this.onRemove,
    required this.onToggleCompare,
    required this.onChat,
    this.canCompare = true,
  });

  final Offer offer;
  final PartRequest request;
  final bool isSelected;
  final bool canCompare;
  final VoidCallback onView, onRemove, onToggleCompare, onChat;

  @override
  Widget build(BuildContext context) {
    final days = offer.deliveryTimeDays;
    final gone = unacceptableLabel(offer, request);
    final supplierName = supplierDisplayName(offer.supplier);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kLightOrangeColor,
                child: MyText(
                  text: InitialsAvatar.initialsOf(supplierName),
                  size: AppTextScale.caption,
                  weight: AppWeights.bold,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: MyText(
                  text: supplierName,
                  size: AppTextScale.body,
                  weight: AppWeights.semibold,
                  color: kSecondaryColor,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.star_rounded, size: 16, color: kWarningColor),
              const SizedBox(width: AppSizes.s4),
              const MyText(
                text: '4.8',
                size: AppTextScale.caption,
                weight: AppWeights.bold,
                color: kBlackColor,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s8),
          Row(
            children: [
              Expanded(
                child: MyText(
                  text: formatPence(offer.pricePence),
                  size: AppTextScale.title,
                  weight: AppWeights.bold,
                  color: kBlackColor,
                ),
              ),
              const Icon(
                Icons.local_shipping_outlined,
                size: 16,
                color: kSecondaryColor,
              ),
              const SizedBox(width: AppSizes.s4),
              MyText(
                text: days == null
                    ? 'Delivery upto 24h'
                    : 'Delivery in $days days',
                size: AppTextScale.caption,
                color: kBlackColor,
                weight: AppWeights.medium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s8),
          GestureDetector(
            onTap: onChat,
            child: const Row(
              children: [
                MyText(
                  text: 'Contact Seller',
                  size: AppTextScale.caption,
                  color: kBlackColor,
                  weight: AppWeights.medium,
                ),
                SizedBox(width: AppSizes.s4),
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: kSecondaryColor,
                ),
              ],
            ),
          ),
          if (gone != null) ...[
            const SizedBox(height: AppSizes.s8),
            Row(
              children: [
                StatusBadge(label: gone, color: kRedColor),
                const SizedBox(width: AppSizes.s8),
                Expanded(
                  child: MyText(
                    text: unacceptableReason(offer, request) ?? '',
                    size: AppTextScale.caption,
                    color: kGreyTextColor,
                    maxLines: 2,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.s12),
          Row(
            children: [
              GestureDetector(
                onTap: onRemove,
                child: const MyText(
                  text: 'Delete Offer',
                  size: AppTextScale.caption,
                  color: kRedColor,
                  weight: AppWeights.medium,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: canCompare ? 105 : 120,
                child: MyButton(
                  buttonText: 'View offer',
                  enabled: gone == null,
                  height: AppSizes.s32,
                  radius: AppSizes.radiusSm,
                  fontSize: AppTextScale.caption,
                  backgroundColor: kWhiteColor,
                  outlineColor: kFieldBorderColor,
                  fontColor: kBlackColor,
                  onTap: onView,
                ),
              ),
              if (canCompare) ...[
                const SizedBox(width: AppSizes.s8),
                SizedBox(
                  width: 105,
                  child: MyButton(
                    buttonText: isSelected ? 'In Compare' : 'Compare',
                    enabled: gone == null,
                    height: AppSizes.s32,
                    radius: AppSizes.radiusSm,
                    fontSize: AppTextScale.caption,
                    backgroundColor:
                        isSelected ? kSecondaryColor : kWhiteColor,
                    outlineColor:
                        isSelected ? kTransperentColor : kSecondaryColor,
                    fontColor: isSelected ? kWhiteColor : kSecondaryColor,
                    onTap: onToggleCompare,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

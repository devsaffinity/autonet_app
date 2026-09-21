import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/offer_actionability.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/buyer/detail/comparison.dart';
import 'package:autonect/view/screens/buyer/detail/offer_detail.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/confirm_dialog.dart';
import 'package:autonect/view/widget/detail_item.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/offer_card.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One request and its offers as TWO independent [StateView]s: the offers
/// route is uncapped and unpaginated, so a slow offers read must never blank
/// the header that says what the buyer is looking at.
class BuyerRequestDetailPage extends StatefulWidget {
  const BuyerRequestDetailPage({super.key, required this.requestId});

  final String requestId;

  @override
  State<BuyerRequestDetailPage> createState() => _RequestDetailState();
}

class _RequestDetailState extends State<BuyerRequestDetailPage> {
  final RequestDetailController c = RequestDetailController.ensure();

  @override
  void initState() {
    super.initState();
    c.load(widget.requestId);
  }

  /// ONE confirm dialog at a time: a second entry — a tap in the frame before
  /// the pushed route takes pointer input away from this screen — would stack
  /// a dialog that outlives the action it is asking about.
  bool _confirming = false;

  /// CLOSE and CANCEL are one-way and terminal — there is no reopen route — so
  /// both sit behind [ConfirmDialog], whose buttons fire at most once. The
  /// verbs are CloseAction, never the statuses CLOSED/CANCELLED, which this
  /// endpoint 400s on.
  Future<void> _confirm(CloseAction action, String verb, String warning) async {
    if (_confirming) return;
    _confirming = true;
    final ok =
        await Get.dialog<bool>(ConfirmDialog(verb: verb, warning: warning));
    _confirming = false;
    if (ok == true) await c.close(action);
  }

  /// Offered only while the request is OPEN: the transitions are terminal.
  Widget _actions(PartRequest r) => Obx(() {
    final error = c.formError.value;
    if (!r.isOpen) return const SizedBox.shrink();
    return Column(children: [
      if (error != null)
        MyText(text: error, size: AppTextScale.label, color: kRedColor,
            textAlign: TextAlign.center, paddingBottom: AppSizes.s8),
      MyButton(mTop: AppSizes.s16, buttonText: 'Close request',
          fontSize: AppTextScale.body, loading: c.busy.value,
          onTap: () => _confirm(CloseAction.close, 'Close request',
              'Suppliers can no longer send offers. This cannot be undone.')),
      MyButton(mTop: AppSizes.s12, buttonText: 'Cancel request',
          backgroundColor: kWhiteColor, outlineColor: kRedColor,
          fontColor: kRedColor, fontSize: AppTextScale.body,
          loading: c.busy.value,
          onTap: () => _confirm(CloseAction.cancel, 'Cancel request',
              'The request is withdrawn and cannot be reopened.')),
    ]);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(title: 'Request Detail', centerdTitle: false),
    body: ListView(padding: AppSizes.DEFAULT, children: [
      Obx(() => StateView<PartRequest>(
        state: c.request.value,
        onRetry: c.loadRequest,
        builder: (_, r) =>
            Column(children: [_RequestHeader(request: r), _actions(r)]),
      )),
      Padding(
        padding: const EdgeInsets.only(top: AppSizes.s24, bottom: AppSizes.s12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const MyText(
              text: 'Offers',
              size: AppTextScale.title,
              color: kBlackColor,
              weight: AppWeights.bold,
            ),
            Obx(() {
              final r = c.requestOrNull;
              final offers = switch (c.offers.value) {
                Data(:final value) => value,
                _ => const <Offer>[],
              };
              if (r == null || offers.length < 2) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => Get.to(() => ComparisonPage(request: r)),
                child: const MyText(
                  text: 'Compare Offers',
                  size: AppTextScale.body,
                  weight: AppWeights.bold,
                  color: kSecondaryColor,
                  decoration: TextDecoration.underline,
                ),
              );
            }),
          ],
        ),
      ),
      // `c.requestOrNull` is read HERE, never in the builder (see [StateView]):
      // read there it subscribed to nothing, so a header 'Try again' that
      // succeeded left every row holding null and its tap guard inert forever.
      Obx(() {
        final r = c.requestOrNull;
        return StateView<List<Offer>>(state: c.offers.value,
            onRetry: c.loadOffers, builder: (_, offers) => Column(children: [
              for (final o in offers) _OfferRow(offer: o, request: r),
            ]));
      }),
    ]),
  );
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader({required this.request});

  final PartRequest request;

  @override
  Widget build(BuildContext context) {
    final v = request.vehicle;
    final vehicle = [v?.make, v?.model, v?.year?.toString()].whereType<String>().join(' ');
    final photos = request.images.length;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: MyText(text: request.partName, color: kBlackColor,
              size: AppTextScale.subtitle, weight: AppWeights.bold)),
          StatusBadge(label: request.status?.label ?? 'Unknown',
              color: requestStatusColor(request.status)),
        ]),
        const SizedBox(height: AppSizes.s16),
        DetailItem(label: 'Registration', value: request.regNumber),
        DetailItem(
            label: 'Vehicle', value: vehicle.isEmpty ? 'Not identified' : vehicle),
        DetailItem(label: 'Category', value: request.category.name),
        DetailItem(label: 'Condition', value: request.condition?.label ?? 'Any'),
        DetailItem(label: 'Urgency', value: request.urgency?.label ?? 'Not stated'),
        if (request.partNumber != null)
          DetailItem(label: 'Part number', value: request.partNumber!),
        if (request.description != null)
          DetailItem(label: 'Description', value: request.description!),
        // A chip, never thumbnails: requests.service.ts returns raw S3 keys and
        // never calls createDownloadUrl, so a buyer holds no signed URL.
        StatusBadge(
            color: kGreyTextColor, label: photos == 1 ? '1 photo' : '$photos photos'),
      ]),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer, required this.request});

  final Offer offer;

  /// Null while the header loads or fails: [OfferDetailPage] needs both halves.
  final PartRequest? request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final days = offer.deliveryTimeDays;
    return MyRippleEffect(
      radius: AppSizes.radiusMd,
      splashColor: kSecondaryColor.withValues(alpha: .1),
      // The whole row IS this screen's CTA, so 'disabled' is a tap that goes
      // nowhere over a card that says why — the rule the comparison card reads.
      onTap: () {
        if (r != null && canAcceptOffer(offer, r)) {
          Get.to(() => OfferDetailPage(offer: offer, request: r));
        }
      },
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSizes.s12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(text: supplierDisplayName(offer.supplier), maxLines: 1,
                    size: AppTextScale.body, weight: AppWeights.semibold,
                    color: kBlackColor, textOverflow: TextOverflow.ellipsis),
                MyText(size: AppTextScale.label, color: kGreyTextColor,
                    paddingTop: AppSizes.s4,
                    text: days == null
                        ? 'Delivery time not stated'
                        : 'Delivery in $days days'),
              ],
            )),
            MyText(text: formatPence(offer.pricePence), color: kBlackColor,
                size: AppTextScale.subtitle, weight: AppWeights.bold),
          ]),
          if (r != null) OfferGoneNote(offer: offer, request: r),
        ]),
      ),
    );
  }
}

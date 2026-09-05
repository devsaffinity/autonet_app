import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/domain/offer_actionability.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';

/// The pieces every buyer-facing offer card needs when the row it draws can no
/// longer be accepted.
///
/// THREE screens list offers — comparison, its report, and the request detail —
/// and `GET /v1/requests/{id}/offers` hands all three the REJECTED, ACCEPTED
/// and (via a closed parent) untouchable rows in the same array as the live
/// ones. Said three different ways that reads as three different facts, so the
/// pill and the sentence are drawn HERE and the rule behind them stays in
/// domain/offer_actionability.dart. Nothing in this file decides anything.
///
/// Each renders an empty box while the offer is live, so a card can place them
/// unconditionally and never repeat the null check.
class OfferGoneBadge extends StatelessWidget {
  const OfferGoneBadge({super.key, required this.offer, required this.request});

  final Offer offer;
  final PartRequest request;

  @override
  Widget build(BuildContext context) {
    final label = unacceptableLabel(offer, request);
    return label == null
        ? const SizedBox.shrink()
        : StatusBadge(label: label, color: kRedColor);
  }
}

/// The one sentence that goes with [OfferGoneBadge]: what happened, never what
/// the buyer did wrong.
class OfferGoneReason extends StatelessWidget {
  const OfferGoneReason({super.key, required this.offer, required this.request});

  final Offer offer;
  final PartRequest request;

  @override
  Widget build(BuildContext context) {
    final reason = unacceptableReason(offer, request);
    return reason == null
        ? const SizedBox.shrink()
        : MyText(text: reason, size: AppTextScale.label, color: kGreyTextColor,
            paddingTop: AppSizes.s8);
  }
}

/// Both, stacked — for a card with no price row to hang the pill beside.
class OfferGoneNote extends StatelessWidget {
  const OfferGoneNote({super.key, required this.offer, required this.request});

  final Offer offer;
  final PartRequest request;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OfferGoneBadge(offer: offer, request: request),
        OfferGoneReason(offer: offer, request: request),
      ]);
}

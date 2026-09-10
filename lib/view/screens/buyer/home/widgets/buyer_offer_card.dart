import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The comp's metadata glyphs at their shipped size, with #D94D2F baked in —
/// the same two the requests list and the active-request card already draw, so
/// a date and a part category look the same everywhere in the app.
const double _kMetaIcon = 16;

/// The offer thumbnail. Wide and short, because the only art available is a
/// side-on car.
const double _kThumbWidth = 96, _kThumbHeight = 52;

/// One offer on the buyer's home feed — the comp's offer card, driven by a real
/// [Offer] from `GET /v1/buyer/offers`.
///
/// Every field below is optional on the wire except the price and the date, so
/// each line is omitted rather than blanked when absent: DVLA returns no model
/// for most plates, and `offer.request` is null on the per-request route this
/// same model also serves.
///
/// THE THUMBNAIL IS THE BUYER'S OWN PHOTO, not the supplier's. There is no
/// supplier one to show: `model Offer` has no image relation and no image
/// column and `createOfferBodySchema` accepts no keys, so a quote cannot carry
/// a picture anywhere in the system. What the buyer attached to the REQUEST
/// can, and is the more useful image on this card anyway — it is the part they
/// asked about.
///
/// It renders as soon as `buyer-offers.service.ts` selects and signs
/// `request.images`, exactly as `withSignedImages` already does for
/// requestsService. Until then that projection sends no images key at all, the
/// list decodes empty, and the slot falls back to the same static car the
/// requests list uses — decoration that reads as decoration.
class BuyerOfferCard extends StatelessWidget {
  const BuyerOfferCard({super.key, required this.offer, this.onTap});

  final Offer offer;
  final VoidCallback? onTap;

  /// The vehicle, or the registration when DVLA gave us no make.
  ///
  /// Never 'null null' and never empty: [OfferRequestRef.regNumber] is required
  /// on the projection, so there is always something to fall back to.
  static String _vehicleLine(OfferRequestRef r) {
    final parts = [r.make, r.model].whereType<String>();
    return parts.isEmpty ? r.regNumber : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final request = offer.request;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.s12),
        decoration: AppStyling().myShadowStyle(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (request != null)
                    MyText(
                      text: _vehicleLine(request).toUpperCase(),
                      size: AppTextScale.caption,
                      color: kGreyTextColor,
                      weight: AppWeights.medium,
                      letterSpacing: 0.5,
                      maxLines: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  MyText(
                    // The part, not the vehicle the comp's mock put here: two
                    // offers on one feed are told apart by what they are FOR,
                    // and the car is already named on the line above.
                    text: request?.partName ?? 'Offer',
                    size: AppTextScale.body,
                    weight: AppWeights.bold,
                    color: kBlackColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s8),
                  // Wrap, not Row: at 200% system font two icon+label pairs do
                  // not fit one line inside a phone-width card, and a Row
                  // overflows where this reflows.
                  //
                  // The supplier's name and rating are deliberately NOT here —
                  // the comp's card is price, part and provenance. Both are on
                  // ComparisonPage, which is where an offer is actually chosen
                  // and where a rating can sit beside its rivals.
                  Wrap(
                    spacing: AppSizes.s12,
                    runSpacing: AppSizes.s4,
                    children: [
                      _meta(Assets.imagesRsC,
                          formatDayMonthYear(offer.createdAt)),
                      if (request?.categoryName case final name?)
                        _meta(Assets.imagesRsD, name),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                MyText(
                  // GBP, not the comp's dollars: money is integer pence and
                  // sterling everywhere in this system.
                  text: formatPence(offer.pricePence),
                  size: AppTextScale.subtitle,
                  weight: AppWeights.bold,
                  color: kSecondaryColor,
                ),
                const SizedBox(height: AppSizes.s8),
                _thumb(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The buyer's first request photo, or the placeholder.
  ///
  /// `url` is a SHORT-LIVED presign, so the decoded image is cached against the
  /// stable S3 key: keying on the url re-downloads on every read and serves a
  /// 403 from anything holding an expired one. Same rule as the active-request
  /// card, and the reason [RequestImage] keeps both fields.
  Widget _thumb() {
    final first = offer.request?.images.firstOrNull;
    if (first != null && first.isRenderable) {
      return CommonImageView(url: first.url, cacheKey: first.s3Key,
          width: _kThumbWidth, height: _kThumbHeight,
          radius: AppSizes.radiusSm, fit: BoxFit.cover);
    }
    return Container(
      width: _kThumbWidth,
      height: _kThumbHeight,
      decoration: BoxDecoration(
        color: kLightOrangeColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: const Center(
        child: Icon(
          Icons.directions_car_outlined,
          size: 26,
          color: kGreyTextColor,
        ),
      ),
    );
  }

  Widget _meta(String asset, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CommonImageView(svgPath: asset, height: _kMetaIcon, width: _kMetaIcon),
      const SizedBox(width: AppSizes.s4),
      // Flexible, NOT a fixed maxWidth: a fixed cap still demands its full
      // width when the Wrap has less to give, overflowing by the shortfall.
      Flexible(
        child: MyText(
          text: label,
          size: AppTextScale.label,
          color: kGreyTextColor,
          maxLines: 1,
          textOverflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

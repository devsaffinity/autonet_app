import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// One offer on the buyer's home feed — the comp's offer card, now driven by a
/// real [Offer] from `GET /v1/buyer/offers`.
///
/// It replaces OfferStyleRequestCard, which stood in for this while no
/// cross-request offers route existed and could therefore only ever show an
/// offer COUNT where the comp shows a price.
///
/// Every field below is optional on the wire except the price and the date, so
/// each line is omitted rather than blanked when absent: DVLA returns no model
/// for most plates, and `offer.request` is null on the per-request route this
/// same model also serves.
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
                    // The part, not the supplier: two offers on one home feed
                    // are told apart by what they are for, and the supplier
                    // name sits on the line below where the comp puts it.
                    text: request?.partName ?? 'Offer',
                    size: AppTextScale.body,
                    weight: AppWeights.bold,
                    color: kBlackColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s8),
                  // Wrap, not Row: at 200% system font three icon+label pairs
                  // do not fit one line inside a phone-width card, and a Row
                  // overflows where this reflows.
                  Wrap(
                    spacing: AppSizes.s12,
                    runSpacing: AppSizes.s4,
                    children: [
                      _meta(Icons.calendar_today_outlined,
                          formatDayMonthYear(offer.createdAt)),
                      if (request?.categoryName case final name?)
                        _meta(Icons.build_outlined, name),
                      if (_supplierName case final name?)
                        _meta(Icons.storefront_outlined, name),
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
                  text: formatPence(offer.pricePence),
                  size: AppTextScale.subtitle,
                  weight: AppWeights.bold,
                  color: kSecondaryColor,
                ),
                // ratingCount, not ratingAvg alone: a 5.0 from one review and a
                // 5.0 from two hundred are not the same claim, and only this
                // route selects either — see OfferSupplier.ratingAvg.
                if (offer.supplier.ratingAvg case final avg?)
                  if ((offer.supplier.ratingCount ?? 0) > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: AppSizes.s12, color: kSecondaryColor),
                        const SizedBox(width: 2),
                        MyText(
                          text: '${avg.toStringAsFixed(1)} '
                              '(${offer.supplier.ratingCount})',
                          size: AppTextScale.caption,
                          color: kGreyTextColor,
                        ),
                      ],
                    ),
              ],
            ),
            const Icon(Icons.chevron_right,
                size: AppSizes.s20, color: kGreyTextColor),
          ],
        ),
      ),
    );
  }

  /// businessName over name: the trading name is what a buyer recognises, and
  /// the account holder's own name is the fallback. Both are nullable.
  String? get _supplierName {
    final business = offer.supplier.businessName;
    if (business != null && business.isNotEmpty) return business;
    final name = offer.supplier.name;
    return name != null && name.isNotEmpty ? name : null;
  }

  Widget _meta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: AppSizes.s12, color: kSecondaryColor),
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

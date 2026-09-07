import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// dd/MM/yyyy, zero-padded, UK ordering.
///
/// Hand-rolled because the project has no `intl` dependency, deliberately. If
/// one is ever added, this is the call site to replace — not a second format
/// invented alongside it.
String formatDayMonthYear(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
}

/// The wide card under 'Requests with offers'.
///
/// It takes the comp's OFFER card layout — make over model, a metadata row of
/// orange glyph + value, an emphasised figure on the right — but it is driven
/// by a [PartRequest], and its label says so.
///
/// Why not the comp's actual offers feed: no route returns a buyer's offers
/// across their requests, so the price on every card would cost one HTTP call
/// per request. The per-offer design — price, supplier, date — belongs on the
/// Comparison screen, where `GET /v1/requests/:id/offers` genuinely supplies
/// it. Until a buyer-scoped offers endpoint exists, a header reading 'Offers'
/// over a list of requests would be a labelling lie.
class OfferStyleRequestCard extends StatelessWidget {
  const OfferStyleRequestCard({super.key, required this.request, this.onTap});

  final PartRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final make = request.vehicle?.make;
    final offers = request.offerCount;

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
                  // Omitted rather than blanked when DVLA gave us no make —
                  // which is common. The line below always renders something.
                  if (make != null)
                    MyText(
                      text: make.toUpperCase(),
                      size: AppTextScale.caption,
                      color: kGreyTextColor,
                      weight: AppWeights.medium,
                      letterSpacing: 0.5,
                      maxLines: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  MyText(
                    // partName is what the buyer actually asked for, and it is
                    // always present. The comp shows only the vehicle, which
                    // would leave two requests on the same car indistinguishable.
                    text: request.partName,
                    size: AppTextScale.body,
                    weight: AppWeights.bold,
                    color: kBlackColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s8),
                  // Wrap, not Row: at a large system font two icon+label pairs
                  // will not sit on one line inside a phone-width card, and a
                  // Row would overflow rather than reflow.
                  Wrap(
                    spacing: AppSizes.s12,
                    runSpacing: AppSizes.s4,
                    children: [
                      _meta(
                        Icons.calendar_today_outlined,
                        formatDayMonthYear(request.createdAt),
                      ),
                      _meta(Icons.build_outlined, request.category.name),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            // Where the comp puts a price. There is no price to put: it belongs
            // to an offer, and this is a request.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                MyText(
                  text: '$offers',
                  size: AppTextScale.title,
                  weight: AppWeights.bold,
                  color: kSecondaryColor,
                ),
                MyText(
                  text: offers == 1 ? 'offer' : 'offers',
                  size: AppTextScale.caption,
                  color: kGreyTextColor,
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

  Widget _meta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: AppSizes.s12, color: kSecondaryColor),
      const SizedBox(width: AppSizes.s4),
      // Flexible, NOT a ConstrainedBox with a fixed maxWidth: a fixed cap still
      // demands its full width when the Wrap has less to give, which overflows
      // by exactly the shortfall. Flexible lets the label ellipsize into
      // whatever space actually exists. Caught at 320dp / 200% font, where the
      // date row overran by 16px.
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

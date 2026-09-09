import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The carousel's fixed height. Private to this card in spirit, like ImageTray's
/// tile size — it is exported only because the slot that holds the carousel has
/// to be given a height before any card is built.
///
/// Tuned to the comp, which draws a card about as tall as it is wide rather than
/// the near-2:3 slab this was. The floor on it is the text block at 200% system
/// font — 24 of padding plus four rows is about 182 — which is why the image
/// band is [Expanded]: it surrenders the difference instead of overflowing.
const double kActiveRequestCardHeight = 235;

/// The card's width, so that two cards read as two — one whole and the next
/// clearly begun — on every phone.
///
/// A fixed 230 was the comp's width on the comp's device: it shows nearly three
/// cards on a 430pt phone and one and a bit on a 320pt one, so the two-up rhythm
/// only ever held where it was drawn. Half the viewport reproduces it, because
/// two cards plus their gap then always overrun the padded row by a little, and
/// that overrun IS the peek that says 'swipe'. Clamped at both ends: below 170
/// the four text rows start ellipsizing on real data, and above 240 the card is
/// a slab on a tablet.
double activeRequestCardWidth(BuildContext context) =>
    (MediaQuery.sizeOf(context).width * .5).clamp(170.0, 240.0);

/// Both parts of the name are nullable and there is no top-level vehicle name
/// on the payload, so an unresolved plate degrades to the registration rather
/// than to 'null null'.
///
/// Worth knowing when reading the design comp: DVLA returns makes in caps and
/// usually no model at all, so this renders 'FORD' or a bare registration far
/// more often than it renders the comp's 'Mercedes Benz'.
String vehicleNameOf(PartRequest r) {
  final parts = [r.vehicle?.make, r.vehicle?.model].whereType<String>();
  return parts.isEmpty ? r.regNumber : parts.join(' ');
}

/// One open request on the buyer's home carousel.
///
/// It takes the typed [PartRequest], never a Map. `id` is a uuid and would
/// overflow the slot the fixture sized for 'BND-123-66', so the registration is
/// what is shown.
///
/// Row ordering follows the comp: the VALUE sits left and its LABEL right on
/// the part-number and condition rows. That reads oddly in code and is correct
/// on screen — do not "fix" it.
class ActiveRequestCard extends StatelessWidget {
  const ActiveRequestCard({super.key, required this.request, this.onTap});

  final PartRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: activeRequestCardWidth(context),
      decoration: AppStyling().myShadowStyle(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expanded, not a fixed height: at a large system font the rows below
          // need more room, and the image band giving it up is the only
          // degradation that does not overflow a carousel of fixed height.
          Expanded(child: _thumb()),
          Padding(
            padding: const EdgeInsets.all(AppSizes.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: MyText(
                    text: vehicleNameOf(request), size: AppTextScale.body,
                    weight: AppWeights.bold, color: kBlackColor,
                    maxLines: 1, textOverflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(width: AppSizes.s4),
                  MyText(text: request.regNumber, size: AppTextScale.label,
                      color: kSecondaryColor, weight: AppWeights.semibold),
                ]),
                const SizedBox(height: AppSizes.s8),
                // Category, with the comp's trailing orange glyph — the same
                // 16pt asset the requests list uses for its category chip, so
                // one part category reads identically on both screens. ONE
                // generic icon on purpose: PartCategory carries id/name/parentId
                // and nothing else, so a name-to-icon map would silently fall
                // back the next time an admin adds a category.
                Row(children: [
                  Expanded(child: MyText(
                    text: request.category.name, size: AppTextScale.label,
                    color: kGreyTextColor, maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  )),
                  CommonImageView(svgPath: Assets.imagesRsD,
                      height: AppSizes.s16, width: AppSizes.s16),
                ]),
                // Hidden entirely when null rather than showing a dash beside a
                // label: partNumber is optional on the wire, and an empty row
                // reads as a missing value rather than an absent field.
                if (request.partNumber case final pn?) ...[
                  const SizedBox(height: AppSizes.s4),
                  _detailRow(value: pn, label: 'Part No'),
                ],
                const SizedBox(height: AppSizes.s4),
                _detailRow(
                  // Three-valued on the wire, not binary — 'Either' is a real
                  // condition a buyer can pick, and null predates the field.
                  value: request.condition?.label ?? 'Any',
                  label: 'Condition',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _detailRow({required String value, required String label}) => Row(
    children: [
      Expanded(child: MyText(
        text: value, size: AppTextScale.label, color: kGreyTextColor,
        maxLines: 1, textOverflow: TextOverflow.ellipsis,
      )),
      const SizedBox(width: AppSizes.s8),
      MyText(text: label, size: AppTextScale.label, color: kBlackColor,
          weight: AppWeights.medium),
    ],
  );

  /// The buyer's own first photo, or a placeholder when there is none.
  ///
  /// Nothing is drawn OVER it. The comp's band is a clean photograph, and the
  /// two chips this used to stack on it — an offer count and a photo count —
  /// are both now said better elsewhere: the offer count by the Offers section
  /// below, which carries real priced offers rather than the derived count it
  /// showed when that chip was written, and the photo count by the request
  /// detail screen, which actually shows them.
  ///
  /// The url is a short-lived presign, so the decoded image is cached against
  /// the stable S3 KEY — keying on the url would re-download on every read and
  /// 403 the moment one expired.
  ///
  /// Still degrades rather than erroring: a request may genuinely have no
  /// photos, and a server older than the signing change sends only keys.
  Widget _thumb() {
    final first = request.images.firstOrNull;
    return SizedBox(
      width: double.infinity,
      child: first != null && first.isRenderable
          ? CommonImageView(
              url: first.url,
              cacheKey: first.s3Key,
              fit: BoxFit.cover,
            )
          : const ColoredBox(
              color: kMutedSurfaceColor,
              child: Icon(Icons.directions_car_filled_outlined,
                  color: kGreyTextColor, size: AppSizes.s32),
            ),
    );
  }
}

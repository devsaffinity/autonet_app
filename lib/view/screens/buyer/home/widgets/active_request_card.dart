import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The carousel's fixed geometry. Private to this card, like ImageTray's tile
/// size — it is not a spacing scale anyone else consumes.
const double kActiveRequestCardWidth = 230;
const double kActiveRequestCardHeight = 290;

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
      width: kActiveRequestCardWidth,
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
                // Category, with the comp's trailing orange glyph. ONE generic
                // icon on purpose: PartCategory carries id/name/parentId and
                // nothing else, so a name-to-icon map would silently fall back
                // the next time an admin adds a category.
                Row(children: [
                  Expanded(child: MyText(
                    text: request.category.name, size: AppTextScale.label,
                    color: kGreyTextColor, maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  )),
                  const Icon(Icons.build_outlined,
                      size: AppSizes.s16, color: kSecondaryColor),
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

  /// A PLACEHOLDER, not an image. `images` are raw S3 keys and the buyer routes
  /// sign no download URL, so there is nothing fetchable to hand
  /// CommonImageView. The chip states the count honestly instead.
  ///
  /// Deliberately not stock photography, which the comp implies: a generic
  /// engine bay on every card is a lie the buyer spots the moment they compare
  /// two of their own requests. When the backend signs a thumbnail this becomes
  /// `CommonImageView(url: …)` in place, with no layout change.
  Widget _thumb() => SizedBox(
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(
          color: kMutedSurfaceColor,
          child: Icon(Icons.directions_car_filled_outlined,
              color: kGreyTextColor, size: AppSizes.s32),
        ),
        // The offer count has no slot in the comp, but it is the ONLY thing
        // distinguishing this carousel from the 'Requests with offers' one
        // below it. Drop it and the two sections render identical cards.
        Positioned(
          left: AppSizes.s8,
          top: AppSizes.s8,
          child: _chip(
            '${request.offerCount} ${request.offerCount == 1 ? 'offer' : 'offers'}',
            background: kSecondaryColor,
          ),
        ),
        if (request.images.isNotEmpty)
          Positioned(
            right: AppSizes.s8,
            bottom: AppSizes.s8,
            child: _chip(
              '${request.images.length} '
              '${request.images.length == 1 ? 'photo' : 'photos'}',
              background: kBlackColor.withValues(alpha: .6),
            ),
          ),
      ],
    ),
  );

  Widget _chip(String text, {required Color background}) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s8, vertical: AppSizes.s4),
    decoration: AppStyling().myDecoration(
      color: background,
      borderColor: kTransperentColor,
      radius: AppSizes.radiusPill,
    ),
    child: MyText(text: text, size: AppTextScale.caption, color: kWhiteColor),
  );
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The carousel's fixed geometry. Private to this card, like ImageTray's tile
/// size — it is not a spacing scale anyone else consumes.
const double kActiveRequestCardWidth = 178;
const double kActiveRequestCardHeight = 172;
const double _thumbHeight = 74;

/// Both parts of the name are nullable and there is no top-level vehicle name
/// on the payload, so an unresolved plate degrades to the registration rather
/// than to 'null null'.
String vehicleNameOf(PartRequest r) {
  final parts = [r.vehicle?.make, r.vehicle?.model].whereType<String>();
  return parts.isEmpty ? r.regNumber : parts.join(' ');
}

/// One open request on the buyer's home carousel.
///
/// It takes the typed [PartRequest], never a Map. `id` is a uuid and would
/// overflow the slot the fixture sized for 'BND-123-66', so the registration is
/// what is shown.
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
          _thumb(),
          Padding(
            padding: const EdgeInsets.all(AppSizes.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: MyText(
                    text: vehicleNameOf(request), size: AppTextScale.label,
                    weight: AppWeights.semibold, color: kBlackColor,
                    maxLines: 1, textOverflow: TextOverflow.ellipsis,
                  )),
                  MyText(text: request.regNumber, size: AppTextScale.caption,
                      color: kSecondaryColor, weight: AppWeights.medium),
                ]),
                MyText(text: request.category.name, size: AppTextScale.caption,
                    color: kGreyTextColor, maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                    paddingTop: AppSizes.s4),
                Row(children: [
                  MyText(text: 'Condition  ', size: AppTextScale.caption,
                      color: kGreyTextColor),
                  MyText(text: request.condition?.label ?? 'Any',
                      size: AppTextScale.caption, color: kBlackColor,
                      weight: AppWeights.medium),
                  const Spacer(),
                  MyText(text: '${request.offerCount} offers',
                      size: AppTextScale.caption, color: kSecondaryColor,
                      weight: AppWeights.semibold),
                ]),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  /// A PLACEHOLDER, not an image. `images` are raw S3 keys and the buyer routes
  /// sign no download URL, so there is nothing fetchable to hand
  /// CommonImageView. The chip states the count honestly instead.
  Widget _thumb() => SizedBox(
    height: _thumbHeight,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(
          color: kMutedSurfaceColor,
          child: Icon(Icons.directions_car_filled_outlined,
              color: kGreyTextColor, size: AppSizes.s32),
        ),
        if (request.images.isNotEmpty)
          Positioned(
            right: AppSizes.s4,
            bottom: AppSizes.s4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s8, vertical: AppSizes.s4),
              decoration: AppStyling().myDecoration(
                color: kBlackColor.withValues(alpha: .6),
                borderColor: kTransperentColor, radius: AppSizes.radiusPill,
              ),
              child: MyText(text: '${request.images.length} photos',
                  size: AppTextScale.caption, color: kWhiteColor),
            ),
          ),
      ],
    ),
  );
}

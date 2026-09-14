import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The carousel's fixed geometry, private to this card like ActiveRequestCard's.
///
/// Sized so two cards and the gap between them sit inside a 360dp screen's
/// content width, which is what the comp shows.
const double kServiceProviderCardWidth = 170;

/// The card's chrome: two 12dp paddings, the 64dp avatar, the 36dp button and
/// the four gaps between them. None of it scales with the system font.
const double _kCardChrome = 164;

/// The three text lines — name, brands, rating — at a text scale of 1.
const double _kCardTextBlock = 50;

/// The carousel's height for THIS context's text scale.
///
/// Not a constant. A fixed 214 fits at 100% and overflows the moment the
/// system font grows: the card's chrome is rigid but its three text lines are
/// not, so the strip has to grow with them. Caught by the 320dp/200% test,
/// which is the only reason this is a function.
///
/// Clamped at 2.0 because past that the card would be taller than the phone,
/// and the text inside ellipsizes rather than wrapping anyway.
double serviceProviderCardHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
  return _kCardChrome + _kCardTextBlock * scale;
}

/// How many manufacturers the comp fits on one line before it starts counting.
const int _kBrandsShown = 3;

/// 'BMW · Mercedes · KIA +2' — the comp's brands line.
///
/// The overflow counter is not decoration: a provider can carry a dozen makes,
/// and an ellipsis would tell the buyer nothing about how many were hidden.
/// Empty for a provider who listed none, and the caller omits the row entirely
/// rather than printing a blank one.
String brandsLabel(List<String> brands) {
  if (brands.isEmpty) return '';
  if (brands.length <= _kBrandsShown) return brands.join(' · ');
  final shown = brands.take(_kBrandsShown).join(' · ');
  return '$shown +${brands.length - _kBrandsShown}';
}

/// One approved provider on the buyer's home carousel.
///
/// THE CTA SAYS 'View Profile', NOT 'Book Now' as the comp does, and that is
/// deliberate until booking exists: `POST /v1/bookings` has no buyer-facing
/// route yet, so a 'Book Now' button could only open a screen that cannot
/// book. That is the same labelling lie the old 'Requests with offers' header
/// was, and it gets fixed the same way — by shipping the endpoint, not by
/// renaming the button. Flip the label the moment the booking flow lands.
class ServiceProviderCard extends StatelessWidget {
  const ServiceProviderCard({super.key, required this.provider, this.onTap});

  final ServiceProvider provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brands = brandsLabel(provider.brands);
    return Container(
      width: kServiceProviderCardWidth,
      padding: const EdgeInsets.all(AppSizes.s12),
      decoration: AppStyling().myShadowStyle(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _avatar()),
          const SizedBox(height: AppSizes.s8),
          MyText(
            text: provider.fullName,
            size: AppTextScale.body,
            weight: AppWeights.bold,
            color: kBlackColor,
            textAlign: TextAlign.center,
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
          if (brands.isNotEmpty) ...[
            const SizedBox(height: AppSizes.s4),
            MyText(
              text: brands,
              size: AppTextScale.caption,
              color: kGreyTextColor,
              textAlign: TextAlign.center,
              maxLines: 1,
              textOverflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSizes.s8),
          // ALWAYS present, so every card in the strip is the same shape and
          // the row does not appear and vanish down the carousel.
          _rating(),
          const SizedBox(height: AppSizes.s12),
          MyButton(
            buttonText: 'View Profile',
            fontSize: AppTextScale.label,
            height: 36,
            // The comp draws a rounded rectangle here, not MyButton's default
            // pill — a pill at 36dp tall reads as a chip rather than a CTA.
            radius: AppSizes.radiusMd,
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  /// Square with a soft radius, as the comp draws it — not a circle. The header
  /// avatar is the circular one; these are business cards.
  Widget _avatar() {
    const double size = 64;
    final url = provider.avatarUrl;
    return SizedBox(
      height: size,
      width: size,
      child: url != null &&
              url.isNotEmpty &&
              (url.startsWith('http://') || url.startsWith('https://'))
          ? CommonImageView(
              url: url,
              // The url is a short-lived presign that changes on every read, so
              // the decoded image is cached against the provider's stable id.
              cacheKey: provider.id,
              height: size,
              width: size,
              radius: AppSizes.radiusMd,
              fit: BoxFit.cover,
              errorWidget: InitialsAvatar(name: provider.fullName, size: size),
            )
          : InitialsAvatar(name: provider.fullName, size: size),
    );
  }

  /// The comp's star line — and for a provider nobody has reviewed, 'New'
  /// rather than '0.0/5.0'.
  ///
  /// ratingAvg defaults to 0 server-side, so printing it unconditionally tells
  /// a buyer that a brand-new garage scored zero out of five. That is not a
  /// missing rating, it is a bad one, and it is the difference between a
  /// provider getting their first job and never getting one. 'New' is what
  /// every marketplace shows here, and it keeps the row's height so the
  /// carousel does not jag.
  ///
  /// Worth knowing: today NOTHING can move this off 'New'. Review.orderId is
  /// required and points at Order, which only a parts Offer creates, so a
  /// booking cannot produce a review. Until that changes every provider card
  /// reads 'New' — correctly.
  Widget _rating() {
    final rated = provider.isRated;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          rated ? Icons.star_rounded : Icons.star_outline_rounded,
          size: AppSizes.s16,
          color: rated ? kWarningColor : kGreyTextColor,
        ),
        const SizedBox(width: AppSizes.s4),
        Flexible(
          child: MyText(
            // '/5.0' is in the comp and worth keeping: it makes the scale
            // explicit for a buyer who has not seen a rating on another card.
            text: rated ? '${provider.ratingAvg.toStringAsFixed(1)}/5.0' : 'New',
            size: AppTextScale.label,
            weight: AppWeights.semibold,
            color: rated ? kBlackColor : kGreyTextColor,
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

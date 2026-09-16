import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The buyer's own review, shown where the "Rate this provider" button was.
///
/// READ-ONLY on purpose: a review is final once left — the server has no
/// update route and refuses a second one. Showing the stars they gave, rather
/// than simply hiding the button, is what tells the buyer their review landed;
/// a button that silently vanished reads as a bug.
///
/// Shared by the bookings list and the booking detail page so the two can
/// never disagree about what a reviewed booking looks like.
class SubmittedReviewLine extends StatelessWidget {
  const SubmittedReviewLine({super.key, required this.review});

  final SubmittedReview review;

  @override
  Widget build(BuildContext context) => Semantics(
    // One sentence for a screen reader, not "star, star, star, outline star" —
    // and its own node, rather than merged into whatever card holds it.
    container: true,
    label: 'You rated this provider ${review.rating} out of 5',
    child: ExcludeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s12,
          vertical: AppSizes.s8,
        ),
        decoration: BoxDecoration(
          color: kLightOrangeColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(children: [
          Expanded(
            child: MyText(
              text: 'You rated this provider',
              size: AppTextScale.label,
              weight: AppWeights.semibold,
              color: kBlackColor,
              maxLines: 1,
              textOverflow: TextOverflow.ellipsis,
            ),
          ),
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= review.rating
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: AppSizes.s16,
              color: kSecondaryColor,
            ),
        ]),
      ),
    ),
  );
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// 1..5 tappable stars with an explicit unset state.
///
/// [rating] 0 means 'the buyer has not chosen yet', which is NOT the same as 1:
/// `POST /v1/reviews` requires an int 1..5, so the caller must keep submit
/// disabled while this reads 0 rather than silently posting a one-star review.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = AppSizes.s32,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var star = 1; star <= 5; star++)
              GestureDetector(
                onTap: () => onChanged(star),
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSizes.s8),
                  child: Icon(
                    star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: size,
                    color: star <= rating ? kWarningColor : kGreyTextColor,
                  ),
                ),
              ),
          ],
        ),
        if (rating == 0)
          MyText(text: 'Tap a star to rate', size: AppTextScale.label,
              color: kGreyTextColor, paddingTop: AppSizes.s8),
      ],
    );
  }
}

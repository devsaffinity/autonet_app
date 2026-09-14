import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The comp's tinted provider panel, inside a booking card.
///
/// Shared rather than copied because three screens draw it — the confirmation,
/// the My Bookings row and the booking detail — and they are all showing the
/// same provider on the same booking. A second copy is how the tint on one of
/// them quietly stops matching the other two.
///
/// 'Professional Technician' is the FALLBACK, not the label. The provider's own
/// [headline] goes here when they wrote one, because 'Senior Automotive
/// Electrician' tells a buyer something and a job title shared by everybody on
/// the platform does not.
class TechnicianPanel extends StatelessWidget {
  const TechnicianPanel({
    super.key,
    required this.name,
    this.headline,
    this.avatarUrl,
  });

  final String name;
  final String? headline;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSizes.s8),
    decoration: BoxDecoration(
      color: kLightOrangeColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
    ),
    child: Row(children: [
      if (avatarUrl != null && avatarUrl!.isNotEmpty)
        CommonImageView(
          url: avatarUrl,
          width: 36,
          height: 36,
          radius: AppSizes.radiusPill,
          fit: BoxFit.cover,
        )
      else
        InitialsAvatar(name: name, size: 36, radius: AppSizes.radiusPill),
      const SizedBox(width: AppSizes.s8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MyText(
            text: headline?.isNotEmpty == true
                ? headline!
                : 'Professional Technician',
            size: AppTextScale.caption, color: kGreyTextColor,
            maxLines: 1, textOverflow: TextOverflow.ellipsis,
          ),
          MyText(text: name, size: AppTextScale.body,
              weight: AppWeights.semibold, color: kSecondaryColor,
              maxLines: 1, textOverflow: TextOverflow.ellipsis),
        ],
      )),
    ]),
  );
}

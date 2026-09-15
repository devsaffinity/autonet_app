import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/electrician/provider_bookings_controller.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';

/// One callout, from the PROVIDER's side.
///
/// The action is a single button whose label comes from the booking's own
/// status, mirroring PROVIDER_FORWARD_TRANSITIONS on the server. Offering a
/// menu of statuses would mostly be offering 409s: the machine is
/// forward-only, so there is exactly one legal next step at any point.
class ProviderBookingCard extends StatelessWidget {
  const ProviderBookingCard({
    super.key,
    required this.booking,
    this.onAdvance,
    this.onDecline,
    this.onQuote,
    this.onTap,
  });

  final Booking booking;

  /// Accept / Start / Complete, depending on where the booking is.
  final VoidCallback? onAdvance;

  /// Only offered while the server would accept a cancellation.
  final VoidCallback? onDecline;

  /// Name or revise the price. Only offered once the provider has taken the
  /// work on — the server 409s a quote on a PENDING or CANCELLED booking.
  final VoidCallback? onQuote;

  /// Navigate to booking details page.
  final VoidCallback? onTap;

  String get _buyerName => booking.buyer?.name ?? 'A buyer';

  @override
  Widget build(BuildContext context) {
    final at = booking.scheduledAt.toLocal();
    final nextLabel = ProviderBookingsController.nextStepLabel(booking.status);
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.s20, 0, AppSizes.s20, AppSizes.s12),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Service title and status badge
          Row(children: [
            Expanded(child: MyText(
              text: booking.serviceType?.label ?? 'Callout',
              size: 17, weight: AppWeights.bold,
              color: kBlackColor, maxLines: 1,
              textOverflow: TextOverflow.ellipsis,
            )),
            if (booking.status case final s?)
              StatusBadge(label: s.label, color: _statusColor(s)),
          ]),

          // Customer note / fault description
          if (booking.description case final d? when d.isNotEmpty) ...[
            const SizedBox(height: AppSizes.s8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: kLightBlueColor.withOpacity(0.55),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: kSecondaryColor, width: 3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 14, color: kSecondaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: MyText(
                      text: d,
                      size: AppTextScale.caption,
                      color: kBlackColor,
                      maxLines: 2,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSizes.s12),

          // Client avatar and booking time
          Row(children: [
            if (booking.buyer?.avatarUrl != null &&
                booking.buyer!.avatarUrl!.isNotEmpty &&
                (booking.buyer!.avatarUrl!.startsWith('http://') ||
                    booking.buyer!.avatarUrl!.startsWith('https://')))
              CommonImageView(
                url: booking.buyer!.avatarUrl,
                cacheKey: booking.buyer?.id,
                width: 44,
                height: 44,
                radius: AppSizes.radiusPill,
                fit: BoxFit.cover,
                errorWidget: InitialsAvatar(
                  name: _buyerName,
                  size: 44,
                  radius: AppSizes.radiusPill,
                ),
              )
            else
              InitialsAvatar(
                name: _buyerName,
                size: 44,
                radius: AppSizes.radiusPill,
              ),
            const SizedBox(width: AppSizes.s8),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                MyText(text: _buyerName, size: 15,
                    weight: AppWeights.bold, color: kBlackColor,
                    maxLines: 1, textOverflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: kGreyTextColor),
                    const SizedBox(width: 4),
                    MyText(
                      text: formatDayMonthYear(at),
                      size: AppTextScale.caption,
                      color: kGreyTextColor,
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.access_time_rounded, size: 12, color: kGreyTextColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: MyText(
                        text: '${formatClock(at)}'
                            '${booking.durationMins == null ? '' : ' (~${booking.durationMins}m)'}',
                        size: AppTextScale.caption,
                        color: kGreyTextColor,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            )),
          ]),

          // Vehicle and Location rows
          if (_details() case final rows when rows.isNotEmpty) ...[
            const SizedBox(height: AppSizes.s8),
            for (final (icon, value) in rows)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.s4),
                child: Row(children: [
                  Icon(icon, size: 13, color: kGreyTextColor),
                  const SizedBox(width: 6),
                  Expanded(child: MyText(text: value, size: AppTextScale.caption,
                      color: kGreyTextColor, maxLines: 1,
                      textOverflow: TextOverflow.ellipsis)),
                ]),
              ),
          ],

          // Dedicated Figma-style Price Container
          Container(
            margin: const EdgeInsets.only(top: AppSizes.s12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xffFFF8F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffFFE7E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText(
                      text: booking.status == BookingStatus.completed
                          ? 'FINAL PRICE'
                          : (booking.isQuoted ? 'QUOTED PRICE' : 'ESTIMATED PAY'),
                      size: 10,
                      weight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                    const SizedBox(height: 2),
                    MyText(
                      text: booking.isQuoted
                          ? formatPence(booking.quotedPence!)
                          : (booking.earnedPence != null
                              ? formatPence(booking.earnedPence!)
                              : 'Not priced'),
                      size: 18,
                      weight: FontWeight.w800,
                      color: (booking.isQuoted || booking.earnedPence != null)
                          ? kSecondaryColor
                          : kGreyTextColor,
                    ),
                  ],
                ),
                if (ProviderBookingsController.canQuote(booking.status))
                  InkWell(
                    onTap: onQuote,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kWhiteColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kSecondaryColor.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 12, color: kSecondaryColor),
                          const SizedBox(width: 4),
                          MyText(
                            text: booking.isQuoted ? 'Change' : 'Set price',
                            size: AppTextScale.caption,
                            weight: FontWeight.w600,
                            color: kSecondaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.s12),

          // Bottom Action Row: View Details & Status Action Buttons
          Row(children: [
            // View Details link (Figma)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VIEW DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kBlackColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: kSecondaryColor,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (onDecline != null && booking.canCancel) ...[
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kRedColor,
                    side: const BorderSide(color: kRedColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: AppSizes.s8),
            ],
            if (nextLabel != null)
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: onAdvance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSecondaryColor,
                    foregroundColor: kWhiteColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(nextLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  List<(IconData, String)> _details() => [
    if (booking.regNumber case final r? when r.isNotEmpty)
      (Icons.directions_car_outlined, r),
    if (booking.location case final l? when l.isNotEmpty)
      (Icons.place_outlined, l),
  ];

  Color _statusColor(BookingStatus s) => switch (s) {
    BookingStatus.pending => kWarningColor,
    BookingStatus.confirmed => kInfoColor,
    BookingStatus.inProgress => kInfoColor,
    BookingStatus.completed => kSuccessColor,
    BookingStatus.cancelled => kRedColor,
  };
}

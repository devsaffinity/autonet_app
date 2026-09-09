import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/electrician/provider_bookings_controller.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/widget/app_card.dart';
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
  });

  final Booking booking;

  /// Accept / Start / Complete, depending on where the booking is.
  final VoidCallback? onAdvance;

  /// Only offered while the server would accept a cancellation.
  final VoidCallback? onDecline;

  /// Name or revise the price. Only offered once the provider has taken the
  /// work on — the server 409s a quote on a PENDING or CANCELLED booking.
  final VoidCallback? onQuote;

  String get _buyerName => booking.buyer?.name ?? 'A buyer';

  @override
  Widget build(BuildContext context) {
    final at = booking.scheduledAt.toLocal();
    final nextLabel = ProviderBookingsController.nextStepLabel(booking.status);
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.s20, 0, AppSizes.s20, AppSizes.s12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: MyText(
            text: booking.serviceType?.label ?? 'Callout',
            size: AppTextScale.subtitle, weight: AppWeights.bold,
            color: kSecondaryColor, maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          )),
          if (booking.status case final s?)
            StatusBadge(label: s.label, color: _statusColor(s)),
        ]),
        // What the buyer said is wrong. The single most useful line on this
        // card for somebody deciding whether to take the job.
        if (booking.description case final d? when d.isNotEmpty) ...[
          const SizedBox(height: AppSizes.s4),
          MyText(text: d, size: AppTextScale.label, color: kGreyTextColor,
              maxLines: 3, textOverflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: AppSizes.s12),
        Row(children: [
          InitialsAvatar(name: _buyerName, size: 36,
              radius: AppSizes.radiusPill),
          const SizedBox(width: AppSizes.s8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(text: _buyerName, size: AppTextScale.body,
                  weight: AppWeights.semibold, color: kBlackColor,
                  maxLines: 1, textOverflow: TextOverflow.ellipsis),
              MyText(
                text: '${formatDayMonthYear(at)} · ${formatClock(at)}'
                    '${booking.durationMins == null ? '' : ' · ~${booking.durationMins} mins'}',
                size: AppTextScale.label, color: kGreyTextColor,
              ),
            ],
          )),
          // The price, and a way to name one. 'Not priced' rather than a
          // blank or a zero: the buyer is reading 'Awaiting quote' on their
          // side of the same booking, and this is the control that answers it.
          if (ProviderBookingsController.canQuote(booking.status))
            GestureDetector(
              onTap: onQuote,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSizes.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText(
                      text: booking.isQuoted
                          ? formatPence(booking.quotedPence!)
                          : 'Not priced',
                      size: AppTextScale.body,
                      weight: AppWeights.bold,
                      color: booking.isQuoted ? kSecondaryColor : kGreyTextColor,
                    ),
                    if (onQuote != null)
                      MyText(
                        text: booking.isQuoted ? 'Change' : 'Set price',
                        size: AppTextScale.caption,
                        color: kSecondaryColor,
                        decoration: TextDecoration.underline,
                      ),
                  ],
                ),
              ),
            ),
        ]),
        // The car and where to go — both optional on the wire, and each
        // omitted rather than rendered as an empty row.
        if (_details() case final rows when rows.isNotEmpty) ...[
          const SizedBox(height: AppSizes.s8),
          for (final (icon, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.s4),
              child: Row(children: [
                Icon(icon, size: AppSizes.s12, color: kGreyTextColor),
                const SizedBox(width: AppSizes.s4),
                Expanded(child: MyText(text: value, size: AppTextScale.caption,
                    color: kGreyTextColor, maxLines: 1,
                    textOverflow: TextOverflow.ellipsis)),
              ]),
            ),
        ],
        if (nextLabel != null || onDecline != null) ...[
          const SizedBox(height: AppSizes.s12),
          Row(children: [
            if (onDecline != null && booking.canCancel) ...[
              Expanded(child: MyButton(
                buttonText: 'Decline',
                fontSize: AppTextScale.label,
                height: 40,
                radius: AppSizes.radiusMd,
                backgroundColor: kWhiteColor,
                fontColor: kRedColor,
                outlineColor: kRedColor,
                onTap: onDecline,
              )),
              const SizedBox(width: AppSizes.s12),
            ],
            if (nextLabel != null)
              Expanded(child: MyButton(
                buttonText: nextLabel,
                fontSize: AppTextScale.label,
                height: 40,
                radius: AppSizes.radiusMd,
                // One advance per tap: the server's conditional update would
                // reject the second as a concurrent change anyway.
                oneShot: true,
                onTap: onAdvance,
              )),
          ]),
        ],
      ]),
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

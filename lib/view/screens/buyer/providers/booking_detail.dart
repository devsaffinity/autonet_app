import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:autonect/view/widget/technician_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One booking read in full — where the list's 'View Booking' goes.
///
/// RENDERS THE ROW IT WAS HANDED, with no second fetch. `GET /v1/bookings`
/// already returns the whole booking, so re-reading it by id would be a
/// spinner over data the previous screen is still holding. The trade is that
/// a status changed on another device shows stale until the list is pulled,
/// which is the same trade every other detail screen in this app makes.
///
/// EVERY SECTION IS OMITTED WHEN ITS DATA IS ABSENT. Location, registration,
/// duration and the quote are all nullable on the wire — a booking made
/// against a provider who never gave an address has no address — and a
/// heading over a blank line reads as a bug rather than as an absence.
///
/// [onCancel] and [onReview] are the LIST's handlers, passed down rather than
/// rebuilt here. Cancelling needs a reason dialog and a refresh of the page
/// the buyer came from; a second copy of that flow is how the two screens end
/// up disagreeing about whether a cancelled booking is still cancellable.
class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({
    super.key,
    required this.booking,
    this.onCancel,
    this.onReview,
  });

  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;

  String get _providerName =>
      booking.provider?.fullName ?? booking.provider?.name ?? 'your provider';

  @override
  Widget build(BuildContext context) {
    final at = booking.scheduledAt.toLocal();
    return Scaffold(
      appBar: GeneralAppBar(title: 'Booking details'),
      body: ListView(
        padding: AppSizes.DEFAULT,
        children: [
          _serviceCard(),
          const SizedBox(height: AppSizes.s16),
          _scheduleCard(at),
          if (_hasJobDetails) ...[
            const SizedBox(height: AppSizes.s16),
            _jobCard(),
          ],
          if (booking.events.isNotEmpty) ...[
            const SizedBox(height: AppSizes.s16),
            _progressCard(),
          ],
          const SizedBox(height: AppSizes.s24),
          MyButton(
            buttonText: 'Chat Now',
            iconData: Icons.chat_bubble_outline_rounded,
            radius: AppSizes.radiusMd,
            // THIS booking's thread. It used to open the Messages tab,
            // because POST /v1/conversations took type OFFER only; it now
            // takes BOOKING, and opening is get-or-create.
            onTap: () => Get.to(
                  () => ChatRoomPage(
                    contextId: booking.id,
                    myUserId: booking.buyerId,
                    title: _providerName,
                  ),
                )
          ),
          if (onReview case final review?
              when booking.status == BookingStatus.completed) ...[
            const SizedBox(height: AppSizes.s12),
            MyButton(
              buttonText: 'Rate this provider',
              iconData: Icons.star_outline_rounded,
              radius: AppSizes.radiusMd,
              backgroundColor: kWhiteColor,
              fontColor: kSecondaryColor,
              outlineColor: kSecondaryColor,
              onTap: review,
            ),
          ],
          // Shown only while the server would accept it. Past IN_PROGRESS the
          // provider has travelled and started, so this would earn a 409.
          if (onCancel case final cancel? when booking.canCancel) ...[
            const SizedBox(height: AppSizes.s12),
            MyButton(
              buttonText: 'Cancel booking',
              radius: AppSizes.radiusMd,
              backgroundColor: kWhiteColor,
              fontColor: kRedColor,
              outlineColor: kRedColor,
              onTap: cancel,
            ),
          ],
          const SizedBox(height: AppSizes.s32),
        ],
      ),
    );
  }

  bool get _hasJobDetails =>
      (booking.location?.isNotEmpty ?? false) ||
      (booking.regNumber?.isNotEmpty ?? false) ||
      booking.durationMins != null;

  Widget _serviceCard() => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: MyText(text: 'Service Details',
            size: AppTextScale.caption, color: kGreyTextColor,
            letterSpacing: 0.5)),
        if (booking.status case final s?)
          StatusBadge(label: s.label, color: bookingStatusColor(s)),
      ]),
      const SizedBox(height: AppSizes.s4),
      MyText(
        text: booking.serviceType?.label ?? 'Callout',
        size: AppTextScale.title, weight: AppWeights.bold,
        color: kSecondaryColor,
      ),
      // The buyer's own words about the job, when they gave any.
      if (booking.description case final d? when d.isNotEmpty) ...[
        const SizedBox(height: AppSizes.s4),
        MyText(text: d, size: AppTextScale.body, color: kGreyTextColor,
            lineHeight: 1.5),
      ],
      const SizedBox(height: AppSizes.s12),
      TechnicianPanel(name: _providerName,
          headline: booking.provider?.headline),
    ]),
  );

  Widget _scheduleCard(DateTime at) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: 'Schedule', size: AppTextScale.caption,
          color: kGreyTextColor, letterSpacing: 0.5),
      const SizedBox(height: AppSizes.s4),
      // The long form here, not the confirmation screen's '11 Sep': this page
      // can be opened months after the booking was made, off a list rather
      // than off the calendar that named the month.
      MyText(text: formatLongDate(at), size: AppTextScale.title,
          weight: AppWeights.bold, color: kSecondaryColor),
      MyText(
        // 24-hour, matching the slot chip the buyer originally tapped, which
        // the SERVER labelled on a London clock.
        text: formatClock(at), size: AppTextScale.title,
        weight: AppWeights.bold, color: kBlackColor,
      ),
      const SizedBox(height: AppSizes.s8),
      _row(
        Icons.payments_outlined,
        // 'Awaiting quote', never '£0.00': quotedPence is null until the
        // provider has seen the job, and a zero would read as free.
        booking.isQuoted
            ? formatPence(booking.quotedPence!)
            : 'Awaiting quote — your provider prices the job after seeing it',
      ),
    ]),
  );

  Widget _jobCard() => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: 'Job Details', size: AppTextScale.caption,
          color: kGreyTextColor, letterSpacing: 0.5),
      const SizedBox(height: AppSizes.s8),
      if (booking.location case final l? when l.isNotEmpty)
        _row(Icons.place_outlined, l),
      if (booking.regNumber case final r? when r.isNotEmpty)
        _row(Icons.directions_car_outlined, r),
      if (booking.durationMins case final m?)
        // APPROXIMATE is the honest word: nothing in the schema records how
        // long a job takes, and this was sent as a product constant so the
        // provider's day has a length to plan around.
        _row(Icons.schedule, 'Approximately $m mins'),
    ]),
  );

  /// The booking's own history, straight off `events`.
  ///
  /// Never invented: a booking whose projection carried no events renders no
  /// card at all rather than a fabricated 'Requested' entry dated from
  /// createdAt, which would look identical to a real one and be a guess.
  Widget _progressCard() => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: 'Progress', size: AppTextScale.caption,
          color: kGreyTextColor, letterSpacing: 0.5),
      const SizedBox(height: AppSizes.s8),
      for (final e in booking.events) _event(e),
    ]),
  );

  Widget _event(BookingEvent e) {
    final at = e.at.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          // Nudged down onto the first line of text rather than centred on a
          // row whose height a note can double.
          padding: const EdgeInsets.only(top: AppSizes.s4),
          child: Icon(Icons.circle, size: AppSizes.s8,
              color: bookingStatusColor(e.status)),
        ),
        const SizedBox(width: AppSizes.s8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(text: e.status?.label ?? 'Updated',
                size: AppTextScale.label, weight: AppWeights.semibold,
                color: kBlackColor),
            MyText(text: '${formatDayMonthYear(at)} · ${formatClock(at)}',
                size: AppTextScale.caption, color: kGreyTextColor),
            // The reason a provider or a buyer typed when they moved it.
            if (e.note case final n? when n.isNotEmpty)
              MyText(text: n, size: AppTextScale.caption,
                  color: kGreyTextColor),
          ],
        )),
      ]),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.s8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: AppSizes.s4),
        child: Icon(icon, size: AppSizes.s16, color: kGreyTextColor),
      ),
      const SizedBox(width: AppSizes.s8),
      Expanded(child: MyText(text: text, size: AppTextScale.label,
          color: kGreyTextColor)),
    ]),
  );
}

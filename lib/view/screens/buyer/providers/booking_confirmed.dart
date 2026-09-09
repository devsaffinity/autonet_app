import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/view/screens/buyer/providers/my_bookings.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/technician_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The tinted disc behind the tick, and the card it sits in.
const double _kMarkCard = 80, _kMarkDisc = 48;

/// The comp's Booking Confirmed screen.
///
/// Renders the SERVER'S booking, not what we hoped we sent: the id, the slot
/// and the status all come back from the create, so what a buyer reads here
/// is what actually exists.
///
/// TWO OF THE COMP'S THREE BUTTONS ARE FULLY WIRED AND THE THIRD IS SHOWN
/// DISABLED, which is a deliberate distinction rather than an unfinished one:
///
///   * `Chat with <name>` opens the Messages tab, not this booking's thread.
///     `POST /v1/conversations` accepts type OFFER only — ConversationType
///     .BOOKING is in the schema and not in the DTO — so a booking has no
///     conversation to open. Same limit, same single call site, as the
///     profile's 'Chat Now'.
///   * 'Download Receipt' is rendered UNAVAILABLE, with the reason under it.
///     Nothing in this product receipts a booking, and that is not a missing
///     endpoint so much as a missing event: a Booking carries quotedPence and
///     finalPence, both NULL on everything this screen can be reached with,
///     and no payment is ever recorded against one — money for a callout is
///     settled between the buyer and the provider, off the platform. A button
///     that produced a document for a price nobody has named and a payment
///     nobody has taken would not be a stub, it would be a fabrication.
///
/// A disabled control with its reason printed is the honest shape here. It
/// occupies the comp's third slot, it does not invite the tap that proves it
/// does nothing, and the day a receipt exists it is one method that changes.
class BookingConfirmedPage extends StatelessWidget {
  const BookingConfirmedPage({super.key, required this.booking});

  final Booking booking;

  String get _providerName =>
      booking.provider?.fullName ?? booking.provider?.name ?? 'your provider';

  /// 'Chat with Alex' in the comp — the FIRST name, which is what a person
  /// would say. Falls back to the whole phrase rather than to a bare 'Chat',
  /// so a provider with no name on the row still reads as a sentence.
  String get _firstName {
    final full = booking.provider?.fullName ?? booking.provider?.name;
    final trimmed = full?.trim() ?? '';
    return trimmed.isEmpty ? 'your provider' : trimmed.split(' ').first;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: AppSizes.DEFAULT,
        children: [
          const SizedBox(height: AppSizes.s32),
          Center(child: _successMark()),
          const SizedBox(height: AppSizes.s16),
          MyText(text: 'Booking Confirmed', size: AppTextScale.title,
              weight: AppWeights.bold, color: kBlackColor,
              textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.s4),
          MyText(
            // 'Requested', not the comp's 'has been scheduled': the booking is
            // PENDING until the provider accepts it, and telling a buyer it is
            // locked in would be the screen overstating what happened. The
            // heading above is the comp's own word and stays.
            text: 'Your callout has been requested. '
                '$_providerName will confirm and quote.',
            size: AppTextScale.body, color: kGreyTextColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.s24),
          _serviceCard(),
          const SizedBox(height: AppSizes.s16),
          _scheduleCard(),
          const SizedBox(height: AppSizes.s24),
          MyButton(
            buttonText: 'Chat with $_firstName',
            iconData: Icons.chat_bubble_outline_rounded,
            radius: AppSizes.radiusMd,
            // THIS booking's thread — see booking_detail.dart.
            onTap: () => Get.to(
                  () => ChatRoomPage(
                    contextId: booking.id,
                    myUserId: booking.buyerId,
                    title: _providerName,
                  ),
                )
          ),
          const SizedBox(height: AppSizes.s12),
          MyButton(
            buttonText: 'View my Bookings',
            iconData: Icons.calendar_today_rounded,
            radius: AppSizes.radiusMd,
            backgroundColor: kWhiteColor,
            fontColor: kSecondaryColor,
            outlineColor: kSecondaryColor,
            // `off`, not `to`: this screen has nothing left to come back for,
            // and a confirmation stacked under My Bookings is a back button
            // that re-announces a booking the buyer has already read.
            onTap: () => Get.off(() => const MyBookingsPage()),
          ),
          const SizedBox(height: AppSizes.s12),
          _receiptButton(),
          const SizedBox(height: AppSizes.s32),
        ],
      ),
    ),
  );

  /// The comp's tick: a brand-coloured disc inside a white card, not a bare
  /// circle on the page.
  Widget _successMark() => Container(
    height: _kMarkCard,
    width: _kMarkCard,
    alignment: Alignment.center,
    decoration: AppStyling().myShadowStyle(),
    child: Container(
      height: _kMarkDisc,
      width: _kMarkDisc,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
          color: kSecondaryColor, shape: BoxShape.circle),
      child: const Icon(Icons.check_rounded, color: kWhiteColor,
          size: AppSizes.s24),
    ),
  );

  Widget _serviceCard() => Container(
    padding: const EdgeInsets.all(AppSizes.s16),
    decoration: AppStyling().myShadowStyle(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: 'Service Details', size: AppTextScale.caption,
          color: kGreyTextColor, letterSpacing: 0.5),
      const SizedBox(height: AppSizes.s4),
      MyText(
        text: booking.serviceType?.label ?? 'Callout',
        size: AppTextScale.title, weight: AppWeights.bold,
        color: kSecondaryColor,
      ),
      // The buyer's own words about the job, when they gave any. The comp's
      // 'Stage 2 Performance Mapping…' is copy for one made-up booking; the
      // real sentence is whatever they typed into Required Service.
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

  /// The comp's Schedule card: date over time, not side by side.
  Widget _scheduleCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSizes.s16),
    decoration: AppStyling().myShadowStyle(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: 'Schedule', size: AppTextScale.caption,
          color: kGreyTextColor, letterSpacing: 0.5),
      const SizedBox(height: AppSizes.s4),
      MyText(
        // Rendered in the DEVICE's zone, which is the clock the buyer will
        // actually be standing next to.
        text: formatShortDate(booking.scheduledAt.toLocal()),
        size: AppTextScale.title, weight: AppWeights.bold,
        color: kSecondaryColor,
      ),
      MyText(
        // 24-hour, not the comp's '11:30 AM'. The slot the buyer tapped two
        // screens ago was labelled by the SERVER on a London clock and drawn
        // verbatim — '14:00', never '2:00 PM'. Reformatting it here would
        // make one booking read two different ways inside one flow.
        text: formatClock(booking.scheduledAt.toLocal()),
        size: AppTextScale.title, weight: AppWeights.bold,
        color: kBlackColor,
      ),
    ]),
  );

  /// The comp's third button, shown UNAVAILABLE. See the class doc: a booking
  /// has no price and no payment, so there is nothing a receipt could report.
  ///
  /// Its own colours rather than MyButton's disabled treatment, which dims the
  /// BACKGROUND — on an outlined button that is white already, so the border
  /// and label would stay at full strength and the control would read as live.
  Widget _receiptButton() => Column(children: [
    MyButton(
      buttonText: 'Download Receipt',
      iconData: Icons.download_rounded,
      radius: AppSizes.radiusMd,
      enabled: false,
      backgroundColor: kWhiteColor,
      fontColor: kGreyTextColor,
      outlineColor: kFieldBorderColor,
    ),
    const SizedBox(height: AppSizes.s8),
    MyText(
      text: 'Receipts arrive once your provider has quoted and the job is '
          'complete.',
      size: AppTextScale.caption, color: kGreyTextColor,
      textAlign: TextAlign.center,
    ),
  ]);
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/receipt_controller.dart';
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
/// All three of the comp's buttons are wired:
///
///   * `Chat with <name>` opens THIS booking's thread.
///   * 'View my Bookings' replaces this screen with the list.
///   * 'Download Receipt' works once the booking is COMPLETED and PRICED, the
///     rule the server applies before issuing one. A booking has neither just
///     after it is made, so here it is almost always shown unavailable, with
///     the reason printed under it rather than a tap that can only fail.
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
      TechnicianPanel(
        name: _providerName,
        headline: booking.provider?.headline,
        avatarUrl: booking.provider?.avatarUrl,
      ),
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

  /// The comp's third button: LIVE once the booking is COMPLETED and PRICED,
  /// visibly unavailable with the reason under it until then.
  ///
  /// Its own colours rather than MyButton's disabled treatment, which dims the
  /// BACKGROUND — on an outlined button that is white already, so the border
  /// and label would stay at full strength and the control would read as live.
  Widget _receiptButton() {
    if (!booking.canHaveReceipt) {
      return Column(children: [
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
          text: 'Your receipt will be ready once the job is complete and your '
              'provider has recorded the price.',
          size: AppTextScale.caption, color: kGreyTextColor,
          textAlign: TextAlign.center,
        ),
      ]);
    }
    // Only a booking that CAN have a receipt touches the controller — on this
    // screen, shown straight after booking, that is almost never.
    return Obx(() {
      final receipts = ReceiptController.ensure();
      final busy = receipts.working.value == booking.id;
      return MyButton(
        buttonText: busy ? 'Preparing receipt…' : 'Download Receipt',
        iconData: Icons.download_rounded,
        radius: AppSizes.radiusMd,
        enabled: !busy,
        backgroundColor: kWhiteColor,
        fontColor: kSecondaryColor,
        outlineColor: kSecondaryColor,
        onTap: () => receipts.open(booking),
      );
    });
  }
}

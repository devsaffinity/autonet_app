import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/view/screens/buyer/providers/my_bookings.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The comp's Booking Confirmed screen.
///
/// Renders the SERVER'S booking, not what we hoped we sent: the id, the slot
/// and the status all come back from the create, so what a buyer reads here
/// is what actually exists.
///
/// The comp's 'Chat with Alex' and 'Download Receipt' are absent. Neither can
/// be built yet and neither is a small gap: a conversation can only be opened
/// against an OFFER (ConversationType.BOOKING is dead enum, and the Flutter
/// chat screen is a static mock with no repository), and nothing anywhere in
/// this product generates a receipt — there is no document, no PDF and no
/// route. Buttons that lead nowhere would be worse than their absence.
class BookingConfirmedPage extends StatelessWidget {
  const BookingConfirmedPage({super.key, required this.booking});

  final Booking booking;

  String get _providerName =>
      booking.provider?.fullName ?? booking.provider?.name ?? 'your provider';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: AppSizes.DEFAULT,
        children: [
          const SizedBox(height: AppSizes.s32),
          Center(child: Container(
            height: 64,
            width: 64,
            decoration: const BoxDecoration(
              color: kSecondaryColor, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: kWhiteColor,
                size: AppSizes.s32),
          )),
          const SizedBox(height: AppSizes.s16),
          MyText(text: 'Booking Confirmed', size: AppTextScale.title,
              weight: AppWeights.bold, color: kBlackColor,
              textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.s4),
          MyText(
            // 'Requested', not 'scheduled': the booking is PENDING until the
            // provider accepts it, and telling a buyer it is locked in would
            // be the screen overstating what happened.
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
            buttonText: 'View my Bookings',
            radius: AppSizes.radiusMd,
            onTap: () => Get.off(() => const MyBookingsPage()),
          ),
          const SizedBox(height: AppSizes.s12),
          MyButton(
            buttonText: 'Done',
            radius: AppSizes.radiusMd,
            backgroundColor: kWhiteColor,
            fontColor: kSecondaryColor,
            outlineColor: kSecondaryColor,
            onTap: Get.back,
          ),
          const SizedBox(height: AppSizes.s32),
        ],
      ),
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
        size: AppTextScale.subtitle, weight: AppWeights.bold,
        color: kSecondaryColor,
      ),
      // The buyer's own words about the job, when they gave any.
      if (booking.description case final d? when d.isNotEmpty) ...[
        const SizedBox(height: AppSizes.s4),
        MyText(text: d, size: AppTextScale.body, color: kGreyTextColor),
      ],
      const SizedBox(height: AppSizes.s12),
      Row(children: [
        InitialsAvatar(name: _providerName, size: 36,
            radius: AppSizes.radiusPill),
        const SizedBox(width: AppSizes.s8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(text: booking.provider?.headline ?? 'Provider',
                size: AppTextScale.caption, color: kGreyTextColor),
            MyText(text: _providerName, size: AppTextScale.body,
                weight: AppWeights.semibold, color: kSecondaryColor,
                maxLines: 1, textOverflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    ]),
  );

  Widget _scheduleCard() => Container(
    padding: const EdgeInsets.all(AppSizes.s16),
    decoration: AppStyling().myShadowStyle(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: 'Schedule', size: AppTextScale.caption,
          color: kGreyTextColor, letterSpacing: 0.5),
      const SizedBox(height: AppSizes.s4),
      Row(children: [
        MyText(
          // Rendered in the DEVICE's zone, which is the clock the buyer will
          // actually be standing next to.
          text: formatDayMonthYear(booking.scheduledAt.toLocal()),
          size: AppTextScale.subtitle, weight: AppWeights.bold,
          color: kSecondaryColor,
        ),
        const SizedBox(width: AppSizes.s12),
        MyText(text: formatClock(booking.scheduledAt.toLocal()),
            size: AppTextScale.subtitle, weight: AppWeights.bold,
            color: kBlackColor),
      ]),
      const SizedBox(height: AppSizes.s8),
      MyText(
        text: 'Status: ${booking.status?.label ?? 'Awaiting confirmation'}',
        size: AppTextScale.label, color: kGreyTextColor,
      ),
    ]),
  );
}

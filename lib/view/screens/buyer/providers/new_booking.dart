import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/new_booking_controller.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/view/screens/buyer/providers/booking_confirmed.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/month_calendar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/slot_picker.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The comp's New Booking screen.
///
/// NO PRICE IS COLLECTED, and that is the product rule rather than an
/// omission: a buyer books a date and a service, and the provider quotes once
/// they have seen the job. `quotedPence` is null on everything this creates.
///
/// The comp draws Location as a MAP. This shows the same information as an
/// address instead: nothing in this project draws maps — no tiles, no key, no
/// geocoding, no dependency — and a decorative map that does not actually
/// show where the job is would be worse than the address, which is the part
/// the buyer needs to read and the provider needs recorded.
class NewBookingPage extends StatefulWidget {
  const NewBookingPage({super.key, required this.provider});

  final ServiceProvider provider;

  @override
  State<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends State<NewBookingPage> {
  late final NewBookingController _c;

  /// Owned by the ROUTE, not the controller: a GetX controller that outlives
  /// this screen must not hold disposables the screen created. Same rule the
  /// part-request wizard follows.
  final TextEditingController _service = TextEditingController();
  final TextEditingController _car = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c = NewBookingController.ensure();
    _c.start(widget.provider);
  }

  @override
  void dispose() {
    _service.dispose();
    _car.dispose();
    super.dispose();
  }

  String get _providerName =>
      widget.provider.fullName.isEmpty ? 'this provider' : widget.provider.fullName;

  Future<void> _confirm() async {
    final booking = await _c.submit(
      description: _service.text,
      regNumber: _car.text,
    );
    if (booking == null || !mounted) return;
    // `off`, not `to`: going back to a form whose slot is now taken is a dead
    // end, and the confirmation screen owns the journey from here.
    Get.off(() => BookingConfirmedPage(booking: booking));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(title: 'New Booking'),
    body: ListView(
      padding: AppSizes.DEFAULT,
      children: [
        _title(),
        const SizedBox(height: AppSizes.s4),
        MyText(
          text: 'Select your preferred date and time. '
              'Your provider will confirm and quote.',
          size: AppTextScale.label, color: kGreyTextColor,
        ),
        const SizedBox(height: AppSizes.s16),
        Container(
          padding: const EdgeInsets.all(AppSizes.s16),
          decoration: AppStyling().myShadowStyle(),
          child: Obx(() => MonthCalendar(
            selected: _c.selectedDay.value,
            onSelect: _c.selectDay,
            // The server rejects a past slot, so offering one would only earn
            // a 400.
            firstSelectable: DateTime.now(),
          )),
        ),
        const SizedBox(height: AppSizes.s20),
        _selectedDay(),
        const SizedBox(height: AppSizes.s16),
        _slots(),
        const SizedBox(height: AppSizes.s20),
        MyText(text: 'Required Service', size: AppTextScale.body,
            weight: AppWeights.semibold, color: kBlackColor),
        const SizedBox(height: AppSizes.s8),
        MyTextField(
          controller: _service,
          hintText: 'What needs doing?',
          radius: AppSizes.radiusSm,
          marginBottom: AppSizes.s16,
          maxLines: 2,
        ),
        MyText(text: 'Car Model', size: AppTextScale.body,
            weight: AppWeights.semibold, color: kBlackColor),
        const SizedBox(height: AppSizes.s8),
        MyTextField(
          controller: _car,
          hintText: 'Registration',
          radius: AppSizes.radiusSm,
          marginBottom: AppSizes.s16,
          textCapitalization: TextCapitalization.characters,
        ),
        _serviceLocation(),
        _duration(),
        const SizedBox(height: AppSizes.s16),
        _summary(),
        const SizedBox(height: AppSizes.s16),
        Obx(() => MyButton(
          buttonText: 'Confirm Selection',
          radius: AppSizes.radiusMd,
          // Disabled until a slot is chosen: the server would 400 without
          // one, and a button that only produces an error is a worse teacher
          // than a button that waits.
          enabled: _c.canSubmit && !_c.busy.value,
          loading: _c.busy.value,
          // One booking per tap. A double tap must be dropped, not queued.
          oneShot: true,
          onTap: _confirm,
        )),
        const SizedBox(height: AppSizes.s32),
      ],
    ),
  );

  /// The comp's 'Booking with <name>', with the NAME in the brand colour.
  ///
  /// Wrap of two MyTexts rather than a Text.rich: MyText carries the app's
  /// font and a raw span would silently fall back to the platform default
  /// for half the line. Wrap, not Row, because a long name plus a large
  /// text scale will not sit on one line at 320dp — the same reason the
  /// directory row builds its name and trade line this way.
  Widget _title() => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      MyText(text: 'Booking with ', size: AppTextScale.subtitle,
          weight: AppWeights.bold, color: kBlackColor),
      MyText(text: _providerName, size: AppTextScale.subtitle,
          weight: AppWeights.bold, color: kSecondaryColor),
    ],
  );

  /// The comp's 'Selected slot' line, between the grid and the times.
  ///
  /// It reads the day back in words — '15 October 2026' — because the grid
  /// above only ever shows a bare number in a circle, and by the time a
  /// buyer has scrolled to the times that circle is off screen. Which day
  /// they are about to book is the one fact this form must never make them
  /// scroll up to check.
  ///
  /// UK ordering, day first, per formatLongDate. The comp's 'October 15,
  /// 2024' is US and every other date in this product is already UK.
  Widget _selectedDay() => Obx(() {
    final day = _c.selectedDay.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: 'Selected slot', size: AppTextScale.body,
          weight: AppWeights.semibold, color: kBlackColor),
      const SizedBox(height: AppSizes.s4),
      MyText(text: formatLongDate(day), size: AppTextScale.label,
          color: kGreyTextColor),
    ]);
  });

  Widget _slots() => Obx(() {
    // Read INSIDE the closure — a read from a builder that runs later
    // registers no dependency.
    final selected = _c.selectedSlot.value;
    return StateView<List<BookingSlot>>(
      state: _c.slots.value,
      onRetry: _c.loadSlots,
      emptyTitle: 'No slots that day',
      builder: (_, slots) => SlotPicker(
        slots: slots,
        selected: selected,
        onSelect: (s) => _c.selectedSlot.value = s,
      ),
    );
  });

  /// The comp's Location panel, as an address rather than a map.
  ///
  /// Omitted entirely when the provider has not given one — a 'Service
  /// Location' heading over an empty card tells a buyer nothing and looks
  /// broken.
  Widget _serviceLocation() {
    final location = widget.provider.location;
    if (location == null || location.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MyText(text: 'Location', size: AppTextScale.body,
            weight: AppWeights.semibold, color: kBlackColor),
        const SizedBox(height: AppSizes.s8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.s16),
          decoration: BoxDecoration(
            color: kSecondaryColor.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(children: [
            Container(
              height: 32,
              width: 32,
              decoration: const BoxDecoration(
                  color: kSecondaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.place, size: AppSizes.s16,
                  color: kWhiteColor),
            ),
            const SizedBox(width: AppSizes.s12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                MyText(text: 'SERVICE LOCATION', size: AppTextScale.caption,
                    weight: AppWeights.bold, color: kSecondaryColor,
                    letterSpacing: 0.5),
                MyText(text: location, size: AppTextScale.label,
                    color: kBlackColor),
              ],
            )),
          ]),
        ),
      ]),
    );
  }

  /// The comp's 'Approximate service duration: 90 mins'.
  ///
  /// APPROXIMATE is the honest word and the comp's own. Nothing in the schema
  /// records how long a job takes; this is a per-callout product constant on
  /// BookingServiceType, sent as durationMins so the provider's day has a
  /// length to plan around.
  Widget _duration() => Obx(() {
    final service = _c.serviceType.value;
    if (service == null) return const SizedBox.shrink();
    return Row(children: [
      const Icon(Icons.schedule, size: AppSizes.s16, color: kGreyTextColor),
      const SizedBox(width: AppSizes.s8),
      Expanded(child: MyText(
        text: 'Approximate service duration: '
            '${service.typicalMinutes} mins',
        size: AppTextScale.label,
        color: kGreyTextColor,
      )),
    ]);
  });

  /// The comp's SELECTED DATE / TIME SLOT bar.
  Widget _summary() => Obx(() {
    final slot = _c.selectedSlot.value;
    final day = _c.selectedDay.value;
    return Container(
      padding: const EdgeInsets.all(AppSizes.s12),
      decoration: AppStyling().myShadowStyle(),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(text: 'SELECTED DATE', size: AppTextScale.caption,
                color: kGreyTextColor, letterSpacing: 0.5),
            MyText(text: formatDayMonthYear(day), size: AppTextScale.body,
                weight: AppWeights.semibold, color: kBlackColor),
          ],
        )),
        Container(width: 1, height: 32, color: kFieldBorderColor),
        const SizedBox(width: AppSizes.s12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(text: 'TIME SLOT', size: AppTextScale.caption,
                color: kGreyTextColor, letterSpacing: 0.5),
            MyText(
              // Never a fabricated default: until a slot is picked there is
              // no time, and saying so is the point of the bar.
              text: slot?.time ?? 'Not selected',
              size: AppTextScale.body,
              weight: AppWeights.semibold,
              color: slot == null ? kGreyTextColor : kBlackColor,
            ),
          ],
        )),
      ]),
    );
  });
}

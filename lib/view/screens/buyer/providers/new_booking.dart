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
/// The comp's Location map is not here. There is a `location` column and the
/// API accepts it, but nothing in this project draws a map — no tiles, no key,
/// no geocoding — and a decorative map image that does not reflect where the
/// job is would be worse than the plain address the provider actually needs.
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
        MyText(text: 'Booking with $_providerName',
            size: AppTextScale.subtitle, weight: AppWeights.bold,
            color: kBlackColor),
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

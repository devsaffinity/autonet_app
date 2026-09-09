import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/electrician/availability_controller.dart';
import 'package:autonect/data/models/provider_schedule.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The provider's weekly working pattern.
///
/// A WEEKLY pattern, not a diary. Turning Monday evening off means every
/// Monday evening — the dates in the strip are only a familiar way to point at
/// a weekday. A one-off day away is a different model (a dated exception) and
/// is not built, so nothing here pretends to offer it.
class ElectricianAvailabilityPage extends StatefulWidget {
  const ElectricianAvailabilityPage({super.key});

  @override
  State<ElectricianAvailabilityPage> createState() =>
      _ElectricianAvailabilityPageState();
}

class _ElectricianAvailabilityPageState
    extends State<ElectricianAvailabilityPage> {
  final AvailabilityController c = AvailabilityController.ensure();

  @override
  void initState() {
    super.initState();
    c.load();
  }

  /// The band each card describes, in the order the design lists them.
  static const List<AvailabilityBand> _bands = AvailabilityBand.values;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        // Every Rx the subtree needs is read HERE, inside the Obx closure.
        // StateView.builder runs in its own build, outside this tracking zone,
        // so a read down there registers no dependency — GetX then throws
        // 'improper use of a GetX', which a release build paints as a plain
        // grey rectangle.
        child: Obx(() {
          final state = c.state.value;
          final weekday = c.selectedWeekday.value;
          final bands = c.selectedBands;
          final counts = Map<AvailabilityBand, int>.from(c.slotCounts);
          final configured = c.configured.value;
          final dirty = c.dirty.value;
          final wouldClear = c.wouldClearSchedule;
          final dayIsOff = c.selectedDayIsOff;
          final dates = c.weekDates;

          return StateView<ProviderSchedule>(
            state: state,
            onRetry: c.load,
            builder: (_, _) => SingleChildScrollView(
              padding: AppSizes.DEFAULT,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MyBackButton(),
                  MyText(
                    text: 'Availability',
                    size: 28,
                    weight: FontWeight.w800,
                    color: kBlackColor,
                    paddingBottom: 4,
                  ),
                  MyText(
                    text: 'Choose the half-days you work. This repeats every '
                        'week.',
                    size: 13,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                    paddingBottom: configured ? 28 : 16,
                  ),

                  if (!configured) _notSetYetNotice(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyText(
                        text: 'SELECT DAY',
                        size: 11,
                        weight: FontWeight.w700,
                        color: kGreyTextColor,
                      ),
                      MyText(
                        text: monthYearOf(dates.first),
                        size: 13,
                        weight: FontWeight.w700,
                        color: kSecondaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _WeekStrip(
                    dates: dates,
                    selectedWeekday: weekday,
                    worksOn: (d) => (c.draft[d.weekday] ?? const {}).isNotEmpty,
                    onSelect: c.selectWeekday,
                  ),
                  const SizedBox(height: 28),

                  MyText(
                    text: 'TIME SLOTS FOR ${weekdayName(weekday)}S'
                        .toUpperCase(),
                    size: 11,
                    weight: FontWeight.w700,
                    color: kGreyTextColor,
                    paddingBottom: 16,
                  ),

                  ..._bands.map(
                    (band) => _SlotCard(
                      band: band,
                      enabled: bands.contains(band),
                      slotCount: counts[band] ?? 0,
                      onChanged: (_) => c.toggle(band),
                    ),
                  ),

                  const SizedBox(height: 8),
                  _dayOffRow(weekday: weekday, dayIsOff: dayIsOff),
                  const SizedBox(height: 16),

                  if (dirty && wouldClear) _clearsScheduleWarning(),

                  _quickTip(),
                  const SizedBox(height: 20),

                  MyButton(
                    buttonText: dirty ? 'Save availability' : 'Saved',
                    enabled: dirty,
                    onTap: c.save,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// A provider who has never set a pattern is FULLY AVAILABLE, which is the
  /// opposite of what seven empty-looking days suggest. Saying so is not
  /// decoration: without it the screen reads as 'you work nothing'.
  Widget _notSetYetNotice() => Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(14),
    decoration: AppStyling().myDecoration(
      color: const Color(0xffEEF2FF),
      borderColor: const Color(0xffEEF2FF),
      radius: 14,
    ),
    child: MyText(
      text: 'You have not set working hours, so buyers can book you in any '
          'slot. Turn off the half-days you do not work.',
      size: 13,
      weight: FontWeight.w500,
      color: kBlackColor,
    ),
  );

  /// Saving an all-off week CLEARS the schedule rather than closing it: the
  /// server stores 'works nothing' as no rows, and no rows is also how it
  /// records 'never set'. A provider who believed they had blocked the week
  /// would be bookable in all of it, so this is said before they save.
  Widget _clearsScheduleWarning() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: AppStyling().myDecoration(
      color: kLightOrangeColor,
      borderColor: kLightOrangeColor,
      radius: 14,
    ),
    child: MyText(
      text: 'Every day is switched off. Saving this clears your working hours '
          'and makes you bookable in every slot again.',
      size: 13,
      weight: FontWeight.w500,
      color: kBlackColor,
    ),
  );

  Widget _dayOffRow({required int weekday, required bool dayIsOff}) {
    final day = weekdayName(weekday);
    return MyRippleEffect(
      onTap: c.toggleDayOff,
      radius: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: AppStyling().myDecoration(
          color: kPrimaryColor,
          borderColor: kTertiaryColor,
          radius: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kLightOrangeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: kSecondaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MyText(
                // Plural, because it is every one of them — 'Block Oct 14'
                // would promise a one-off this model cannot keep.
                text: dayIsOff
                    ? 'Start working ${day}s again'
                    : 'I do not work ${day}s',
                size: 14,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: kGreyTextColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTip() => Container(
    padding: const EdgeInsets.all(16),
    decoration: AppStyling().myDecoration(
      color: const Color(0xffEEF2FF),
      borderColor: const Color(0xffEEF2FF),
      radius: 14,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: kLightOrangeColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Quick Tip',
                size: 14,
                weight: FontWeight.w700,
                color: kBlackColor,
                paddingBottom: 4,
              ),
              MyText(
                // What actually happens. The old copy promised that blocking a
                // day cancels appointments and texts the client; nothing
                // cancels anything, and there is no SMS provider in the app.
                text: 'Switching a half-day off hides those slots from new '
                    'bookings. Jobs you have already accepted are not '
                    'affected — cancel those from the booking itself.',
                size: 13,
                weight: FontWeight.w400,
                color: kGreyTextColor,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.dates,
    required this.selectedWeekday,
    required this.worksOn,
    required this.onSelect,
  });

  final List<DateTime> dates;
  final int selectedWeekday;
  final bool Function(DateTime) worksOn;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(dates.length, (i) {
        final date = dates[i];
        final isSelected = selectedWeekday == date.weekday;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < dates.length - 1 ? 6 : 0),
            child: MyRippleEffect(
              onTap: () => onSelect(date.weekday),
              radius: 14,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? kSecondaryColor : kTertiaryColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? kSecondaryColor : kTertiaryColor,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText(
                      text: weekdayAbbrev(date.weekday),
                      size: 10,
                      weight: FontWeight.w600,
                      color: isSelected ? kWhiteColor : kGreyTextColor,
                    ),
                    const SizedBox(height: 4),
                    MyText(
                      text: '${date.day}',
                      size: 18,
                      weight: FontWeight.w800,
                      color: isSelected ? kWhiteColor : kBlackColor,
                    ),
                    const SizedBox(height: 4),
                    // A dot marks a day this provider works — the one fact the
                    // strip can state truthfully without a second read.
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: !worksOn(date)
                            ? kTransperentColor
                            : isSelected
                            ? kWhiteColor
                            : kSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.band,
    required this.enabled,
    required this.slotCount,
    required this.onChanged,
  });

  final AvailabilityBand band;
  final bool enabled;
  final int slotCount;
  final ValueChanged<bool> onChanged;

  static const Map<AvailabilityBand, IconData> _icons = {
    AvailabilityBand.morning: Icons.wb_sunny_outlined,
    AvailabilityBand.afternoon: Icons.wb_sunny_rounded,
    AvailabilityBand.evening: Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: AppStyling().myDecoration(
        color: kPrimaryColor,
        borderColor: kTertiaryColor,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                _icons[band],
                size: 20,
                color: band == AvailabilityBand.evening
                    ? const Color(0xff7986CB)
                    : const Color(0xffF4A020),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: enabled,
                  activeThumbColor: kSecondaryColor,
                  activeTrackColor: kSecondaryColor.withValues(alpha: 0.25),
                  inactiveThumbColor: kGreyTextColor.withValues(alpha: 0.5),
                  inactiveTrackColor: kTertiaryColor,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          MyText(
            text: band.label,
            size: 18,
            weight: FontWeight.w700,
            color: enabled ? kBlackColor : kGreyTextColor,
            paddingBottom: 2,
          ),
          MyText(
            text: band.timeRange,
            size: 13,
            weight: FontWeight.w400,
            color: kGreyTextColor,
            paddingBottom: 10,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xffE8F5E9)
                  : kTertiaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: MyText(
              // The number of bookable slots this band holds, from the
              // server's own grid — not a booking count, which this screen
              // does not read and must not imply.
              text: enabled
                  ? '$slotCount ${slotCount == 1 ? 'SLOT' : 'SLOTS'} BOOKABLE'
                  : 'NOT WORKING',
              size: 10,
              weight: FontWeight.w700,
              color: enabled ? const Color(0xff2E7D32) : kGreyTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

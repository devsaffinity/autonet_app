import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Monday-first weekday labels, the UK convention and the comp's.
///
/// The month names live in domain/date_format.dart rather than here: the
/// booking screen spells the selected day out in full right below this grid,
/// and two lists would be two places for a typo to hide in one screenshot.
const List<String> _kWeekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// Whether two instants fall on the same calendar day, LOCALLY.
///
/// Comparing instants directly would make 09:00 and 14:00 on one day
/// different days, and comparing ISO strings would convert to UTC first and
/// name yesterday for anyone tapping after midnight.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// A month grid with a selectable day — the comp's calendar.
///
/// Extracted from the booking screen because the electrician availability
/// screen wants the same grid, and a second copy is how two calendars in one
/// app start disagreeing about which day is Monday.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.firstSelectable,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  /// Days before this are rendered disabled. Null allows any day.
  ///
  /// The booking flow passes today: the server rejects a past slot, so
  /// offering one would be inviting a 400.
  final DateTime? firstSelectable;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  @override
  void didUpdateWidget(MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow a selection made elsewhere — otherwise picking a day in a
    // different month from outside would leave the grid showing the old one.
    if (!isSameDay(oldWidget.selected, widget.selected)) {
      _month = DateTime(widget.selected.year, widget.selected.month);
    }
  }

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  bool _isDisabled(DateTime day) {
    final floor = widget.firstSelectable;
    if (floor == null) return false;
    final f = DateTime(floor.year, floor.month, floor.day);
    return day.isBefore(f);
  }

  @override
  Widget build(BuildContext context) {
    // weekday is 1..7 with Monday==1, so this is already the Monday-first
    // offset with no remapping.
    final firstOfMonth = DateTime(_month.year, _month.month);
    final leading = firstOfMonth.weekday - 1;
    // Day 0 of the next month is the last day of this one.
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    return Column(children: [
      Row(children: [
        Expanded(child: MyText(
          text: '${kMonthNames[_month.month - 1]} ${_month.year}',
          size: AppTextScale.subtitle, weight: AppWeights.bold,
          color: kBlackColor,
        )),
        _navButton(Icons.chevron_left, 'Previous month', () => _shift(-1)),
        const SizedBox(width: AppSizes.s8),
        _navButton(Icons.chevron_right, 'Next month', () => _shift(1)),
      ]),
      const SizedBox(height: AppSizes.s12),
      Row(children: [
        for (final label in _kWeekdays)
          Expanded(child: Center(child: MyText(
            text: label, size: AppTextScale.caption, color: kGreyTextColor,
            weight: AppWeights.medium,
          ))),
      ]),
      const SizedBox(height: AppSizes.s8),
      GridView.builder(
        // Inside a scrolling page, so it must not scroll itself.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: leading + daysInMonth,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, i) {
          if (i < leading) return const SizedBox.shrink();
          final day = DateTime(_month.year, _month.month, i - leading + 1);
          return _dayCell(day);
        },
      ),
    ]);
  }

  Widget _navButton(IconData icon, String label, VoidCallback onTap) =>
      Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          // The padding IS the touch target; a bare 20px glyph is under the
          // 48dp floor and these sit at the top of a long form.
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s12),
            child: Icon(icon, size: AppSizes.s20, color: kBlackColor),
          ),
        ),
      );

  /// The comp's selected day: a PALE disc with the brand colour on top,
  /// not a solid one with white text.
  ///
  /// White-on-orange is the louder of the two and was here first, but this
  /// grid sits directly above a row of slot chips that mark their own
  /// selection the same pale way. Two different visual answers to 'this is
  /// the one you picked', six lines apart, is the reading a buyer has to
  /// stop and do.
  Widget _dayCell(DateTime day) {
    final selected = isSameDay(day, widget.selected);
    final disabled = _isDisabled(day);
    return Center(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: !disabled,
        child: GestureDetector(
          onTap: disabled ? null : () => widget.onSelect(day),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? kSecondaryColor.withValues(alpha: .14)
                  : kTransperentColor,
              shape: BoxShape.circle,
            ),
            child: MyText(
              text: '${day.day}',
              size: AppTextScale.label,
              weight: selected ? AppWeights.bold : AppWeights.regular,
              color: selected
                  ? kSecondaryColor
                  : disabled
                      ? kGreyTextColor.withValues(alpha: .4)
                      : kBlackColor,
            ),
          ),
        ),
      ),
    );
  }
}

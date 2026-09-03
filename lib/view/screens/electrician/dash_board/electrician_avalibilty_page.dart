import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usage:
//   body: ElectricianAvailabilityPage()
// ─────────────────────────────────────────────────────────────────────────────

class ElectricianAvailabilityPage extends StatefulWidget {
  const ElectricianAvailabilityPage({super.key});

  @override
  State<ElectricianAvailabilityPage> createState() =>
      _ElectricianAvailabilityPageState();
}

class _ElectricianAvailabilityPageState
    extends State<ElectricianAvailabilityPage> {
  // ── Week days data ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _weekDays = [
    {'short': 'MON', 'date': 14, 'hasBooking': false},
    {'short': 'TUE', 'date': 15, 'hasBooking': false},
    {'short': 'WED', 'date': 16, 'hasBooking': false},
    {'short': 'THU', 'date': 17, 'hasBooking': false},
    {'short': 'FRI', 'date': 18, 'hasBooking': true}, // has clock indicator
  ];
  int _selectedDayIndex = 0;

  // ── Time slots state ───────────────────────────────────────────────────────
  // Each slot: label, timeRange, badge, badgeColor, icon, enabled, note
  final List<Map<String, dynamic>> _slots = [
    {
      'label': 'Morning',
      'timeRange': '08:00 AM – 12:00 PM',
      'badge': '2 BOOKINGS',
      'badgeColor': const Color(0xffE8EEFF),
      'badgeTextColor': const Color(0xff4A6CF7),
      'icon': Icons.wb_sunny_outlined,
      'iconColor': const Color(0xffF4A020),
      'enabled': true,
      'note': null,
    },
    {
      'label': 'Afternoon',
      'timeRange': '12:00 PM – 05:00 PM',
      'badge': 'AVAILABLE',
      'badgeColor': const Color(0xffE8F5E9),
      'badgeTextColor': const Color(0xff2E7D32),
      'icon': Icons.wb_sunny_rounded,
      'iconColor': const Color(0xffF4A020),
      'enabled': true,
      'note': null,
    },
    {
      'label': 'Evening',
      'timeRange': '05:00 PM – 09:00 PM',
      'badge': null,
      'badgeColor': null,
      'badgeTextColor': null,
      'icon': Icons.nightlight_round,
      'iconColor': const Color(0xff7986CB),
      'enabled': false,
      'note': 'Currently toggled off for personal errands.',
    },
  ];

  String get _selectedDayLabel => 'Oct ${_weekDays[_selectedDayIndex]['date']}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.DEFAULT,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyBackButton(),
              // ── Header ─────────────────────────────────────────────────────
              MyText(
                text: 'Availability',
                size: 28,
                weight: FontWeight.w800,
                color: kBlackColor,
                paddingBottom: 4,
              ),
              MyText(
                text: 'Manage your working hours and block vacation days.',
                size: 13,
                weight: FontWeight.w400,
                color: kGreyTextColor,
                paddingBottom: 28,
              ),

              // ── Date row ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText(
                    text: 'SELECT DATE',
                    size: 11,
                    weight: FontWeight.w700,
                    color: kGreyTextColor,
                  ),
                  MyText(
                    text: 'October 2024',
                    size: 13,
                    weight: FontWeight.w700,
                    color: kSecondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Week strip ─────────────────────────────────────────────────
              _buildWeekStrip(),
              const SizedBox(height: 28),

              // ── Time slots label ───────────────────────────────────────────
              MyText(
                text: 'TIME SLOTS FOR $_selectedDayLabel'.toUpperCase(),
                size: 11,
                weight: FontWeight.w700,
                color: kGreyTextColor,
                paddingBottom: 16,
              ),

              // ── Time slot cards ────────────────────────────────────────────
              ..._slots.asMap().entries.map(
                (e) => _buildSlotCard(e.key, e.value),
              ),

              const SizedBox(height: 8),

              // ── Block full day row ─────────────────────────────────────────
              _buildBlockFullDay(),
              const SizedBox(height: 16),

              // ── Quick tip card ─────────────────────────────────────────────
              _buildQuickTip(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Week Strip ─────────────────────────────────────────────────────────────
  Widget _buildWeekStrip() {
    return Row(
      children: List.generate(_weekDays.length, (i) {
        final day = _weekDays[i];
        final isSelected = _selectedDayIndex == i;
        final hasIndicator = day['hasBooking'] as bool;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _weekDays.length - 1 ? 8 : 0),
            child: MyRippleEffect(
              onTap: () => setState(() => _selectedDayIndex = i),
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
                      text: day['short'],
                      size: 10,
                      weight: FontWeight.w600,
                      color: isSelected ? kWhiteColor : kGreyTextColor,
                    ),
                    const SizedBox(height: 4),
                    MyText(
                      text: '${day['date']}',
                      size: 20,
                      weight: FontWeight.w800,
                      color: isSelected ? kWhiteColor : kBlackColor,
                    ),
                    const SizedBox(height: 4),
                    // Dot or clock indicator
                    hasIndicator && !isSelected
                        ? Icon(
                            Icons.watch_later_outlined,
                            size: 12,
                            color: kSecondaryColor,
                          )
                        : Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? kWhiteColor.withOpacity(0.6)
                                  : kTransperentColor,
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

  // ── Slot Card ──────────────────────────────────────────────────────────────
  Widget _buildSlotCard(int index, Map<String, dynamic> slot) {
    final bool enabled = slot['enabled'] as bool;

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
          // Top row: icon + toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                slot['icon'] as IconData,
                size: 20,
                color: slot['iconColor'] as Color,
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: enabled,
                  activeColor: kSecondaryColor,
                  activeTrackColor: kSecondaryColor.withOpacity(0.25),
                  inactiveThumbColor: kGreyTextColor.withOpacity(0.5),
                  inactiveTrackColor: kTertiaryColor,
                  onChanged: (val) => setState(() {
                    _slots[index]['enabled'] = val;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Label
          MyText(
            text: slot['label'],
            size: 18,
            weight: FontWeight.w700,
            color: enabled ? kBlackColor : kGreyTextColor,
            paddingBottom: 2,
          ),

          // Time range
          MyText(
            text: slot['timeRange'],
            size: 13,
            weight: FontWeight.w400,
            color: kGreyTextColor,
            paddingBottom: slot['badge'] != null || slot['note'] != null
                ? 10
                : 0,
          ),

          // Badge
          if (slot['badge'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: slot['badgeColor'] as Color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: MyText(
                text: slot['badge'],
                size: 10,
                weight: FontWeight.w700,
                color: slot['badgeTextColor'] as Color,
              ),
            ),

          // Disabled note
          if (slot['note'] != null)
            MyText(
              text: slot['note'],
              size: 12,
              weight: FontWeight.w500,
              color: kSecondaryColor,
              paddingTop: 2,
            ),
        ],
      ),
    );
  }

  // ── Block Full Day ─────────────────────────────────────────────────────────
  Widget _buildBlockFullDay() {
    return MyRippleEffect(
      onTap: () {},
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
                text: 'Block full day for $_selectedDayLabel',
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

  // ── Quick Tip ──────────────────────────────────────────────────────────────
  Widget _buildQuickTip() {
    return Container(
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
            decoration: BoxDecoration(
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
                  text:
                      'Blocking a date will automatically cancel any non-confirmed appointments. Clients will be notified via SMS.',
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
}

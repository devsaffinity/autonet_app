import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/buyer/services/booking_confirmed.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class NewBookingPage extends StatefulWidget {
  const NewBookingPage({super.key});

  @override
  State<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends State<NewBookingPage> {
  // ── Calendar state
  DateTime _focusedMonth = DateTime(2024, 10);
  DateTime? _selectedDate = DateTime(2024, 10, 15);

  // ── Selected time slot
  String? _selectedSlot = '11:30 AM';

  // ── Controllers
  final _serviceController = TextEditingController(text: 'Rewiring');
  final _carModelController = TextEditingController(text: 'Nisson GTR');

  // ── Time slots
  static const List<String> _morningSlots = ['06:00 AM', '10:30 AM'];
  static const List<String> _afternoonSlots = [
    '11:30 AM',
    '02:00 PM',
    '03:30 PM',
    '05:00 PM',
  ];

  @override
  void dispose() {
    _serviceController.dispose();
    _carModelController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "New Booking", centerdTitle: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Booking with
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kBlackColor,
                      ),
                      children: [
                        const TextSpan(text: 'Booking with '),
                        TextSpan(
                          text: 'Larry Allison',
                          style: const TextStyle(color: kSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  MyText(
                    text:
                        'Select your preferred date and time for premium vehicle diagnostics and luminance tuning.',
                    size: 12,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                    paddingBottom: 16,
                  ),

                  // ── Calendar Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBlackColor.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ── Month nav
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            MyText(
                              text:
                                  '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                              size: 15,
                              weight: FontWeight.w700,
                              color: kBlackColor,
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _previousMonth,
                                  child: const Icon(
                                    Icons.chevron_left,
                                    size: 22,
                                    color: kBlackColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _nextMonth,
                                  child: const Icon(
                                    Icons.chevron_right,
                                    size: 22,
                                    color: kBlackColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Day headers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children:
                              ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                                  .map(
                                    (d) => SizedBox(
                                      width: 30,
                                      child: Center(
                                        child: MyText(
                                          text: d,
                                          size: 10,
                                          weight: FontWeight.w600,
                                          color: kGreyTextColor,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 8),

                        // ── Calendar grid
                        _buildCalendarGrid(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Selected slot label
                  MyText(
                    text: 'Selected slot',
                    size: 16,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                  MyText(
                    text: _selectedDate != null
                        ? 'October ${_selectedDate!.day}, 2024'
                        : 'No date selected',
                    size: 12,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                    paddingBottom: 12,
                  ),

                  // ── Morning slots
                  MyText(
                    text: 'Morning',
                    size: 16,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                    paddingBottom: 8,
                  ),
                  _TimeSlotRow(
                    slots: _morningSlots,
                    selectedSlot: _selectedSlot,
                    onSlotTap: (s) => setState(() => _selectedSlot = s),
                  ),

                  const SizedBox(height: 10),

                  // ── Afternoon slots
                  MyText(
                    text: 'Afternoon',
                    size: 16,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                    paddingBottom: 8,
                  ),
                  _TimeSlotRow(
                    slots: _afternoonSlots,
                    selectedSlot: _selectedSlot,
                    onSlotTap: (s) => setState(() => _selectedSlot = s),
                  ),

                  const SizedBox(height: 16),

                  // ── Required Service
                  MyTextField(
                    radius: 9,
                    labelText: 'Required Service',
                    controller: _serviceController,
                    marginBottom: 14,
                  ),

                  // ── Car Model
                  MyTextField(
                    radius: 9,
                    labelText: 'Car Model',
                    controller: _carModelController,
                    marginBottom: 14,
                  ),

                  // ── Location
                  MyText(
                    text: 'Location',
                    size: 16,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                    paddingBottom: 8,
                  ),
                  _MapCard(),

                  const SizedBox(height: 10),

                  // ── Approx duration note
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: kGreyTextColor,
                      ),
                      const SizedBox(width: 6),
                      MyText(
                        text: 'Approximate service duration: 90 mins',
                        size: 11,
                        color: kGreyTextColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Summary bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBlackColor.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(
                                text: 'SELECTED DATE',
                                size: 10,
                                color: kGreyTextColor,
                                weight: FontWeight.w500,
                              ),
                              MyText(
                                text: 'Oct 15, 2024',
                                size: 13,
                                weight: FontWeight.w700,
                                color: kBlackColor,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: kBlackColor.withOpacity(0.1),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyText(
                                  text: 'TIME SLOT',
                                  size: 10,
                                  color: kGreyTextColor,
                                  weight: FontWeight.w500,
                                ),
                                MyText(
                                  text: _selectedSlot ?? '--',
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: kBlackColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── Confirm button
          Container(
            color: kPrimaryColor,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: MyButton(
              buttonText: 'Confirm Selection',
              height: 52,
              fontSize: 15,
              onTap: () {
                Get.to(() => BookingConfirmedPage());
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Build calendar grid
  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // Monday-based offset (1=Mon ... 7=Sun)
    int startOffset = firstDay.weekday - 1;
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;

    final List<Widget> cells = [];

    // Empty cells before first day
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox(width: 30, height: 30));
    }

    // Day cells
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final isSelected =
          _selectedDate != null &&
          _selectedDate!.day == d &&
          _selectedDate!.month == _focusedMonth.month &&
          _selectedDate!.year == _focusedMonth.year;

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isSelected ? kSecondaryColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: MyText(
                text: '$d',
                size: 13,
                weight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? kWhiteColor : kBlackColor,
              ),
            ),
          ),
        ),
      );
    }

    // Build rows of 7
    final List<Widget> rows = [];
    for (int i = 0; i < cells.length; i += 7) {
      final rowCells = cells.sublist(
        i,
        i + 7 > cells.length ? cells.length : i + 7,
      );
      // Pad last row
      while (rowCells.length < 7) {
        rowCells.add(const SizedBox(width: 30, height: 30));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rowCells,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time Slot Row
// ─────────────────────────────────────────────────────────────────────────────

class _TimeSlotRow extends StatelessWidget {
  final List<String> slots;
  final String? selectedSlot;
  final ValueChanged<String> onSlotTap;

  const _TimeSlotRow({
    required this.slots,
    required this.selectedSlot,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: slots.map((s) {
        final isSelected = selectedSlot == s;
        return GestureDetector(
          onTap: () => onSlotTap(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? kSecondaryColor : kPrimaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? kSecondaryColor
                    : kBlackColor.withOpacity(0.15),
              ),
            ),
            child: MyText(
              text: s,
              size: 13,
              color: isSelected ? kWhiteColor : kBlackColor,
              weight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Card (static placeholder with red tint)
// ─────────────────────────────────────────────────────────────────────────────

class _MapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSecondaryColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // ── Map image
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  kSecondaryColor.withOpacity(0.15),
                  BlendMode.srcOver,
                ),
                child: Image.asset(
                  Assets.imagesMapImage1,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: kSecondaryColor.withOpacity(0.08),
                    child: Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 40,
                        color: kSecondaryColor.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Service location label
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),

                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: AppStyling().myDecoration(
                        color: kSecondaryColor,
                        borderColor: kTransperentColor,
                        radius: 7,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: kWhiteColor,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: 'SERVICE LOCATION',
                          size: 12,
                          color: kWhiteColor,
                          weight: FontWeight.w600,
                        ),
                        MyText(
                          text: 'Precision Performance Center, Bay 4',
                          size: 12,
                          color: kWhiteColor,
                          weight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

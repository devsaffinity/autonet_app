import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/electrician/dash_board/electrician_avalibilty_page.dart';
import 'package:autonect/view/screens/electrician/home/upcoming_booking_details.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_pill_tabs.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usage:
//   body: ElectricianBookingRequestPage()
// ─────────────────────────────────────────────────────────────────────────────

class ElectricianBookingRequestPage extends StatefulWidget {
  const ElectricianBookingRequestPage({super.key});

  @override
  State<ElectricianBookingRequestPage> createState() =>
      _ElectricianBookingRequestPageState();
}

class _ElectricianBookingRequestPageState
    extends State<ElectricianBookingRequestPage> {
  // ── Tabs ───────────────────────────────────────────────────────────────────
  int _selectedTab = 0;
  final List<String> _tabs = ['Pending', 'Instant Bookings'];

  // ── Booking requests data ──────────────────────────────────────────────────
  final List<Map<String, dynamic>> _requests = [
    {
      'image': Assets.imagesCar1,
      'name': 'Sarah Jenkins',
      'carBadge': 'AUDI A4',
      'service': 'ECU Remapping — Stage 1',
      'date': 'Oct 24, 2023',
      'time': '09:30 AM',
      'location': 'On-site Service',
    },
    {
      'image': Assets.imagesCar1,
      'name': 'Michael Thorne',
      'carBadge': 'BMW M3',
      'service': 'Performance Exhaust Install',
      'date': 'Oct 25, 2023',
      'time': '02:15 PM',
      'location': null,
    },
  ];

  // ── Performance metrics ────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _metrics = [
    {'label': 'Response Time', 'value': '12m', 'progress': 0.52},
    {'label': 'Acceptance Rate', 'value': '94%', 'progress': 0.94},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.DEFAULT,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              MyText(
                text: 'PROVIDER DASHBOARD',
                size: 10,
                weight: FontWeight.w700,
                color: kSecondaryColor,
                paddingBottom: 4,
                paddingTop: 10,
                letterSpacing: 1,
              ),
              MyText(
                text: 'Booking Requests',
                size: 26,
                weight: FontWeight.w800,
                color: kBlackColor,
                paddingBottom: 16,
              ),

              // ── Tab bar ─────────────────────────────────────────────────
              MyPillTabs(
                labels: _tabs,
                selectedIndex: _selectedTab,
                onChanged: (i) => setState(() => _selectedTab = i),
              ),
              const SizedBox(height: 24),

              // ── Booking request cards ────────────────────────────────────
              if (_selectedTab == 0) ...[
                if (_requests.isEmpty)
                  _buildEmptyState('No pending requests right now')
                else
                  ..._requests.map((r) => _buildRequestCard(r)),
                const SizedBox(height: 8),

                // ── Availability Status ──────────────────────────────────
                _buildAvailabilityStatus(),
                const SizedBox(height: 24),

                // ── Performance ──────────────────────────────────────────
                _buildPerformance(),
              ] else
                _buildEmptyState('No instant bookings yet'),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  void _openDetails(Map<String, dynamic> r) {
    Get.to(
      () => ElectricianBookingDetailsPage(
        clientName: r['name'] as String,
        service: r['service'] as String,
        vehicle: r['carBadge'] as String,
        date: r['date'] as String,
        time: r['time'] as String,
        location: (r['location'] as String?) ?? 'On-site Service',
        isPremiumClient: false,
        bookingCount: 'NEW CLIENT',
      ),
    );
  }

  void _accept(Map<String, dynamic> r) {
    setState(() => _requests.remove(r));
    _openDetails(r);
  }

  void _decline(Map<String, dynamic> r) {
    setState(() => _requests.remove(r));
    Get.snackbar(
      'Request declined',
      '${r['name']} has been notified.',
      backgroundColor: kWhiteColor,
    );
  }

  // ── Single Request Card ────────────────────────────────────────────────────
  Widget _buildRequestCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: AppStyling().myShadowStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car image — opens the full booking brief
          MyRippleEffect(
            onTap: () => _openDetails(r),
            radius: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CommonImageView(
                imagePath: r['image'],
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Name + car badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: MyText(
                  text: r['name'],
                  size: 18,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kLightBlueColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: MyText(
                  text: r['carBadge'],
                  size: 11,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Service
          MyText(
            text: r['service'],
            size: 14,
            weight: FontWeight.w600,
            color: kSecondaryColor,
            paddingBottom: 10,
          ),

          // Date + Time row
          Row(
            children: [
              _iconText(Icons.calendar_today_outlined, r['date']),
              const SizedBox(width: 16),
              _iconText(Icons.access_time_rounded, r['time']),
            ],
          ),

          // Location (optional)
          if (r['location'] != null) ...[
            const SizedBox(height: 6),
            _iconText(Icons.location_on_outlined, r['location']),
          ],
          const SizedBox(height: 16),

          // Buttons row
          Row(
            children: [
              Expanded(
                child: MyButton(
                  buttonText: 'Accept Request',
                  onTap: () => _accept(r),
                  backgroundColor: kSecondaryColor,
                  fontColor: kWhiteColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 46,
                  radius: 100,
                ),
              ),
              const SizedBox(width: 16),
              MyRippleEffect(
                onTap: () => _decline(r),
                radius: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: MyText(
                    text: 'Decline',
                    size: 14,
                    weight: FontWeight.w600,
                    color: kBlackColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: kTertiaryColor, height: 1),
        ],
      ),
    );
  }

  // ── Availability Status ────────────────────────────────────────────────────
  Widget _buildAvailabilityStatus() {
    return MyRippleEffect(
      // "Open calendar to manage capacity" now actually opens the calendar.
      onTap: () => Get.to(() => const ElectricianAvailabilityPage()),
      radius: 14,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffEEF2FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              text: 'AVAILABILITY STATUS',
              size: 10,
              weight: FontWeight.w700,
              color: kBlackColor,
              paddingBottom: 10,
            ),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xff34C759),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                MyText(
                  text: 'Active Today',
                  size: 16,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            MyText(
              text:
                  'You have 4 slots remaining for next week. Open calendar to manage capacity.',
              size: 14,
              weight: FontWeight.w400,
              color: kBlackColor,
            ),
          ],
        ),
      ),
    );
  }

  // ── Performance ───────────────────────────────────────────────────────────
  Widget _buildPerformance() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: AppStyling().myShadowStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'Performance',
            size: 18,
            weight: FontWeight.w800,
            color: kBlackColor,
            paddingBottom: 16,
          ),
          ..._metrics.map((m) => _buildMetricRow(m)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(Map<String, dynamic> m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text: m['label'],
                size: 13,
                weight: FontWeight.w500,
                color: kBlackColor,
              ),
              MyText(
                text: m['value'],
                size: 13,
                weight: FontWeight.w700,
                color: kSecondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: m['progress'] as double,
              backgroundColor: kTertiaryColor,
              valueColor: const AlwaysStoppedAnimation<Color>(kSecondaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: kGreyTextColor.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          MyText(
            text: message,
            size: 14,
            weight: FontWeight.w500,
            color: kGreyTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Helper: icon + text row ────────────────────────────────────────────────
  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kBlackColor),
        const SizedBox(width: 5),
        MyText(
          text: text,
          size: 13,
          weight: FontWeight.w400,
          color: kBlackColor,
        ),
      ],
    );
  }
}

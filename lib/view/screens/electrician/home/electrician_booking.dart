import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/electrician/home/upcoming_booking_details.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ElectricianMyBookingsPage extends StatefulWidget {
  const ElectricianMyBookingsPage({super.key});

  @override
  State<ElectricianMyBookingsPage> createState() =>
      _ElectricianMyBookingsPageState();
}

class _ElectricianMyBookingsPageState extends State<ElectricianMyBookingsPage> {
  final List<String> _tabs = ['Upcoming', 'Completed', 'Cancelled'];
  int _selectedTab = 0;

  // ── Booking data ────
  // status: 'inprogress' | 'confirmed' | 'premium'
  final List<Map<String, dynamic>> _upcomingBookings = [
    {
      'status': 'inprogress',
      'statusLabel': 'IN PROGRESS',
      'name': 'Marcus Chen',
      'date': 'Today, Oct 24',
      'time': '09:00 AM – 11:30 AM',
      'service': 'Electrical Diagnostic',
      'actionLabel': 'ACTIVE SESSION',
      'icon': Icons.build_outlined,
      'iconBg': const Color(0xffEAEEFB),
      'iconColor': kSecondaryColor,
    },
    {
      'status': 'confirmed',
      'statusLabel': 'CONFIRMED',
      'name': 'Elena Rodriguez',
      'date': 'Tomorrow, Oct 25',
      'time': '02:30 PM – 04:00 PM',
      'service': 'Pipe Leak Repair',
      'actionLabel': 'VIEW DETAILS',
      'icon': Icons.water_drop_outlined,
      'iconBg': const Color(0xffFFF0EE),
      'iconColor': kSecondaryColor,
    },
    {
      'status': 'confirmed',
      'statusLabel': 'CONFIRMED',
      'name': 'Sarah Jenkins',
      'date': 'Mon, Oct 28',
      'time': '10:00 AM – 12:00 PM',
      'service': 'AC Maintenance',
      'actionLabel': 'VIEW DETAILS',
      'icon': Icons.settings_outlined,
      'iconBg': const Color(0xffF0F4FF),
      'iconColor': kSecondaryColor,
    },
    {
      'status': 'premium',
      'statusLabel': 'UPCOMING • PREMIUM CLIENT',
      'name': 'Riverview Corporate Plaza',
      'date': 'Wed, Oct 30',
      'location': 'Downtown Hub',
      'service':
          'Multi-unit electrical inspection and safety certification for Phase 2 office wing.',
      'price': '\$450.00',
      'priceLabel': 'ESTIMATED PAY',
      'icon': Icons.apartment_outlined,
      'iconBg': const Color(0xffFFF0EE),
      'iconColor': kSecondaryColor,
    },
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
              // ── Page title ────
              MyText(
                text: 'Bookings',
                size: 36,
                weight: FontWeight.w800,
                color: kBlackColor,
                paddingBottom: 8,
                paddingTop: 10,
              ),
              MyText(
                text: 'Manage your service pipeline and client schedule.',
                size: 16,
                weight: FontWeight.w500,
                color: kGreyTextColor,
                paddingBottom: 32,
              ),

              // ── Tab bar ───
              _buildTabBar(),
              const SizedBox(height: 28),

              // ── Booking cards ─────
              if (_selectedTab == 0) ...[
                ..._upcomingBookings.map((b) => _buildBookingCard(b)),
                const SizedBox(height: 16),
                _buildWeeklyForecast(),
              ] else
                _buildEmptyState(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab Bar ───
  Widget _buildTabBar() {
    return Container(
      height: 52,
      decoration: AppStyling().myDecoration(
        color: Colors.deepPurpleAccent.withValues(alpha: .1),
        borderColor: kTransperentColor,
        radius: 100,
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: MyRippleEffect(
              onTap: () => setState(() => _selectedTab = i),
              radius: 100,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? kSecondaryColor : kTransperentColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: MyText(
                  text: _tabs[i],
                  size: 14,
                  weight: FontWeight.w600,
                  color: isSelected ? kWhiteColor : kBlackColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Open the brief for the tapped row ─────
  void _openDetails(Map<String, dynamic> b) {
    Get.to(
      () => ElectricianBookingDetailsPage(
        clientName: b['name'] as String,
        service: b['service'] as String,
        date: b['date'] as String,
        time: (b['time'] as String?) ?? 'To be confirmed',
        location: (b['location'] as String?) ?? 'Downtown District, Sector 7',
        fee: (b['price'] as String?) ?? '\$285.00',
        isPremiumClient: b['status'] == 'premium',
      ),
    );
  }

  // ── Booking Card dispatcher ─────
  Widget _buildBookingCard(Map<String, dynamic> b) {
    if (b['status'] == 'premium') return _buildPremiumCard(b);
    return _buildStandardCard(b);
  }

  // ── Standard card (inprogress / confirmed) ─────
  Widget _buildStandardCard(Map<String, dynamic> b) {
    final bool isInProgress = b['status'] == 'inprogress';
    final Color statusColor = isInProgress
        ? const Color(0xff4A6CF7)
        : kSecondaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status label
          MyText(
            text: b['statusLabel'],
            size: 10,
            weight: FontWeight.w700,
            color: statusColor,
            paddingBottom: 4,
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: b['name'],
                      size: 20,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                      paddingBottom: 10,
                    ),
                    _infoRow(Icons.calendar_today_outlined, b['date']),
                    const SizedBox(height: 6),
                    _infoRow(Icons.access_time_rounded, b['time']),
                    const SizedBox(height: 6),
                    _infoRow(Icons.build_outlined, b['service']),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Icon bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: b['iconBg'] as Color,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(
                  b['icon'] as IconData,
                  size: 22,
                  color: b['iconColor'] as Color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Action row
          MyRippleEffect(
            onTap: () => _openDetails(b),
            radius: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(
                  text: b['actionLabel'],
                  size: 12,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: kSecondaryColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Premium card ────
  Widget _buildPremiumCard(Map<String, dynamic> b) {
    return MyRippleEffect(
      onTap: () => _openDetails(b),
      radius: 20,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status label + icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: b['statusLabel'],
                      size: 10,
                      weight: FontWeight.w600,
                      color: kSecondaryColor,
                      paddingBottom: 8,
                    ),

                    // Name
                    MyText(
                      text: b['name'],
                      size: 22,
                      weight: FontWeight.w800,
                      color: kBlackColor,
                      paddingBottom: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: b['iconBg'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  b['icon'] as IconData,
                  size: 22,
                  color: b['iconColor'] as Color,
                ),
              ),
            ],
          ),

          // Description
          MyText(
            text: b['service'],
            size: 14,
            weight: FontWeight.w400,
            color: kBlackColor,
            paddingBottom: 16,
          ),

          // Date + location row
          Row(
            children: [
              _infoRowWidget(Icons.calendar_today_outlined, b['date']),
              const SizedBox(width: 16),
              _infoRowWidget(Icons.location_on_outlined, b['location']),
            ],
          ),

          const SizedBox(height: 16),

          // Price box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: AppStyling().myDecoration(
              color: Colors.deepPurple.withValues(alpha: .1),
              borderColor: kTertiaryColor,
              radius: 20,
            ),
            child: Column(
              children: [
                MyText(
                  text: b['price'],
                  size: 24,
                  weight: FontWeight.w900,
                  color: kSecondaryColor,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                MyText(
                  text: b['priceLabel'],
                  size: 10,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  // ── Weekly Forecast card ───
  Widget _buildWeeklyForecast() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: AppStyling().myDecoration(
        color: kSecondaryColor,
        borderColor: kTertiaryColor,
        radius: 24,
      ),
      child: Stack(
        children: [
          // Decorative trend icon
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.trending_up_rounded,
              size: 60,
              color: kWhiteColor.withOpacity(0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Weekly Forecast',
                size: 18,
                weight: FontWeight.w700,
                color: kWhiteColor,
                paddingBottom: 4,
              ),
              MyText(
                text: '8 new bookings confirmed since Monday.',
                size: 14,
                weight: FontWeight.w400,
                color: kWhiteColor.withOpacity(0.6),
                paddingBottom: 16,
              ),
              MyText(
                text: '14',
                size: 36,
                weight: FontWeight.w900,
                color: kWhiteColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: kGreyTextColor.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          MyText(
            text: 'No bookings here yet',
            size: 15,
            weight: FontWeight.w600,
            color: kGreyTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Info row helpers ──
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: kBlackColor),
        const SizedBox(width: 6),
        Expanded(
          child: MyText(
            text: text,
            size: 14,
            weight: FontWeight.w400,
            color: kBlackColor,
          ),
        ),
      ],
    );
  }

  Widget _infoRowWidget(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kBlackColor),
        const SizedBox(width: 4),
        MyText(
          text: text,
          size: 14,
          weight: FontWeight.w600,
          color: kBlackColor,
        ),
      ],
    );
  }
}

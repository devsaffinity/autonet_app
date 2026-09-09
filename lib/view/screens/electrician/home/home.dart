import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/electrician/availability_controller.dart';
import 'package:autonect/controller/electrician/provider_bookings_controller.dart';
import 'package:autonect/controller/electrician/provider_dashboard_controller.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/provider_dashboard.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/electrician/dash_board/electrician_avalibilty_page.dart';
import 'package:autonect/view/screens/electrician/dash_board/manage_services.dart';
import 'package:autonect/view/screens/electrician/dash_board/total_balance.dart';
import 'package:autonect/view/screens/electrician/home/upcoming_booking_details.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ElectricianHomePage extends StatefulWidget {
  const ElectricianHomePage({super.key});

  @override
  State<ElectricianHomePage> createState() => _ElectricianHomePageState();
}

class _ElectricianHomePageState extends State<ElectricianHomePage> {
  final ProviderDashboardController _dashboard =
      ProviderDashboardController.ensure();
  final ProviderBookingsController _bookings =
      ProviderBookingsController.ensure();
  final AvailabilityController _availability = AvailabilityController.ensure();

  @override
  void initState() {
    super.initState();
    // Three independent reads, each with its own slot, so a slow one never
    // holds up the rest of the screen.
    _dashboard.load();
    _bookings.refreshFirst();
    _availability.load();
  }

  // ── Quick Management actions ─────
  final List<Map<String, dynamic>> _quickActions = [
    {'label': 'Manage Slots', 'icon': Assets.imagesQmA},
    {'label': 'Edit Services', 'icon': Assets.imagesQmB},
    {'label': 'View Reports', 'icon': Assets.imagesQmC},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildPerformanceCard(),
              const SizedBox(height: 12),
              _buildEarningsCard(),
              const SizedBox(height: 20),
              _buildQuickManagement(),
              const SizedBox(height: 20),
              _buildUpcomingBookings(),
              const SizedBox(height: 20),
              _buildMessages(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: AppStyling().myDecoration(
            color: kSecondaryColor,
            borderColor: kSecondaryColor,
            radius: 100,
          ),
          padding: EdgeInsets.all(.3),
          child: ClipOval(
            child: CommonImageView(
              imagePath: Assets.imagesProfileImage,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Good morning,',
                size: 14,
                weight: FontWeight.w400,
                color: kGreyTextColor,
              ),
              MyText(
                text: 'Alex Chen',
                size: 16,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
            ],
          ),
        ),

        // Online toggle
        MyRippleEffect(
          onTap: () => Get.to(() => const ElectricianAvailabilityPage()),
          radius: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: AppStyling().myDecoration(
              color: kSecondaryColor.withValues(alpha: .1),
              radius: 100,
              borderColor: kTransperentColor,
            ),
            child: Row(
              children: [
                // ONLINE was a local bool nothing acted on — a provider could
                // switch to OFFLINE and still be booked all day. What actually
                // decides that is their schedule, so this reflects it and taps
                // through to the screen that changes it.
                Obx(() {
                  final working = _availability.worksToday;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: working
                              ? const Color(0xff34C759)
                              : kGreyTextColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      MyText(
                        text: working ? 'WORKING TODAY' : 'OFF TODAY',
                        size: 12,
                        weight: FontWeight.w600,
                        color: kBlackColor,
                      ),
                    ],
                  );
                }),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: kBlackColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Bell
        MyRippleEffect(
          onTap: () {},
          radius: 20,
          child: CommonImageView(svgPath: Assets.imagesNotification),
        ),
      ],
    );
  }

  /// Work coming up and work waiting on an answer.
  ///
  /// The card used to read '4 Bookings / 20% increase from yesterday'. Nothing
  /// computed either figure, and no comparison against yesterday exists to
  /// compute — so it says what the data actually supports.
  Widget _buildPerformanceCard() {
    return Obx(() {
      final state = _dashboard.state.value;
      final d = state is Data<ProviderDashboard> ? state.value : null;
      return _performanceCard(
        headline: d == null
            ? '—'
            : '${d.upcomingCount} '
                  '${d.upcomingCount == 1 ? 'booking' : 'bookings'}',
        sub: d == null
            ? 'Loading your day'
            : d.pendingCount == 0
            ? 'Nothing waiting on you'
            : '${d.pendingCount} '
                  '${d.pendingCount == 1 ? 'request needs' : 'requests need'} '
                  'your answer',
      );
    });
  }

  Widget _performanceCard({required String headline, required String sub}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: AppStyling().myDecoration(
        color: kSecondaryColor,
        borderColor: kTransperentColor,
        radius: 12,
      ),
      child: Stack(
        children: [
          // Decorative faint car icon
          Positioned(
            bottom: 0,
            right: -10,
            top: -4,
            child: Icon(
              Icons.calendar_month,
              size: 90,
              color: kWhiteColor.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Coming Up',
                size: 12,
                weight: FontWeight.w600,
                color: kWhiteColor.withValues(alpha: 0.8),
                paddingBottom: 6,
              ),
              MyText(
                text: headline,
                size: 24,
                weight: FontWeight.w700,
                color: kWhiteColor,
                paddingBottom: 8,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: kWhiteColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: MyText(
                      text: sub,
                      size: 14,
                      weight: FontWeight.w500,
                      color: kWhiteColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Earnings Card ──────
  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: AppStyling().myShadowDecoration(
        color: kWhiteColor,
        radius: 16,
        borderColor: kTransperentColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text: 'Work completed this week',
                size: 12,
                weight: FontWeight.w500,
                color: kGreyTextColor,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kLightOrangeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: kSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Obx(() {
            final state = _dashboard.state.value;
            final d = state is Data<ProviderDashboard> ? state.value : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: d == null ? '—' : formatPence(d.last7DaysPence),
                  size: 28,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                  paddingBottom: 4,
                ),
                // The progress bar and '75% of goal' are gone: there is no
                // earnings goal anywhere in the product to be 75% of, and a
                // bar with an invented denominator is a made-up figure with a
                // picture attached. This says who pays, which is the fact a
                // provider actually needs from this card.
                MyText(
                  text: 'Paid to you directly by each customer',
                  size: 11,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Quick Management ───────────────────────────────────────────────────────
  Widget _buildQuickManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Quick Management',
          size: 16,
          weight: FontWeight.w700,
          color: kBlackColor,
          paddingBottom: 12,
        ),
        // Wrap to let 3rd item wrap to next line on its own
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_quickActions.length, (i) {
            final action = _quickActions[i];
            return MyRippleEffect(
              radius: 12,
              child: Container(
                width: (MediaQuery.of(context).size.width - 32 - 12) / 2,
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                decoration: AppStyling().myShadowDecoration(
                  color: kPrimaryColor,
                  radius: 12,
                  borderColor: kTransperentColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonImageView(svgPath: action['icon']),
                    const SizedBox(height: 10),
                    MyText(
                      text: action['label'] as String,
                      size: 12,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                    ),
                  ],
                ),
              ),
              onTap: () {
                // The first two were crossed over: 'Manage Slots' opened the
                // services editor and 'Edit Services' opened the calendar.
                switch (i) {
                  case 0:
                    Get.to(() => const ElectricianAvailabilityPage());
                    break;
                  case 1:
                    Get.to(() => const ManageServicesPage());
                    break;
                  case 2:
                    Get.to(() => const TotalBalancePage());
                    break;
                }
              },
            );
          }),
        ),
      ],
    );
  }

  // ── Upcoming Bookings ──────────────────────────────────────────────────────
  Widget _buildUpcomingBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText(
              text: 'Upcoming Bookings',
              size: 16,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
            MyRippleEffect(
              // Null-aware: this page is also pushed standalone, where there
              // is no shell ancestor.
              onTap: () => RoleShell.maybeOf(context)?.goTo(1),
              radius: 6,
              child: MyText(
                text: 'View All',
                size: 13,
                weight: FontWeight.w600,
                color: kSecondaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // The rows are read HERE, in the Obx closure. Reading `state.value`
        // inside itemBuilder would subscribe to nothing — the list runs
        // outside the tracking zone — and GetX throws, which release paints
        // as a grey rectangle.
        Obx(() {
          final state = _bookings.state.value;
          final rows = state is Data<List<Booking>>
              ? state.value.where((b) => b.status != BookingStatus.cancelled).take(3).toList()
              : const <Booking>[];
          return Container(
            decoration: AppStyling().myShadowDecoration(
              color: kPrimaryColor,
              radius: 14,
              borderColor: kTransperentColor,
            ),
            child: rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 22,
                    ),
                    child: MyText(
                      text: state is Loading<List<Booking>>
                          ? 'Loading your bookings…'
                          : 'No bookings yet. They appear here as soon as a '
                                'customer books you.',
                      size: 13,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: kTertiaryColor,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (_, i) => _buildBookingRow(rows[i]),
                  ),
          );
        }),
      ],
    );
  }

  Widget _buildBookingRow(Booking booking) {
    // Every field falls back to something TRUE rather than to a plausible
    // placeholder: a buyer may not know their model, and a job is unpriced
    // until the provider quotes it. 'Not quoted yet' is information; a made-up
    // fee is not.
    final name = booking.buyer?.name?.trim();
    final client = (name == null || name.isEmpty) ? 'Customer' : name;
    final vehicle = booking.regNumber?.trim().isNotEmpty == true
        ? booking.regNumber!.trim()
        : 'Vehicle not given';
    final service = booking.serviceType?.label ?? 'Service';
    final fee = booking.earnedPence == null
        ? 'Not quoted yet'
        : formatPence(booking.earnedPence!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: () {
          Get.to(
            () => ElectricianBookingDetailsPage(
              clientName: client,
              clientImage: Assets.imagesProfileImage,
              service: service,
              vehicle: vehicle,
              time: formatClock(booking.scheduledAt.toLocal()),
              fee: fee,
              date: formatShortDate(booking.scheduledAt.toLocal()),
              bookingId: booking.id,
              myUserId: booking.electricianId,
            ),
          );
        },
        child: Row(
          children: [
            // Car image thumbnail
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kTertiaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CommonImageView(
                  imagePath: Assets.imagesProfileImage,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: client,
                    size: 14,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                  const SizedBox(height: 3),
                  MyText(
                    text: '$vehicle • $service',
                    size: 12,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kLightOrangeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: MyText(
                text: formatClock(booking.scheduledAt.toLocal()),
                size: 11,
                weight: FontWeight.w600,
                color: kSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Messages ───────────────────────────────────────────────────────────────
  Widget _buildMessages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MyText(
              text: 'Messages',
              size: 16,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
            // The unread badge said '2' unconditionally. Nothing counts
            // unread messages, so a badge here can only ever be wrong; it
            // comes back with the chat client.
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 10, vertical: 10),
          decoration: AppStyling().myShadowDecoration(
            color: kGreyTextColor.withValues(alpha: .1),
            radius: 14,
            borderColor: kTransperentColor,
          ),
          child: Column(
            children: [
              // The three conversations here were fabricated — named people
              // with quoted messages nobody sent. Chat has no client yet
              // (sending is socket-only server-side), so this says nothing
              // rather than something false; the section stays so the wiring
              // is a fill, not a rebuild.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: MyText(
                  text: 'No messages yet.',
                  size: 13,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
              ),
              const Divider(height: 1, color: kTertiaryColor),
              // Go to Messenger
              MyRippleEffect(
                onTap: () => RoleShell.maybeOf(context)?.goTo(3),
                radius: 0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: MyText(
                      text: 'Go to Messenger',
                      size: 14,
                      weight: FontWeight.w600,
                      color: kSecondaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow(Map<String, String> msg) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: AppStyling().myDecoration(
        color: kWhiteColor,
        borderColor: kTransperentColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kTertiaryColor,
              ),
              child: ClipOval(
                child: CommonImageView(
                  imagePath: msg['image'],
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyText(
                        text: msg['name']!,
                        size: 14,
                        weight: FontWeight.w600,
                        color: kBlackColor,
                      ),
                      MyText(
                        text: msg['time']!,
                        size: 11,
                        weight: FontWeight.w400,
                        color: kGreyTextColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  MyText(
                    text: msg['preview']!,
                    size: 12,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/controller/electrician/provider_bookings_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/screens/electrician/home/widgets/quote_dialog.dart';
import 'package:autonect/view/screens/electrician/profile/electrician_access_tier_page.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Electrician Booking Details Page.
///
/// Implemented to exact Figma fidelity:
/// 1. Client header with verified avatar badge, name, location, and peach badges
/// 2. Service Details card with robotic arm watermark, schedule/time boxes, duration & fee
/// 3. Vehicle Specs card with car icon, title, year, engine type, VIN, and last service
/// 4. Customer Notes card with left terracotta accent and light bubble
/// 5. Location / Map card with contour map, center marker, and floating route pill
/// 6. Bottom action bar with `...` options, pill `Chat`, and pill `Mark as Completed` CTA
///
/// Fully wired with backend:
/// - Real-time status advances via `BookingsRepository.advance`
/// - Chat navigation via `ChatRoomPage`
/// - Price quotation updates via `BookingsRepository.quote`
/// - Pull-to-refresh booking synchronization via `BookingsRepository.byId`
class ElectricianBookingDetailsPage extends StatefulWidget {
  final Booking? booking;
  final String clientName;
  final String clientImage;
  final String? clientAvatarUrl;
  final String location;
  final String service;
  final String date;
  final String time;
  final String duration;
  final String fee;
  final String vehicle;
  final String vehicleYear;
  final String bookingCount;
  final bool isPremiumClient;
  final String? bookingId;
  final String? myUserId;
  final String? customerNotes;
  final VoidCallback? onBookingUpdated;

  const ElectricianBookingDetailsPage({
    super.key,
    this.booking,
    this.clientName = 'Marcus Thorne',
    this.clientImage = Assets.imagesProfileImage,
    this.clientAvatarUrl,
    this.location = 'Downtown District, Sector 7',
    this.service = 'ECU Coding',
    this.date = 'Oct 24, 2023',
    this.time = '10:00 AM',
    this.duration = '1h 45m',
    this.fee = '\$285.00',
    this.vehicle = 'Porsche Taycan Turbo S',
    this.vehicleYear = 'Model Year: 2023',
    this.bookingCount = '12 BOOKINGS',
    this.isPremiumClient = true,
    this.bookingId,
    this.myUserId,
    this.customerNotes,
    this.onBookingUpdated,
  });

  @override
  State<ElectricianBookingDetailsPage> createState() =>
      _ElectricianBookingDetailsPageState();
}

class _ElectricianBookingDetailsPageState
    extends State<ElectricianBookingDetailsPage> {
  late Booking? _currentBooking;
  late BookingStatus? _status;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _status = widget.booking?.status;
    _fetchLatestBooking();
  }

  Future<void> _fetchLatestBooking() async {
    final id = _bookingId;
    if (id == null) return;
    if (Get.isRegistered<BookingsRepository>()) {
      final res = await Get.find<BookingsRepository>().byId(id);
      if (mounted && res is Ok<Booking>) {
        setState(() {
          _currentBooking = res.value;
          _status = res.value.status;
        });
      }
    }
  }

  String get _clientName =>
      _currentBooking?.buyer?.name?.trim().isNotEmpty == true
          ? _currentBooking!.buyer!.name!.trim()
          : widget.clientName;

  String? get _clientAvatarUrl =>
      _currentBooking?.buyer?.avatarUrl ?? widget.clientAvatarUrl;

  String get _service {
    if (_currentBooking?.serviceType != null) {
      if (_currentBooking!.serviceType == BookingServiceType.ecuCoding) {
        return 'ECU Coding';
      }
      return _currentBooking!.serviceType!.label;
    }
    return widget.service;
  }

  String get _date => _currentBooking != null
      ? formatDayMonthYear(_currentBooking!.scheduledAt.toLocal())
      : widget.date;

  String get _time => _currentBooking != null
      ? formatClock(_currentBooking!.scheduledAt.toLocal())
      : widget.time;

  String get _duration => _currentBooking?.durationMins != null
      ? '${_currentBooking!.durationMins}m'
      : widget.duration;

  String get _fee {
    if (_currentBooking != null) {
      if (_currentBooking!.earnedPence != null) {
        return formatPence(_currentBooking!.earnedPence!);
      }
      if (_currentBooking!.quotedPence != null) {
        return formatPence(_currentBooking!.quotedPence!);
      }
      return 'Awaiting quote';
    }
    return widget.fee;
  }

  String get _vehicle =>
      _currentBooking?.regNumber?.trim().isNotEmpty == true
          ? _currentBooking!.regNumber!.trim()
          : widget.vehicle;

  String get _vehicleYear => _currentBooking?.regNumber != null
      ? 'Reg: ${_currentBooking!.regNumber}'
      : widget.vehicleYear;

  String get _location =>
      _currentBooking?.location?.trim().isNotEmpty == true
          ? _currentBooking!.location!.trim()
          : widget.location;

  String get _notes =>
      widget.customerNotes ??
      _currentBooking?.description ??
      'Please check my sensor wiring around the rear bumper assembly. Getting intermittent proximity warnings after the last car wash. ECU coding should focus on the performance throttle map adjustment as discussed.';

  String? get _bookingId => _currentBooking?.id ?? widget.bookingId;
  String? get _myUserId => _currentBooking?.electricianId ?? widget.myUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      appBar: GeneralAppBar(
        title: 'Booking Details',
        hasBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchLatestBooking,
              color: kSecondaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClientHeader(),
                    const SizedBox(height: 20),
                    _buildServiceDetailsCard(),
                    const SizedBox(height: 18),
                    _buildVehicleSpecsCard(),
                    const SizedBox(height: 18),
                    _buildCustomerNotesCard(),
                    const SizedBox(height: 18),
                    _buildMapCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  // ── 1. Client Header (Marcus Thorne) ───────────────────────────────────────
  Widget _buildClientHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Verified Avatar with Overlapping Checkmark Badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 70,
                height: 70,
                color: const Color(0xff1C2A38),
                child: (_clientAvatarUrl != null &&
                        _clientAvatarUrl!.isNotEmpty &&
                        (_clientAvatarUrl!.startsWith('http://') ||
                            _clientAvatarUrl!.startsWith('https://')))
                    ? CommonImageView(
                        url: _clientAvatarUrl,
                        cacheKey: _currentBooking?.buyer?.id ?? _bookingId,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorWidget: _buildInitialsFallback(),
                      )
                    : _buildInitialsFallback(),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xffE04F2E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),

        // Name, Location, Badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _clientName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff101828),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Color(0xff667085),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _location,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff667085),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.isPremiumClient) ...[
                    _buildPeachBadge('PREMIUM CLIENT'),
                    const SizedBox(width: 8),
                  ],
                  _buildPeachBadge(widget.bookingCount),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsFallback() {
    return InitialsAvatar(
      name: _clientName,
      size: 70,
      radius: 18,
    );
  }

  Widget _buildPeachBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xffFFEFE8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Color(0xffE04F2E),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── 2. Card 1: Service Details Card ────────────────────────────────────────
  Widget _buildServiceDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffF0F3F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          // Watermark robotic arm in top right
          const Positioned(
            right: 0,
            top: 0,
            child: _RoboticArmWatermark(),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SERVICE DETAILS',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xffE04F2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _service,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff101828),
                ),
              ),
              const SizedBox(height: 18),

              // Schedule & Time Slot boxes
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      label: 'SCHEDULE',
                      icon: Icons.calendar_today_rounded,
                      value: _date,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoBox(
                      label: 'TIME SLOT',
                      icon: Icons.access_time_rounded,
                      value: _time,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Duration & Service Fee row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESTIMATED DURATION',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xff8896A6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _duration,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff101828),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'SERVICE FEE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xff8896A6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fee,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xffE04F2E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String label,
    required IconData icon,
    required String value,
  }) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffF2F5FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xff8896A6),
            ),
          ),
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xffE04F2E)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff101828),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Card 2: Vehicle Specs Card ──────────────────────────────────────────
  Widget _buildVehicleSpecsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF2F6FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE4EDFB), width: 1),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VEHICLE SPECS',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xff667085),
            ),
          ),
          const SizedBox(height: 14),

          // Car Name & Year row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.directions_car_rounded,
                    size: 24,
                    color: Color(0xffE04F2E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehicle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff101828),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _vehicleYear,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xffE4EDFB), height: 1, thickness: 1),

          _buildSpecRow('Engine Type', 'DUAL MOTOR EV'),
          const Divider(color: Color(0xffE4EDFB), height: 1, thickness: 1),
          _buildSpecRow('VIN', _currentBooking?.regNumber ?? 'WP0AB2Y1...7829'),
          const Divider(color: Color(0xffE4EDFB), height: 1, thickness: 1),
          _buildSpecRow('Last Service', 'April 12, 2023'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xff667085),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xff101828),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Card 3: Customer Notes Card ─────────────────────────────────────────
  Widget _buildCustomerNotesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffF0F3F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Solid terracotta left vertical accent bar
            Container(
              width: 3.5,
              decoration: const BoxDecoration(
                color: Color(0xffB84C1C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 18,
                          color: Color(0xffB84C1C),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'CUSTOMER NOTES',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Color(0xffB84C1C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffEEF4FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '"$_notes"',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.55,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff344054),
                        ),
                      ),
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

  // ── 5. Card 4: Map / Location Card ─────────────────────────────────────────
  Widget _buildMapCard() {
    return Container(
      height: 165,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Map Contour background
          CommonImageView(
            imagePath: Assets.imagesMapImage1,
            width: double.infinity,
            height: 165,
            fit: BoxFit.cover,
          ),

          // Semi-transparent gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.25),
                ],
              ),
            ),
          ),

          // Center Pin Marker
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on,
                  color: Color(0xffE04F2E),
                  size: 24,
                ),
              ),
            ),
          ),

          // Floating Route Pill at bottom
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Route to: $_location',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff101828),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Bottom Action Bar ───────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    final next = ProviderBookingsController.nextStep(_status);
    final isCompleted = _status == BookingStatus.completed;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. More options dots button
          InkWell(
            onTap: _showMoreOptions,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xffE6EEF8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xff101828),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Chat pill button
          InkWell(
            onTap: _openChat,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xffE6EEF8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: Color(0xff101828),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff101828),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 3. Primary Status CTA Button (Mark as Completed / Start Job)
          Expanded(
            child: InkWell(
              onTap: (isCompleted || _advancing) ? null : () => _handlePrimaryAction(next),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xff12B76A)
                      : const Color(0xffD94426),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (isCompleted
                              ? const Color(0xff12B76A)
                              : const Color(0xffD94426))
                          .withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _advancing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 19,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _ctaButtonLabel(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ctaButtonLabel() {
    if (_status == BookingStatus.completed) return 'Completed';
    if (_status == BookingStatus.confirmed) return 'Start Job';
    if (_status == BookingStatus.inProgress) return 'Mark as Completed';
    if (_status == BookingStatus.pending) return 'Accept Request';
    return 'Mark as Completed';
  }

  void _handlePrimaryAction(BookingStatus? next) {
    if (next != null) {
      _advanceTo(next);
    } else if (_status == null) {
      _confirmCompletionDialog();
    }
  }

  void _showFeedback(String title, String message) {
    final isTest = Get.testMode ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) return;
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _advanceTo(BookingStatus next) async {
    final id = _bookingId;
    if (id == null) {
      _confirmCompletionDialog();
      return;
    }

    setState(() => _advancing = true);
    if (Get.isRegistered<BookingsRepository>()) {
      final res = await Get.find<BookingsRepository>().advance(
        id: id,
        status: next,
      );
      if (mounted) setState(() => _advancing = false);
      switch (res) {
        case Ok():
          setState(() {
            _status = next;
          });
          widget.onBookingUpdated?.call();
          if (next == BookingStatus.completed) {
            _confirmCompletionDialog();
          } else {
            _showFeedback('Status updated', 'Job status updated to ${next.label}');
          }
        case Err(error: final err):
          if (err.code == ApiErrorCode.insufficientCredits || err.statusCode == 402) {
            _showLeadAccessRequiredDialog(err.message);
          } else {
            _showFeedback('Error', err.message);
          }
      }
    } else {
      if (mounted) setState(() => _advancing = false);
    }
  }

  void _showLeadAccessRequiredDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: kPrimaryColor,
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: kSecondaryColor, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lead Access Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kBlackColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: kGreyTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: kGreyTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              Get.to(() => const ElectricianAccessTierPage());
            },
            child: const Text(
              'View Access Tiers',
              style: TextStyle(color: kWhiteColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCompletionDialog() {
    Get.bottomSheet(
      MyBSheet(
        btnText: 'Back to Bookings',
        onTap: () {
          Get.back();
          Get.back();
        },
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: CommonImageView(
                imagePath: Assets.imagesDoneCheckIcon,
                height: 64,
                width: 64,
                fit: BoxFit.contain,
              ),
            ),
            MyText(
              text: 'Job Completed',
              size: 20,
              weight: FontWeight.w800,
              color: kBlackColor,
              textAlign: TextAlign.center,
              paddingTop: 16,
              paddingBottom: 8,
            ),
            MyText(
              text:
                  '$_service for $_clientName is marked complete. Your job record is updated.',
              size: 14,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              textAlign: TextAlign.center,
              paddingBottom: 8,
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openChat() {
    final id = _bookingId;
    if (id != null) {
      Get.to(
        () => ChatRoomPage(
          contextId: id,
          myUserId: _myUserId,
          title: _clientName,
          peerAvatarUrl: _clientAvatarUrl,
        ),
      );
    } else {
      _showFeedback(
        'Chat',
        'Chat is available once booking is active.',
      );
    }
  }

  void _showMoreOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.price_change_outlined, color: Color(0xffD94426)),
              title: const Text('Update Quote / Final Price', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Get.back();
                if (_currentBooking != null) {
                  final quoteRes = await showQuoteDialog(_currentBooking!);
                  if (quoteRes != null && Get.isRegistered<BookingsRepository>()) {
                    await Get.find<BookingsRepository>().quote(
                      id: _currentBooking!.id,
                      quotedPence: quoteRes.isFinal ? null : quoteRes.pence,
                      finalPence: quoteRes.isFinal ? quoteRes.pence : null,
                    );
                    _fetchLatestBooking();
                    widget.onBookingUpdated?.call();
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation_outlined, color: Color(0xff101828)),
              title: const Text('Navigate to Client', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Get.back();
                _showFeedback('Navigation', 'Route: $_location');
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined, color: Color(0xff101828)),
              title: const Text('Call Client', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Get.back();
                _showFeedback('Contact Client', 'Calling $_clientName');
              },
            ),
            if (_status == BookingStatus.pending || _status == BookingStatus.confirmed)
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                onTap: () {
                  Get.back();
                  _showCancelDialog();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showCancelDialog() {
    final noteCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a mandatory reason for cancellation:'),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = noteCtrl.text.trim();
              if (reason.isEmpty) {
                _showFeedback('Error', 'Reason cannot be empty');
                return;
              }
              Get.back();
              if (_bookingId != null && Get.isRegistered<BookingsRepository>()) {
                final res = await Get.find<BookingsRepository>().cancel(
                  id: _bookingId!,
                  note: reason,
                );
                if (res is Ok) {
                  _showFeedback('Cancelled', 'Booking was cancelled');
                  widget.onBookingUpdated?.call();
                  Get.back();
                } else {
                  _showFeedback('Error', 'Failed to cancel booking');
                }
              }
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Robotic arm watermark illustration in the top-right corner of the Service Details card.
class _RoboticArmWatermark extends StatelessWidget {
  const _RoboticArmWatermark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _RoboticArmPainter(),
      ),
    );
  }
}

class _RoboticArmPainter extends CustomPainter {
  const _RoboticArmPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const armColor = Color(0xffEBF1F6);
    final strokePaint = Paint()
      ..color = armColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = armColor
      ..style = PaintingStyle.fill;

    // Base pedestal
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.40,
        size.height * 0.80,
        size.width * 0.46,
        size.height * 0.12,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(baseRect, fillPaint);

    // Shoulder joint
    final shoulder = Offset(size.width * 0.52, size.height * 0.76);
    canvas.drawCircle(shoulder, 5.0, fillPaint);

    // Lower arm beam (slanted up-left)
    final elbow = Offset(size.width * 0.46, size.height * 0.38);
    canvas.drawLine(shoulder, elbow, strokePaint);
    canvas.drawCircle(elbow, 6.0, fillPaint);

    // Forearm beam (slanted up-right toward wrist)
    final wrist = Offset(size.width * 0.68, size.height * 0.24);
    canvas.drawLine(elbow, wrist, strokePaint);
    canvas.drawCircle(wrist, 5.0, fillPaint);

    // Wrist mount
    final clawBase = Offset(size.width * 0.74, size.height * 0.20);
    canvas.drawLine(wrist, clawBase, strokePaint);

    // Top claw prong
    final pathTop = Path()
      ..moveTo(clawBase.dx, clawBase.dy)
      ..lineTo(size.width * 0.86, size.height * 0.10)
      ..lineTo(size.width * 0.94, size.height * 0.18);
    canvas.drawPath(pathTop, strokePaint);

    // Bottom claw prong
    final pathBottom = Path()
      ..moveTo(clawBase.dx, clawBase.dy)
      ..lineTo(size.width * 0.86, size.height * 0.32)
      ..lineTo(size.width * 0.94, size.height * 0.24);
    canvas.drawPath(pathBottom, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

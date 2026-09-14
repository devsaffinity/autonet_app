import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Every caller — the home dashboard, the bookings list and the request feed —
/// pushes this page with the row the user actually tapped. The defaults are the
/// original hard-coded copy, so an un-parameterised push still renders.
class ElectricianBookingDetailsPage extends StatelessWidget {
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

  /// The booking this page describes, when it came from a real one.
  ///
  /// Null while the page is still opened with placeholder strings; the Chat
  /// button is hidden in that case rather than opening a thread for a
  /// booking that does not exist.
  final String? bookingId;

  /// The signed-in provider, so their own messages sit on the right.
  final String? myUserId;

  const ElectricianBookingDetailsPage({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: ""),
      body: Column(
        children: [
          // ── Scrollable content ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientHeader(),
                  const SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: AppStyling().myShadowStyle(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildServiceDetails(),
                        const SizedBox(height: 16),
                        _buildScheduleRow(),
                        const SizedBox(height: 16),
                        _buildDurationFeeRow(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildVehicleSpecs(),
                  const SizedBox(height: 20),
                  _buildCustomerNotes(),
                  const SizedBox(height: 20),
                  _buildMapCard(),
                  const SizedBox(height: 100), // bottom padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom action bar ────────────────────────────────────────────────
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ── Client Header ──────────────────────────────────────────────────────────
  Widget _buildClientHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (clientAvatarUrl != null &&
            clientAvatarUrl!.isNotEmpty &&
            (clientAvatarUrl!.startsWith('http://') ||
                clientAvatarUrl!.startsWith('https://')))
          CommonImageView(
            url: clientAvatarUrl,
            width: 80,
            height: 80,
            radius: 18,
            fit: BoxFit.cover,
            errorWidget: InitialsAvatar(
              name: clientName,
              size: 80,
              radius: 18,
            ),
          )
        else
          InitialsAvatar(
            name: clientName,
            size: 80,
            radius: 18,
          ),
        const SizedBox(width: 12),

        // Name + location + badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: clientName,
                size: 17,
                weight: FontWeight.w800,
                color: kBlackColor,
                paddingBottom: 4,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: kGreyTextColor,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: MyText(
                      text: location,
                      size: 12,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isPremiumClient) ...[
                    _badge(
                      label: 'PREMIUM CLIENT',
                      bgColor: kLightOrangeColor,
                      textColor: kSecondaryColor,
                      icon: Icons.workspace_premium_rounded,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _badge(
                    label: bookingCount,
                    bgColor: kTertiaryColor,
                    textColor: kGreyTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge({
    required String label,
    required Color bgColor,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 3),
          ],
          MyText(
            text: label,
            size: 10,
            weight: FontWeight.w700,
            color: textColor,
          ),
        ],
      ),
    );
  }

  // ── Service Details ────────────────────────────────────────────────────────
  Widget _buildServiceDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'SERVICE DETAILS',
          size: 10,
          weight: FontWeight.w700,
          color: kSecondaryColor,
          paddingBottom: 6,
        ),
        MyText(
          text: service,
          size: 30,
          weight: FontWeight.w800,
          color: kBlackColor,
        ),
      ],
    );
  }

  // ── Schedule + Time Slot ───────────────────────────────────────────────────
  Widget _buildScheduleRow() {
    return Row(
      children: [
        Expanded(
          child: _infoBox(
            label: 'SCHEDULE',
            icon: Icons.calendar_today_outlined,
            iconColor: kSecondaryColor,
            value: date,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoBox(
            label: 'TIME SLOT',
            icon: Icons.access_time_rounded,
            iconColor: kSecondaryColor,
            value: time,
          ),
        ),
      ],
    );
  }

  Widget _infoBox({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: AppStyling().myDecoration(
        color: kLightBlueColor,
        borderColor: kTertiaryColor,
        radius: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MyText(
            text: label,
            size: 10,
            weight: FontWeight.w700,
            color: kGreyTextColor,
            paddingBottom: 8,
          ),
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: MyText(
                  text: value,
                  size: 14,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Duration + Fee ─────────────────────────────────────────────────────────
  Widget _buildDurationFeeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'ESTIMATED DURATION',
                size: 10,
                weight: FontWeight.w700,
                color: kGreyTextColor,
                paddingBottom: 4,
              ),
              MyText(
                text: duration,
                size: 18,
                weight: FontWeight.w800,
                color: kBlackColor,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'SERVICE FEE',
                size: 10,
                weight: FontWeight.w700,
                color: kGreyTextColor,
                paddingBottom: 4,
              ),
              MyText(
                text: fee,
                size: 22,
                weight: FontWeight.w800,
                color: kSecondaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Vehicle Specs ──────────────────────────────────────────────────────────
  Widget _buildVehicleSpecs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: AppStyling().myDecoration(
        color: kLightBlueColor,
        borderColor: kTertiaryColor,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'VEHICLE SPECS',
            size: 10,
            weight: FontWeight.w700,
            color: kGreyTextColor,
            paddingBottom: 12,
          ),

          // Car name row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kLightOrangeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_car_outlined,
                  size: 20,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: vehicle,
                    size: 15,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                  MyText(
                    text: vehicleYear,
                    size: 12,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: kGreyTextColor.withOpacity(0.15), height: 1),

          _specRow('Engine Type', 'DUAL MOTOR EV'),
          Divider(color: kGreyTextColor.withOpacity(0.15), height: 1),
          _specRow('VIN', 'MP0AB2Y1. . . 7829'),
          Divider(color: kGreyTextColor.withOpacity(0.15), height: 1),
          _specRow('Last Service', 'April 12, 2023'),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText(
            text: label,
            size: 13,
            weight: FontWeight.w400,
            color: kGreyTextColor,
          ),
          MyText(
            text: value,
            size: 13,
            weight: FontWeight.w700,
            color: kBlackColor,
          ),
        ],
      ),
    );
  }

  // ── Customer Notes ─────────────────────────────────────────────────────────
  Widget _buildCustomerNotes() {
    return Container(
      height: 200,
      decoration: AppStyling().myDecoration(
        color: kWhiteColor,
        borderColor: kTertiaryColor,
        radius: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left red accent bar
          Container(
            width: 4,
            decoration: const BoxDecoration(
              color: kSecondaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 18,
                        color: kSecondaryColor,
                      ),
                      const SizedBox(width: 6),
                      MyText(
                        text: 'CUSTOMER NOTES',
                        size: 10,
                        weight: FontWeight.w700,
                        color: kSecondaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: const BoxDecoration(
                      color: kLightBlueColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    child: Column(
                      children: [
                        MyText(
                          text:
                              '"Please check my sensor wiring around the rear bumper assembly. Getting intermittent proximity warnings after the last car wash. ECU coding should focus on the performance throttle map adjustment as discussed."',
                          size: 13,
                          weight: FontWeight.w400,
                          color: kBlackColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map Card ───────────────────────────────────────────────────────────────
  Widget _buildMapCard() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: AppStyling().myDecoration(
        color: kTertiaryColor,
        borderColor: kTertiaryColor,
        radius: 16,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Map placeholder background
          Container(
            color: const Color(0xffCFD9E0),
            child: Center(
              child: Icon(
                Icons.map_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),

          // Map image (replace with actual map widget or screenshot)
          CommonImageView(
            imagePath: Assets.imagesMapImage1,
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
          ),

          // Pin icon in center
          const Center(
            child: Icon(
              Icons.location_on_rounded,
              size: 32,
              color: kSecondaryColor,
            ),
          ),

          // Route label at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.black.withOpacity(0.45),
              child: Row(
                children: [
                  const Icon(
                    Icons.navigation_outlined,
                    size: 14,
                    color: kWhiteColor,
                  ),
                  const SizedBox(width: 6),
                  MyText(
                    text: 'Route to: 422 West 42nd St, NY',
                    size: 12,
                    weight: FontWeight.w600,
                    color: kWhiteColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mark as Completed ──────────────────────────────────────────────────────
  void _confirmCompletion() {
    Get.bottomSheet(
      MyBSheet(
        btnText: 'Back to Bookings',
        onTap: () {
          Get.back(); // close the sheet
          Get.back(); // pop this detail page back to the calling list
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
                  '$service for $clientName is marked complete. $fee will settle to your balance once the client confirms.',
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

  // ── Bottom Action Bar ──────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // More options dot button
          MyRippleEffect(
            onTap: () {},
            radius: 14,
            child: Container(
              width: 44,
              height: 44,
              decoration: AppStyling().myDecoration(
                color: kTertiaryColor,
                borderColor: kTertiaryColor,
                radius: 12,
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: kBlackColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Chat button — only when there is a real booking behind it.
          if (bookingId != null) ...[
          Expanded(
            child: MyRippleEffect(
              onTap: () => Get.to(
                () => ChatRoomPage(
                  contextId: bookingId!,
                  myUserId: myUserId,
                  title: clientName,
                  peerAvatarUrl: clientAvatarUrl,
                ),
              ),
              radius: 12,
              child: Container(
                height: 44,
                decoration: AppStyling().myDecoration(
                  color: kTertiaryColor,
                  borderColor: kTertiaryColor,
                  radius: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: kBlackColor,
                    ),
                    const SizedBox(width: 6),
                    MyText(
                      text: 'Chat',
                      size: 14,
                      weight: FontWeight.w600,
                      color: kBlackColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ],

          // Mark as Completed button
          Expanded(
            flex: 2,
            child: MyButton(
              buttonText: 'Mark as\nCompleted',
              // The dead comment here pushed ElectricianBookingRequestPage,
              // which is the *incoming* request feed — finishing a job must
              // not dump the provider into a list of jobs they have not
              // accepted. Confirm the completion, then pop back to whichever
              // list opened this booking.
              onTap: _confirmCompletion,
              backgroundColor: kSecondaryColor,
              fontColor: kWhiteColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 48,
              radius: 14,
              icon: 'assets/images/check_icon.png',
              haveSvg: false,
            ),
          ),
        ],
      ),
    );
  }
}

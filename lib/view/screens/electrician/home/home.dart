import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/electrician/dash_board/electrician_avalibilty_page.dart';
import 'package:autonect/view/screens/electrician/dash_board/manage_services.dart';
import 'package:autonect/view/screens/electrician/dash_board/total_balance.dart';
import 'package:autonect/view/screens/electrician/home/upcoming_booking_details.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class ElectricianHomePage extends StatefulWidget {
  const ElectricianHomePage({super.key});

  @override
  State<ElectricianHomePage> createState() => _ElectricianHomePageState();
}

class _ElectricianHomePageState extends State<ElectricianHomePage> {
  bool _isOnline = true;

  final List<Map<String, String>> _bookings = [
    {
      'name': 'Sarah Johnson',
      'detail': 'Porsche 911 • Full Diagnostic',
      'time': '10:30AM',
      'image': Assets.imagesProfileImage,
    },
    {
      'name': 'Michael Chen',
      'detail': 'Tesla Model S • Brake Service',
      'time': '02:15 PM',
      'image': Assets.imagesProfileImage,
    },
    {
      'name': 'James Wilson',
      'detail': 'Ferrari Roma • Oil Change',
      'time': '06:45 PM',
      'image': Assets.imagesProfileImage,
    },
  ];

  final List<Map<String, String>> _messages = [
    {
      'name': 'Elena Ross',
      'preview': 'Hey Alex, do you have any morning sl...',
      'time': '12m ago',
      'image': Assets.imagesProfileImage,
    },
    {
      'name': 'David Miller',
      'preview': 'The brakes feel amazing now, thanks...',
      'time': '1h ago',
      'image': Assets.imagesProfileImage,
    },
  ];

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
          onTap: () => setState(() => _isOnline = !_isOnline),
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
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? const Color(0xff34C759) : kGreyTextColor,
                  ),
                ),
                const SizedBox(width: 5),
                MyText(
                  text: _isOnline ? 'ONLINE' : 'OFFLINE',
                  size: 12,
                  weight: FontWeight.w600,
                  color: kBlackColor,
                ),
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

  // ── Performance Card (red) ─────
  Widget _buildPerformanceCard() {
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
                text: "Today's Performance",
                size: 12,
                weight: FontWeight.w600,
                color: kWhiteColor.withOpacity(0.8),
                paddingBottom: 6,
              ),
              MyText(
                text: '4 Bookings',
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
                  MyText(
                    text: '20% increase from yesterday',
                    size: 16,
                    weight: FontWeight.w500,
                    color: kWhiteColor.withOpacity(0.8),
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
                text: 'Weekly Earnings',
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
          MyText(
            text: '\$1,240',
            size: 28,
            weight: FontWeight.w800,
            color: kBlackColor,
            paddingBottom: 12,
          ),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: 0.75,
              backgroundColor: kTertiaryColor,
              valueColor: const AlwaysStoppedAnimation<Color>(kSecondaryColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: MyText(
              text: '75% of goal',
              size: 11,
              weight: FontWeight.w400,
              color: kGreyTextColor,
            ),
          ),
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
                switch (i) {
                  case 0:
                    Get.to(() => ManageServicesPage());
                    break;
                  case 1:
                    Get.to(() => ElectricianAvailabilityPage());
                    break;
                  case 2:
                    Get.to(() => TotalBalancePage());
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
              onTap: () {},
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
        Container(
          decoration: AppStyling().myShadowDecoration(
            color: kPrimaryColor,
            radius: 14,
            borderColor: kTransperentColor,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bookings.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: kTertiaryColor,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (_, i) => _buildBookingRow(_bookings[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingRow(Map<String, String> booking) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: () {
          Get.to(() => ElectricianBookingDetailsPage());
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
                  imagePath: booking['image'],
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
                    text: booking['name']!,
                    size: 14,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                  const SizedBox(height: 3),
                  MyText(
                    text: booking['detail']!,
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
                text: booking['time']!,
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
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: kSecondaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: MyText(
                  text: '2',
                  size: 11,
                  weight: FontWeight.w700,
                  color: kWhiteColor,
                ),
              ),
            ),
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _messages.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: kTertiaryColor,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (_, i) => _buildMessageRow(_messages[i]),
              ),
              const Divider(height: 1, color: kTertiaryColor),
              // Go to Messenger
              MyRippleEffect(
                onTap: () {},
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

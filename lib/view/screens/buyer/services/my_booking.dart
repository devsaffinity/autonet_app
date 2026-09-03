import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/buyer/services/booking_confirmed.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyBookingsPage extends StatefulWidget {
  /// The booking that was just confirmed, if the buyer arrived from the
  /// confirmation screen. Defaults are the literals this screen used to
  /// hard-code, so an argument-less `MyBookingsPage()` renders as before.
  final String expertName, avatarUrl, service, description;

  const MyBookingsPage({
    super.key,
    this.expertName = 'Alex Rivera',
    this.avatarUrl = 'https://randomuser.me/api/portraits/women/44.jpg',
    this.service = 'ECU Tuning',
    this.description =
        'Stage 2 Performance Mapping & Precision Optimization for enhanced throttle response and power delivery.',
  });

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "My Bookings", centerdTitle: false),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            BookingCard(
              expertName: widget.expertName,
              avatarUrl: widget.avatarUrl,
              service: widget.service,
              description: widget.description,
            ),
            const BookingCard(
              expertName: 'John Mitchel',
              avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
              service: 'Diagnostics Check',
              description:
                  'Full fault-code read, live sensor trace and a written report on what needs attention next.',
              date: 'Sep, 24',
              time: '09:00 AM',
            ),
          ],
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String expertName, avatarUrl, service, description, date, time;

  const BookingCard({
    super.key,
    this.expertName = 'Alex Rivera',
    this.avatarUrl = 'https://randomuser.me/api/portraits/women/44.jpg',
    this.service = 'ECU Tuning',
    this.description =
        'Stage 2 Performance Mapping & Precision Optimization for enhanced throttle response and power delivery.',
    this.date = 'Sep, 11',
    this.time = '11:30 AM',
  });

  @override
  Widget build(BuildContext context) {
    return
    // ── Service Details card
    Padding(
      padding: EdgeInsetsGeometry.only(bottom: 10),
      child: InfoCard(
        child: Stack(
          children: [
            // ── Watermark "BAY" text
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  '888',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: kSecondaryColor.withOpacity(0.07),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Service Details',
                  size: 12,
                  color: kGreyTextColor,
                  weight: FontWeight.w600,
                  paddingBottom: 4,
                ),
                MyText(
                  text: service,
                  size: 24,
                  weight: FontWeight.w700,
                  color: kSecondaryColor,
                  paddingBottom: 6,
                ),
                MyText(
                  text: description,
                  size: 12,
                  color: kGreyTextColor,
                  weight: FontWeight.w400,
                  paddingBottom: 14,
                ),

                // ── Technician row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CommonImageView(
                        url: avatarUrl,
                        height: 36,
                        width: 36,
                        radius: 5,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            text: 'Professional Technician',
                            size: 12,
                            weight: FontWeight.w400,
                          ),
                          MyText(
                            text: expertName,
                            size: 12,
                            weight: FontWeight.w700,
                            color: kSecondaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: List.generate(3, (index) {
                    List<String> names = [
                      'Chat Now',
                      'View Booking',
                      'Save Receipt',
                    ];
                    // Every one of these three was an empty callback, which is
                    // what made this screen a dead end.
                    final List<VoidCallback> actions = [
                      () => Get.to(() => const ChatRoomPage()),
                      () => Get.to(
                        () => BookingConfirmedPage(
                          expertName: expertName,
                          avatarUrl: avatarUrl,
                          service: service,
                          description: description,
                          date: date,
                          time: time,
                        ),
                      ),
                      // TODO(api): needs the receipt endpoint.
                      () => Get.snackbar(
                        "Receipt",
                        "Your receipt will be emailed to you",
                        backgroundColor: kWhiteColor,
                      ),
                    ];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsetsGeometry.only(
                          right: (index < 2) ? 5 : 0,
                        ),
                        child: MyButton(
                          radius: 5,
                          buttonText: names[index],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontColor: kBlackColor,
                          backgroundColor: kWhiteColor,
                          outlineColor: kSecondaryColor,
                          height: 30,

                          onTap: actions[index],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

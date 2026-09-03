import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/buyer/services/my_booking.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookingConfirmedPage extends StatelessWidget {
  /// The booking that was just made. Defaults are the literals this screen used
  /// to hard-code.
  final String expertName, avatarUrl, service, description, date, time;

  const BookingConfirmedPage({
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // ── Success icon
              CommonImageView(height: 100, imagePath: Assets.imagesBookingDone),

              const SizedBox(height: 5),

              // ── Title
              MyText(
                text: 'Booking Confirmed',
                size: 24,
                weight: FontWeight.w600,
                color: kBlackColor,
                textAlign: TextAlign.center,
              ),
              MyText(
                text: 'Your high-performance service has been scheduled.',
                size: 12,
                weight: FontWeight.w400,
                color: kGreyTextColor,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ── Service Details card
              InfoCard(
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
                                radius: 18,
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
                                    color: kGreyTextColor,
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
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Schedule card
              InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: 'Schedule',
                      size: 12,
                      color: kGreyTextColor,
                      weight: FontWeight.w600,
                      paddingBottom: 4,
                    ),
                    MyText(
                      text: date,
                      size: 24,
                      weight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                    MyText(
                      text: time,
                      size: 20,
                      weight: FontWeight.w500,
                      color: kBlackColor,
                    ),

                    const SizedBox(height: 24),

                    // ── Chat with the expert (filled)
                    MyButton(
                      buttonText: 'Chat with ${expertName.split(' ').first}',
                      height: 52,
                      fontSize: 15,
                      haveSvg: true,
                      icon: Assets.imagesBookingChat,
                      onTap: () => Get.to(() => const ChatRoomPage()),
                    ),

                    const SizedBox(height: 12),

                    // ── View my Bookings (outlined)
                    MyButton(
                      haveSvg: true,
                      icon: Assets.imagesViewBooking,
                      buttonText: 'View my Bookings',
                      height: 52,
                      fontSize: 15,
                      backgroundColor: kPrimaryColor,
                      outlineColor: kBlackColor.withOpacity(0.2),
                      fontColor: kBlackColor,
                      onTap: () {
                        // `off` not `to`: the confirmation is terminal, the
                        // buyer should land on the bookings list and back out
                        // to whatever opened the funnel.
                        Get.off(
                          () => MyBookingsPage(
                            expertName: expertName,
                            avatarUrl: avatarUrl,
                            service: service,
                            description: description,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // ── Download Receipt (outlined)
                    MyButton(
                      haveSvg: true,
                      icon: Assets.imagesBookingDownload,
                      buttonText: 'Download Receipt',
                      height: 52,
                      fontSize: 15,
                      backgroundColor: kPrimaryColor,
                      outlineColor: kBlackColor.withOpacity(0.2),
                      fontColor: kBlackColor,
                      // TODO(api): needs the receipt endpoint. Acknowledge the
                      // tap rather than swallowing it.
                      onTap: () => Get.snackbar(
                        "Receipt",
                        "Your receipt will be emailed to you",
                        backgroundColor: kWhiteColor,
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable info card
// ─────────────────────────────────────────────────────────────────────────────

class InfoCard extends StatelessWidget {
  final Widget child;
  const InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

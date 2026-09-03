import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/buyer/services/my_booking.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class BookingConfirmedPage extends StatelessWidget {
  const BookingConfirmedPage({super.key});

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
                          text: 'ECU Tuning',
                          size: 24,
                          weight: FontWeight.w700,
                          color: kSecondaryColor,
                          paddingBottom: 6,
                        ),
                        MyText(
                          text:
                              'Stage 2 Performance Mapping & Precision Optimization for enhanced throttle response and power delivery.',
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
                                url:
                                    'https://randomuser.me/api/portraits/women/44.jpg',
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
                                    text: 'Alex Rivera',
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
                      text: 'Sep, 11',
                      size: 24,
                      weight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                    MyText(
                      text: '11:30 AM',
                      size: 20,
                      weight: FontWeight.w500,
                      color: kBlackColor,
                    ),

                    const SizedBox(height: 24),

                    // ── Chat with Alex (filled)
                    MyButton(
                      buttonText: 'Chat with Alex',
                      height: 52,
                      fontSize: 15,
                      haveSvg: true,
                      icon: Assets.imagesBookingChat,
                      onTap: () {},
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
                        Get.to(() => MyBookingsPage());
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
                      onTap: () {},
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

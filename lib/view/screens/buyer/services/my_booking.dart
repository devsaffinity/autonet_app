import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/buyer/services/booking_confirmed.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "My Bookings", centerdTitle: false),
      body: Padding(
        padding: AppSizes.DEFAULT,
        child: Column(children: [BookingCard(), BookingCard()]),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard({super.key});

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
                        url: 'https://randomuser.me/api/portraits/women/44.jpg',
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
                SizedBox(height: 12),
                Row(
                  children: List.generate(3, (index) {
                    List<String> names = [
                      'Chat Now',
                      'View Booking',
                      'Save Reciept',
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

                          onTap: () {},
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

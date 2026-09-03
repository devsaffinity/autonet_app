import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/buyer/services/new_booking.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExpertProfilePage extends StatelessWidget {
  const ExpertProfilePage({super.key});

  // ── Specializations data
  static const List<Map<String, dynamic>> _specializations = [
    {
      'icon': Assets.imagesExB,
      'title': 'Vehicles Serviced',
      'subtitle': 'ECU, GCM, and PCM restoration',
    },
    {
      'icon': Assets.imagesExC,
      'title': 'Software Updates',
      'subtitle': 'Firmware flashing & calibration',
    },
    {
      'icon': Assets.imagesExD,
      'title': 'EV Diagnostics',
      'subtitle': 'High-voltage battery analytics',
    },
    {
      'icon': Assets.imagesExE,
      'title': 'Custom Wiring',
      'subtitle': 'Performance building',
    },
  ];

  // ── Brands data
  static const List<String> _brands = ['BMW', 'Mercedes', 'Ford', 'Peugeot'];

  // ── Testimonials data
  static const List<Map<String, String>> _testimonials = [
    {
      'name': 'Marcus Thorne',
      'avatar': 'https://randomuser.me/api/portraits/men/41.jpg',
      'rating': '5',
      'review':
          '"Alex is a wizard with electronics. My dealership quoted me \$4k for a new harness, Alex found a single corroded pin and fixed it in an hour. Absolute legend."',
    },
    {
      'name': 'Sarah Jenkins',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'rating': '5',
      'review':
          '"Prompt, professional, and clearly knows his stuff. He explained the software update process for my EV in simple terms. Highly recommended."',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "Expert profile", centerdTitle: false),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scrollable body
            Center(
              child: Column(
                children: [
                  // Avatar
                  CommonImageView(
                    url: 'https://randomuser.me/api/portraits/men/32.jpg',
                    height: 125,
                    width: 125,
                    radius: 9,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 10),

                  // Expert
                  MyText(
                    text: 'EXPERT VERIFIED',
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                  const SizedBox(height: 4),

                  // Name
                  MyText(
                    text: 'LARRY ALLISON',
                    size: 24,
                    weight: FontWeight.w600,
                    color: kSecondaryColor,
                  ),
                  const SizedBox(height: 2),

                  // Role
                  MyText(
                    text: 'Senior Automotive Electrician',
                    size: 14,
                    color: kGreyTextColor,
                    weight: FontWeight.w500,
                  ),
                  const SizedBox(height: 6),

                  // Rating + Experience
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MyText(
                        text: '4.8',
                        size: 13,
                        weight: FontWeight.w700,
                        color: kSecondaryColor,
                      ),
                      MyText(
                        text: '  |  12 Years Experience',
                        size: 12,
                        weight: FontWeight.w400,
                        color: kBlackColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Expertise Profile card
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'Expertise Profile',
                    size: 16,
                    weight: FontWeight.w700,
                    color: kSecondaryColor,
                    paddingBottom: 8,
                  ),
                  MyText(
                    text:
                        'Specializing in advanced dignostic systems and electrical architecture for high-performance and electric vehicles. Alex has spent over a decade perfecting the "digital heartbeat" of modern cars, focusing on precision module repairs and complex software integration. Known for solving intermittent electrical gremlins that stump standard dealerships.',
                    size: 13,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _SectionCard(
              child: // ── Vehicles count row
              Row(
                children: [
                  CommonImageView(svgPath: Assets.imagesExA),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: '1240+',
                        size: 20,
                        weight: FontWeight.w700,
                        color: kBlackColor,
                      ),
                      MyText(
                        text: 'Vehicles Serviced',
                        size: 14,
                        weight: FontWeight.w500,
                        color: kGreyTextColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Specializations
            MyText(
              text: 'Specializations',
              size: 15,
              weight: FontWeight.w700,
              color: kBlackColor,
              paddingBottom: 12,
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: _specializations
                  .map(
                    (s) => _SpecializationCard(
                      icon: s['icon'],
                      title: s['title'],
                      subtitle: s['subtitle'],
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 20),

            // ── Brands Supported
            MyText(
              text: 'Brands Supported',
              size: 15,
              weight: FontWeight.w700,
              color: kBlackColor,
              paddingBottom: 10,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _brands
                  .map(
                    (b) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: kSecondaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: MyText(
                        text: b,
                        size: 12,
                        color: kBlackColor,
                        weight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            // ── Client Testimonials
            MyText(
              text: 'Client Testimonials',
              size: 15,
              weight: FontWeight.w700,
              color: kBlackColor,
              paddingBottom: 12,
            ),
            ..._testimonials.map(
              (t) => _TestimonialCard(
                name: t['name']!,
                avatarUrl: t['avatar']!,
                rating: int.parse(t['rating']!),
                review: t['review']!,
              ),
            ),

            const SizedBox(height: 20),

            // ── Bottom buttons
            MyButton(
              buttonText: 'Book Diagnostic',
              onTap: () {
                Get.to(() => NewBookingPage());
              },
            ),
            const SizedBox(height: 10),
            MyButton(
              mBottom: 50,
              buttonText: 'Chat Now',
              backgroundColor: kPrimaryColor,
              outlineColor: kSecondaryColor,
              fontColor: kBlackColor,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// White section card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

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

// ─────────────────────────────────────────────────────────────────────────────
// Specialization Card
// ─────────────────────────────────────────────────────────────────────────────

class _SpecializationCard extends StatelessWidget {
  final String icon;
  final String title, subtitle;
  const _SpecializationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlackColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kSecondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CommonImageView(svgPath: icon),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyText(
                  text: title,
                  size: 11,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                MyText(text: subtitle, size: 10, color: kGreyTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Testimonial Card
// ─────────────────────────────────────────────────────────────────────────────

class _TestimonialCard extends StatelessWidget {
  final String name, avatarUrl, review;
  final int rating;
  const _TestimonialCard({
    required this.name,
    required this.avatarUrl,
    required this.review,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBlackColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommonImageView(
                url: avatarUrl,
                height: 48,
                width: 48,
                radius: 9,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    paddingBottom: 2,
                    text: name,
                    size: 14,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                  Row(
                    children: List.generate(
                      rating,
                      (_) => const Icon(
                        Icons.star,
                        size: 14,
                        color: kSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          MyText(text: review, size: 16, color: kGreyTextColor),
        ],
      ),
    );
  }
}

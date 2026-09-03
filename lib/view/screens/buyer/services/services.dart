import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/buyer/request/request_status_tracking.dart';
import 'package:autonect/view/screens/buyer/services/expert_profile.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  int _selectedCategory = 0; // 0 = Electricians, 1 = Coders
  final List<String> _categories = ['Electricians', 'Coders'];

  final List<String> _tags = ['Diagnostics', 'ECU Tuning', 'Dashcam Install'];
  int _selectedTag = 0;

  final List<Map<String, String>> _providers = [
    {
      'name': 'John Mitchel',
      'role': 'ECU Specialist',
      'rating': '4.8',
      'reviews': '126 Reviews',
      'skills': 'Coding, Remapping, Key Programming',
      'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    {
      'name': 'John Mitchel',
      'role': 'ECU Specialist',
      'rating': '4.8',
      'reviews': '126 Reviews',
      'skills': 'Coding, Remapping, Key Programming',
      'avatar': 'https://randomuser.me/api/portraits/men/45.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        title: "Services",
        hasBackButton: false,
        action: [
          CommonImageView(svgPath: Assets.imagesCalenderServices),
          SizedBox(width: 20),
        ],
      ),
      body: Padding(
        padding: AppSizes.VERTICAL,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Category tabs + location
                    Row(
                      children: [
                        // Category pills
                        ..._categories.asMap().entries.map((e) {
                          final selected = _selectedCategory == e.key;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = e.key),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? kSecondaryColor
                                    : kPrimaryColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? kSecondaryColor
                                      : kSecondaryColor,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CommonImageView(
                                    svgPath: e.key == 0
                                        ? Assets.imagesElectricanIcon
                                        : Assets.imagesCoderIcon,
                                  ),
                                  const SizedBox(width: 4),
                                  MyText(
                                    text: e.value,
                                    size: 13,
                                    weight: FontWeight.w600,
                                    color: selected ? kWhiteColor : kBlackColor,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const Spacer(),

                        // Location
                        GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: kSecondaryColor,
                              ),
                              const SizedBox(width: 2),
                              MyText(
                                text: 'Dubai, UAE',
                                size: 12,
                                color: kBlackColor,
                                weight: FontWeight.w500,
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: kBlackColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Search bar + filter icon
                    MySearchBar(),

                    const SizedBox(height: 5),

                    // ── Tag chips
                    Row(
                      children: _tags.asMap().entries.map((e) {
                        final selected = _selectedTag == e.key;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTag = e.key),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? kSecondaryColor.withOpacity(0.1)
                                  : kTertiaryColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? kSecondaryColor
                                    : kTertiaryColor,
                              ),
                            ),
                            child: MyText(
                              text: e.value,
                              size: 12,
                              color: selected ? kSecondaryColor : kBlackColor,
                              weight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Provider cards
                    ..._providers.map(
                      (p) => _ProviderCard(
                        name: p['name']!,
                        role: p['role']!,
                        rating: p['rating']!,
                        reviews: p['reviews']!,
                        skills: p['skills']!,
                        avatarUrl: p['avatar']!,
                        onViewProfile: () {
                          Get.to(() => ExpertProfilePage());
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  final String name, role, rating, reviews, skills, avatarUrl;
  final VoidCallback onViewProfile;

  const _ProviderCard({
    required this.name,
    required this.role,
    required this.rating,
    required this.reviews,
    required this.skills,
    required this.avatarUrl,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + name + role + 3-dot
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonImageView(
                url: avatarUrl,
                height: 46,
                width: 46,
                radius: 23,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MyText(
                          text: name,
                          size: 14,
                          weight: FontWeight.w700,
                          color: kBlackColor,
                        ),
                        MyText(text: ' • ', size: 14, color: kBlackColor),
                        MyText(
                          text: role,
                          size: 13,
                          weight: FontWeight.w600,
                          color: kSecondaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        MyText(
                          text: '$rating ($reviews)',
                          size: 12,
                          weight: FontWeight.w500,
                          color: kGreyTextColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    MyText(
                      text: skills,
                      size: 12,
                      weight: FontWeight.w500,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
              ),

              // 3-dot menu
              CommonImageView(svgPath: Assets.imagesChatRed),
            ],
          ),

          const SizedBox(height: 15),

          // ── View Profile button
          MyButton(
            buttonText: 'View Profile',
            height: 42,
            fontSize: 14,
            radius: 9,
            onTap: onViewProfile,
          ),
        ],
      ),
    );
  }
}

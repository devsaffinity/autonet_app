import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usage:
//   body: ElectricianReviewPage()
// ─────────────────────────────────────────────────────────────────────────────

class ElectricianReviewPage extends StatefulWidget {
  const ElectricianReviewPage({super.key});

  @override
  State<ElectricianReviewPage> createState() => _ElectricianReviewPageState();
}

class _ElectricianReviewPageState extends State<ElectricianReviewPage> {
  // ── Filter tabs ────────────────────────────────────────────────────────────
  final List<String> _filters = [
    'All Reviews',
    '5 Stars',
    '4 Stars',
    '3 Stars',
    'Critical',
  ];
  int _selectedFilter = 0;

  // ── Rating breakdown ───────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _ratingBreakdown = [
    {'star': 5, 'percent': 0.92, 'label': '92%'},
    {'star': 4, 'percent': 0.06, 'label': '6%'},
    {'star': 3, 'percent': 0.02, 'label': '2%'},
    {'star': 2, 'percent': 0.0, 'label': '0%'},
    {'star': 1, 'percent': 0.0, 'label': '0%'},
  ];

  // ── Review data ────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Alex Thompson',
      'avatar': Assets.imagesProfileImage,
      'rating': 5,
      'timeAgo': '2 Days Ago',
      'review':
          'Alex Is The Best Coder In London! The Technical Architecture Was Flawless And The Delivery Was Ahead Of Schedule. Truly Professional Experience From Start To Finish.',
      'extraCount': '+12',
      'reply': null,
    },
    {
      'name': 'James Wilson',
      'avatar': Assets.imagesProfileImage,
      'rating': 4,
      'timeAgo': '1 Week Ago',
      'review':
          'Solid Engineering Work. Very Clean Code And Great Documentation. One Star Off Only Because Of A Slight Delay In Initial Communication, But The Work Itself Is 5 Stars.',
      'extraCount': null,
      'reply':
          '"Thanks For The Feedback, James! We\'ve Improved Our Intake Process To Ensure Faster Initial Contact Moving Forward!"',
    },
    {
      'name': 'Alex Thompson',
      'avatar': Assets.imagesProfileImage,
      'rating': 5,
      'timeAgo': '2 Days Ago',
      'review':
          'Alex Is The Best Coder In London! The Technical Architecture Was Flawless And The Delivery Was Ahead Of Schedule. Truly Professional Experience From Start To Finish.',
      'extraCount': '+12',
      'reply': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "Reviews"),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Overall quality ──────────────────────────────────────
                  _buildOverallQuality(),
                  const SizedBox(height: 20),

                  // ── Rating breakdown ─────────────────────────────────────
                  _buildRatingBreakdown(),
                  const SizedBox(height: 24),

                  // ── Filter chips ─────────────────────────────────────────
                  _buildFilterChips(),
                  const SizedBox(height: 20),

                  // ── Review cards ─────────────────────────────────────────
                  ..._reviews.map((r) => _buildReviewCard(r)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom View More button ──────────────────────────────────────────
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Overall Quality ────────────────────────────────────────────────────────
  Widget _buildOverallQuality() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      width: Get.width,
      decoration: AppStyling().myShadowDecoration(
        color: kWhiteColor,
        radius: 15,
      ),
      child: Column(
        children: [
          MyText(
            text: 'Overall Quality',
            size: 14,
            weight: FontWeight.w600,
            color: kSecondaryColor,
            textAlign: TextAlign.center,
            paddingBottom: 6,
          ),
          MyText(
            text: '4.9',
            size: 48,
            weight: FontWeight.w800,
            color: kBlackColor,
            textAlign: TextAlign.center,
            paddingBottom: 6,
          ),
          _buildStars(5, size: 28),
          const SizedBox(height: 6),
          MyText(
            text: 'Based On 128 Reviews',
            size: 13,
            weight: FontWeight.w400,
            color: kGreyTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Rating Breakdown ───────────────────────────────────────────────────────
  Widget _buildRatingBreakdown() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      width: Get.width,
      decoration: AppStyling().myShadowDecoration(
        color: kWhiteColor,
        radius: 15,
      ),
      child: Column(
        children: _ratingBreakdown.map((r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Star number
                SizedBox(
                  width: 12,
                  child: MyText(
                    text: '${r['star']}',
                    size: 13,
                    weight: FontWeight.w600,
                    color: kBlackColor,
                  ),
                ),
                const SizedBox(width: 8),
                // Progress bar
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: r['percent'] as double,
                      minHeight: 7,
                      backgroundColor: kTertiaryColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (r['percent'] as double) > 0
                            ? kSecondaryColor
                            : kTertiaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Percent label
                SizedBox(
                  width: 30,
                  child: MyText(
                    text: r['label'],
                    size: 12,
                    weight: FontWeight.w500,
                    color: kGreyTextColor,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (i) {
          final isSelected = _selectedFilter == i;
          return Padding(
            padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
            child: MyRippleEffect(
              onTap: () => setState(() => _selectedFilter = i),
              radius: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? kSecondaryColor
                      : kSecondaryColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? kSecondaryColor : kTransperentColor,
                  ),
                ),
                child: MyText(
                  text: _filters[i],
                  size: 12,
                  weight: FontWeight.w600,
                  color: isSelected ? kWhiteColor : kBlackColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Review Card ────────────────────────────────────────────────────────────
  Widget _buildReviewCard(Map<String, dynamic> r) {
    final hasReply = r['reply'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      width: Get.width,
      decoration: AppStyling().myShadowDecoration(
        color: kWhiteColor,
        radius: 15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: avatar + name + time ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CommonImageView(
                imagePath: r['avatar'],
                width: 42,
                height: 42,
                radius: 10,
                fit: BoxFit.cover,
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
                          text: r['name'],
                          size: 14,
                          weight: FontWeight.w700,
                          color: kBlackColor,
                        ),
                        MyText(
                          text: r['timeAgo'],
                          size: 11,
                          weight: FontWeight.w400,
                          color: kGreyTextColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    _buildStars(r['rating'] as int, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Review text ────────────────────────────────────────────────────
          MyText(
            text: r['review'],
            size: 13,
            weight: FontWeight.w400,
            color: kBlackColor,
            paddingBottom: 12,
          ),

          // ── Your Reply box ─────────────────────────────────────────────────
          if (hasReply) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppStyling().myDecoration(
                color: kTertiaryColor,
                borderColor: kTertiaryColor,
                radius: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.reply_rounded,
                        size: 14,
                        color: kGreyTextColor,
                      ),
                      const SizedBox(width: 4),
                      MyText(
                        text: 'Your Reply',
                        size: 11,
                        weight: FontWeight.w700,
                        color: kGreyTextColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  MyText(
                    text: r['reply'],
                    size: 13,
                    weight: FontWeight.w400,
                    color: kBlackColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Bottom row: extra count + reply/edit button ────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Extra count badge
              if (r['extraCount'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kTertiaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: MyText(
                    text: r['extraCount'],
                    size: 12,
                    weight: FontWeight.w600,
                    color: kGreyTextColor,
                  ),
                )
              else
                const SizedBox(),

              // Reply / Edit Reply button
              MyRippleEffect(
                onTap: () {},
                radius: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kLightOrangeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasReply ? Icons.edit_outlined : Icons.reply_rounded,
                        size: 13,
                        color: kSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      MyText(
                        text: hasReply ? 'Edit Reply' : 'Reply',
                        size: 12,
                        weight: FontWeight.w700,
                        color: kSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stars builder ──────────────────────────────────────────────────────────
  Widget _buildStars(int count, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < count ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i < count ? const Color(0xffFFB800) : kTertiaryColor,
        );
      }),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 20, bottom: 30, right: 20),
      child: MyButton(
        buttonText: 'View More Reviews',
        onTap: () {},
        backgroundColor: kPrimaryColor,
        fontColor: kBlackColor,
        outlineColor: kSecondaryColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 52,
        radius: 100,
      ),
    );
  }
}

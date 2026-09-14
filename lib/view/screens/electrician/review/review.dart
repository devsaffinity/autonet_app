import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/data/repositories/reviews_repository.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ElectricianReviewPage extends StatefulWidget {
  const ElectricianReviewPage({super.key, this.targetId});

  final String? targetId;

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

  bool _loading = true;
  double _average = 0.0;
  int _total = 0;
  Map<int, int> _counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  List<Review> _realReviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final myId = widget.targetId ?? ProfileController.ensure().me?.id;
    if (myId == null || myId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (Get.isRegistered<ReviewsRepository>()) {
      final res = await Get.find<ReviewsRepository>()
          .forTarget(targetId: myId, limit: 50);
      if (mounted && res is Ok<ReviewsPage>) {
        setState(() {
          _realReviews = res.value.items;
          _average = res.value.summary.average;
          _total = res.value.meta.total;
          _counts = res.value.summary.counts;
          _loading = false;
        });
        return;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Review> get _filteredReviews {
    switch (_selectedFilter) {
      case 1:
        return _realReviews.where((r) => r.rating == 5).toList();
      case 2:
        return _realReviews.where((r) => r.rating == 4).toList();
      case 3:
        return _realReviews.where((r) => r.rating == 3).toList();
      case 4:
        return _realReviews.where((r) => r.rating <= 2).toList();
      default:
        return _realReviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _filteredReviews;

    return Scaffold(
      appBar: GeneralAppBar(title: "Reviews"),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kSecondaryColor),
            )
          : RefreshIndicator(
              color: kSecondaryColor,
              onRefresh: _loadReviews,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                    if (reviews.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 16),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(Icons.rate_review_outlined,
                                size: 48, color: kGreyTextColor),
                            const SizedBox(height: 12),
                            MyText(
                              text: _realReviews.isEmpty
                                  ? 'No reviews yet'
                                  : 'No reviews matching this filter',
                              size: 15,
                              weight: FontWeight.w600,
                              color: kBlackColor,
                            ),
                            const SizedBox(height: 6),
                            MyText(
                              text: _realReviews.isEmpty
                                  ? 'Reviews from your clients will appear here once bookings are completed.'
                                  : 'Try selecting a different filter above.',
                              size: 13,
                              weight: FontWeight.w400,
                              color: kGreyTextColor,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...reviews.map((r) => _buildReviewCard(r)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Overall Quality ────────────────────────────────────────────────────────
  Widget _buildOverallQuality() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
            text: _total == 0 ? '0.0' : _average.toStringAsFixed(1),
            size: 48,
            weight: FontWeight.w800,
            color: kBlackColor,
            textAlign: TextAlign.center,
            paddingBottom: 6,
          ),
          _buildStars(_average.round(), size: 28),
          const SizedBox(height: 6),
          MyText(
            text: 'Based On $_total ${_total == 1 ? 'Review' : 'Reviews'}',
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      width: Get.width,
      decoration: AppStyling().myShadowDecoration(
        color: kWhiteColor,
        radius: 15,
      ),
      child: Column(
        children: [5, 4, 3, 2, 1].map((star) {
          final count = _counts[star] ?? 0;
          final percent = _total > 0 ? (count / _total).clamp(0.0, 1.0) : 0.0;
          final label = _total > 0 ? '${(percent * 100).round()}%' : '0%';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Star number
                SizedBox(
                  width: 12,
                  child: MyText(
                    text: '$star',
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
                      value: percent,
                      minHeight: 7,
                      backgroundColor: kTertiaryColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percent > 0 ? kSecondaryColor : kTertiaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Percent label
                SizedBox(
                  width: 30,
                  child: MyText(
                    text: label,
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
  Widget _buildReviewCard(Review r) {
    final hasReply = r.reply != null;
    final reviewerName = r.author?.name?.trim().isNotEmpty == true
        ? r.author!.name!.trim()
        : 'Anonymous Buyer';
    final avatarUrl = r.author?.avatarUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
              // Avatar: real buyer image from S3, with InitialsAvatar fallback
              if (avatarUrl != null && avatarUrl.isNotEmpty)
                CommonImageView(
                  url: avatarUrl,
                  width: 42,
                  height: 42,
                  radius: 10,
                  fit: BoxFit.cover,
                )
              else
                InitialsAvatar(
                  name: reviewerName,
                  size: 42,
                  radius: 10,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: MyText(
                            text: reviewerName,
                            size: 14,
                            weight: FontWeight.w700,
                            color: kBlackColor,
                            maxLines: 1,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                        ),
                        MyText(
                          text: formatDayMonthYear(r.createdAt.toLocal()),
                          size: 11,
                          weight: FontWeight.w400,
                          color: kGreyTextColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    _buildStars(r.rating, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Review text ────────────────────────────────────────────────────
          if (r.text != null && r.text!.isNotEmpty)
            MyText(
              text: r.text!,
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
                    text: r.reply!.text,
                    size: 13,
                    weight: FontWeight.w400,
                    color: kBlackColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
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
}

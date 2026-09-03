import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/buyer/detail/offer_detail.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class ComparisonReportPage extends StatelessWidget {
  const ComparisonReportPage({super.key});

  static const List<Map<String, dynamic>> _offers = [
    {
      'name': 'Micheal Schofield',
      'subtitle': 'Premium quality with fast turnaround',
      'rating': '4.8',
      'price': '\$1250.00',
      'isLowest': true,
      'delivery': '7 days',
      'isFastest': true,
      'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    {
      'name': 'Alex Mahone',
      'subtitle': 'Premium quality with fast turnaround',
      'rating': '4.8',
      'price': '\$1250.00',
      'isLowest': true,
      'delivery': '7 days',
      'isFastest': true,
      'avatar': 'https://randomuser.me/api/portraits/men/45.jpg',
    },
  ];

  // Quick comparison table data
  static const List<String> _tableHeaders = [
    'Name',
    'Micheal',
    'Schofield',
    'Mahone',
  ];
  static const List<Map<String, String>> _tableRows = [
    {'label': 'Ratings', 'micheal': '4.8', 'schofield': '4.8', 'mahone': '4.8'},
    {
      'label': 'Price',
      'micheal': '\$1250.0',
      'schofield': '\$1000.0',
      'mahone': '\$1100',
    },
    {
      'label': 'Delivery time',
      'micheal': '7 Days',
      'schofield': '9 Days',
      'mahone': '2 Days',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "Comparison Report", centerdTitle: false),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._offers.map(
              (o) => _OfferDetailCard(
                name: o['name'],
                subtitle: o['subtitle'],
                rating: o['rating'],
                price: o['price'],
                isLowest: o['isLowest'],
                delivery: o['delivery'],
                isFastest: o['isFastest'],
                avatarUrl: o['avatar'],
              ),
            ),

            const SizedBox(height: 8),

            // ── Quick Comparison table
            MyText(
              text: 'Quick Comparison',
              size: 20,
              weight: FontWeight.w700,
              paddingBottom: 8,
            ),

            _QuickComparisonTable(headers: _tableHeaders, rows: _tableRows),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offer Detail Card
// ─────────────────────────────────────────────────────────────────────────────

class _OfferDetailCard extends StatelessWidget {
  final String name, subtitle, rating, price, delivery, avatarUrl;
  final bool isLowest, isFastest;

  const _OfferDetailCard({
    required this.name,
    required this.subtitle,
    required this.rating,
    required this.price,
    required this.delivery,
    required this.avatarUrl,
    this.isLowest = false,
    this.isFastest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name row + X
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonImageView(
                url: avatarUrl,
                height: 36,
                width: 36,
                radius: 18,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: name,
                      size: 20,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                    ),
                    MyText(
                      text: subtitle + " sdsdads",
                      size: 13,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.close, size: 18, color: kBlackColor),
            ],
          ),

          // ── Rating
          MyText(
            paddingTop: 12,
            text: 'Rating',
            size: 14,
            weight: FontWeight.w400,
            color: kGreyTextColor,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, size: 25, color: Colors.amber),
              const SizedBox(width: 4),
              MyText(
                text: rating,
                size: 24,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Price
          MyText(
            text: 'Price',
            size: 14,
            weight: FontWeight.w400,
            color: kGreyTextColor,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              MyText(
                text: price,
                size: 24,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
              const SizedBox(width: 8),
              if (isLowest) _Badge(label: 'Lowest', color: kSecondaryColor),
            ],
          ),

          const SizedBox(height: 12),

          // ── Delivery Time
          MyText(
            text: 'Delivery Time',
            size: 14,
            weight: FontWeight.w400,
            color: kGreyTextColor,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              MyText(
                text: delivery,
                size: 24,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
              const SizedBox(width: 8),
              if (isFastest) _Badge(label: 'Fastest', color: kSecondaryColor),
            ],
          ),

          const SizedBox(height: 16),

          // ── Buttons
          Row(
            children: [
              Expanded(
                child: MyButton(
                  buttonText: ' Accept Offer',
                  height: 36,
                  radius: 8,
                  fontSize: 13,
                  icon: Assets.imagesCheck,
                  haveSvg: true,
                  onTap: () {
                    Get.to(() => OfferDetailPage());
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MyButton(
                  buttonText: 'Accept Offer',
                  height: 36,
                  radius: 8,
                  fontSize: 13,
                  backgroundColor: kPrimaryColor,
                  outlineColor: kSecondaryColor,
                  fontColor: kSecondaryColor,
                  icon: Assets.imagesRChat,
                  haveSvg: true,
                  onTap: () {
                    Get.to(() => OfferDetailPage());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge (Lowest / Fastest)
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: MyText(
        text: label,
        size: 12,
        color: color,
        weight: FontWeight.w600,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Comparison Table
// ─────────────────────────────────────────────────────────────────────────────

class _QuickComparisonTable extends StatelessWidget {
  final List<String> headers;
  final List<Map<String, String>> rows;

  const _QuickComparisonTable({required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffFCECEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ── Header row
          _TableRow(cells: headers, isHeader: true),

          // ── Data rows
          ...rows.asMap().entries.map((e) {
            final r = e.value;
            final isRating = r['label'] == 'Ratings';
            return _TableRow(
              cells: [
                r['label']!,
                r['micheal']!,
                r['schofield']!,
                r['mahone']!,
              ],
              isEven: e.key % 2 == 0,
              showStarForRating: isRating,
            );
          }),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;
  final bool isEven;
  final bool showStarForRating;

  const _TableRow({
    required this.cells,
    this.isHeader = false,
    this.isEven = false,
    this.showStarForRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSecondaryColor.withValues(alpha: .1),
        // color: isHeader
        //     ? Colors.transparent
        //     : isEven
        //     ? kPrimaryColor.withOpacity(0.5)
        //     : Colors.transparent,
        // borderRadius: isHeader
        //     ? const BorderRadius.vertical(top: Radius.circular(12))
        //     : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: cells.asMap().entries.map((e) {
          final isFirst = e.key == 0;
          final isRatingValue = showStarForRating && !isFirst;

          return Expanded(
            child: isRatingValue
                ? Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      MyText(
                        text: e.value,
                        size: 12,
                        color: kBlackColor,
                        weight: FontWeight.w500,
                      ),
                    ],
                  )
                : MyText(
                    text: e.value,
                    size: isHeader ? 12 : 12,
                    weight: isHeader || isFirst
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: isHeader
                        ? kBlackColor
                        : isFirst
                        ? kBlackColor
                        : kBlackColor,
                  ),
          );
        }).toList(),
      ),
    );
  }
}

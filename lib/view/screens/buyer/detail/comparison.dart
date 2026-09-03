import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/buyer/detail/report.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ComparisonPage extends StatelessWidget {
  const ComparisonPage({super.key});

  // ── Dummy data
  static const List<Map<String, dynamic>> _compareOffers = [
    {
      'name': 'Sarah Johnson',
      'price': '\$3000',
      'rating': '4.8',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
    },
    {
      'name': 'Sarah Johnson',
      'price': '\$3000',
      'rating': '4.8',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
    },
  ];

  static const List<Map<String, dynamic>> _allOffers = [
    {
      'name': 'Sarah Johnson',
      'price': '\$3000',
      'rating': '4.8',
      'delivery': 'Delivery upto 24h',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'selected': true,
    },
    {
      'name': 'Sarah Johnson',
      'price': '\$3000',
      'rating': '4.8',
      'delivery': 'Delivery upto 24h',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'selected': true,
    },
    {
      'name': 'Sarah Johnson',
      'price': '\$3000',
      'rating': '4.8',
      'delivery': 'Delivery upto 24h',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'selected': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── AppBar
            Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 50),
              width: double.infinity,
              height: 250,
              decoration: AppStyling().allFourSideRaius(
                color: const Color(0xffFCECEA),
                topLeft: 0,
                topRight: 0,
                bottomLeft: 30,
                bottomRight: 30,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      MyRippleEffect(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: kBlackColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      MyText(
                        text: 'Ford Mustang GT',
                        size: 16,
                        weight: FontWeight.w600,
                        color: kBlackColor,
                      ),
                    ],
                  ),
                  CommonImageView(
                    imagePath: Assets.imagesCar1,
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            Padding(
              padding: AppSizes.HORIZONTAL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Offers header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MyText(
                        text: 'Offers',
                        size: 16,
                        weight: FontWeight.w700,
                        color: kBlackColor,
                      ),
                      MyText(
                        text: '(2)',
                        size: 12,
                        color: kSecondaryColor,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),

                  MyText(
                    paddingTop: 4,
                    paddingBottom: 12,
                    text: 'Compare & choose the best offer for your needs',
                    size: 14,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                  ),

                  // ── Comparing card
                  _ComparingCard(offers: _compareOffers),

                  const SizedBox(height: 20),

                  // ── Showing N offers label
                  MyText(
                    text: 'Showing 8 offers',
                    size: 14,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                    paddingBottom: 10,
                  ),

                  // ── All offer cards
                  ..._allOffers.map(
                    (o) => _OfferCard(
                      name: o['name'],
                      price: o['price'],
                      rating: o['rating'],
                      delivery: o['delivery'],
                      avatarUrl: o['avatar'],
                      isSelected: o['selected'],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comparing Card (top comparison box with 1 or 2 offers)
// ─────────────────────────────────────────────────────────────────────────────

class _ComparingCard extends StatelessWidget {
  final List<Map<String, dynamic>> offers;

  const _ComparingCard({required this.offers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: AppStyling().myDecoration(
        color: kSecondaryColor.withValues(alpha: .1),
        borderColor: kSecondaryColor,
      ),
      child: Column(
        children: [
          // ── Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text: 'Comparing ${offers.length} offer',
                size: 16,
                weight: FontWeight.w600,
                color: kSecondaryColor,
              ),
              MyText(
                onTap: () {
                  Get.to(() => ComparisonReportPage());
                },
                text: 'View Comparison',
                size: 12,
                color: kSecondaryColor,
                weight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ],
          ),
          SizedBox(height: 12),

          // ── Each compared offer row
          ...offers.asMap().entries.map((e) {
            final isLast = e.key == offers.length - 1;
            return Column(
              children: [
                _CompareRow(
                  name: e.value['name'],
                  price: e.value['price'],
                  rating: e.value['rating'],
                  avatarUrl: e.value['avatar'],
                ),
                if (!isLast) const Divider(height: 1, color: Color(0xffF0F0F0)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String name, price, rating, avatarUrl;

  const _CompareRow({
    required this.name,
    required this.price,
    required this.rating,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      decoration: AppStyling().myDecoration(
        color: kPrimaryColor,
        borderColor: kTransperentColor,
        radius: 10,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            // ── Name + X
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CommonImageView(
                      url: avatarUrl,
                      height: 24,
                      width: 24,
                      radius: 14,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 8),
                    MyText(
                      text: name,
                      size: 16,
                      weight: FontWeight.w600,
                      color: kSecondaryColor,
                    ),
                  ],
                ),
                const Icon(Icons.close, size: 20, color: kGreyTextColor),
              ],
            ),
            const SizedBox(height: 8),
            // ── Price + Rating + Contact
            Row(
              children: [
                CommonImageView(svgPath: Assets.imagesCpA),
                const SizedBox(width: 4),
                MyText(text: price, size: 14, weight: FontWeight.w400),
                const Spacer(),
                CommonImageView(svgPath: Assets.imagesCpB),
                const SizedBox(width: 4),
                MyText(text: rating, size: 14, weight: FontWeight.w400),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(
                  text: 'Contact Seller',
                  size: 14,
                  weight: FontWeight.w600,
                ),
                CommonImageView(svgPath: Assets.imagesCpC),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single Offer Card (bottom list)
// ─────────────────────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final String name, price, rating, delivery, avatarUrl;
  final bool isSelected;

  const _OfferCard({
    required this.name,
    required this.price,
    required this.rating,
    required this.delivery,
    required this.avatarUrl,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlackColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Name + Rating + Delivery
          Row(
            children: [
              CommonImageView(
                url: avatarUrl,
                height: 24,
                width: 24,
                radius: 16,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MyText(
                  text: name,
                  size: 16,
                  weight: FontWeight.w600,
                  color: kSecondaryColor,
                ),
              ),
              CommonImageView(svgPath: Assets.imagesCpB),
              const SizedBox(width: 4),
              MyText(text: rating, size: 14, weight: FontWeight.w400),
            ],
          ),

          const SizedBox(height: 8),

          // ── Price + Contact
          Row(
            children: [
              CommonImageView(svgPath: Assets.imagesCpA),
              const SizedBox(width: 4),
              MyText(
                text: price,
                size: 14,
                weight: FontWeight.w400,
                color: kBlackColor,
              ),
              const Spacer(),
              CommonImageView(svgPath: Assets.imagesCpD),
              const SizedBox(width: 4),
              MyText(
                text: delivery,
                size: 14,
                weight: FontWeight.w400,
                color: kBlackColor,
              ),
            ],
          ),
          SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(text: 'Contact Seller', size: 14, weight: FontWeight.w600),
              CommonImageView(svgPath: Assets.imagesCpC),
            ],
          ),

          const SizedBox(height: 12),

          // ── Action buttons
          Row(
            children: [
              // Delete Offer
              Expanded(
                child: MyButton(
                  buttonText: 'Delete Offer',
                  backgroundColor: kTransperentColor,
                  outlineColor: kTransperentColor,
                  fontColor: Colors.red,
                  fontSize: 12,
                  height: 36,
                  fontWeight: FontWeight.w600,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              // View Offer
              Expanded(
                child: MyButton(
                  buttonText: 'View Offer',
                  backgroundColor: kTransperentColor,
                  outlineColor: kTransperentColor,
                  fontColor: kBlackColor,
                  fontSize: 12,
                  height: 36,
                  fontWeight: FontWeight.w600,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              // Selected
              Expanded(
                child: MyButton(
                  buttonText: isSelected ? 'Selected' : 'Select',
                  backgroundColor: isSelected
                      ? kSecondaryColor
                      : kSecondaryColor.withOpacity(0.1),
                  outlineColor: kTransperentColor,
                  fontColor: kWhiteColor,
                  fontSize: 12,
                  height: 36,
                  radius: 5,
                  fontWeight: FontWeight.w600,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

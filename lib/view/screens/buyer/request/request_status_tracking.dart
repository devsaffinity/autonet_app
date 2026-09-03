import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/buyer/detail/comparison.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestStatusTrackingPage extends StatelessWidget {
  const RequestStatusTrackingPage({super.key});

  // ── The buyer's open requests. Typed rows rather than five identical
  // defaults, so the tapped item can actually travel to ComparisonPage.
  // Only one vehicle render exists in assets/images/ (car_1), so every row
  // carries it. Per-vehicle imagery is a design/API deliverable — do not invent
  // Assets keys with no file behind them.
  static const List<Map<String, dynamic>> _requests = [
    {
      'brand': 'TOYOTA',
      'model': '21 i8 Gran Coupe',
      'offers': 4,
      'days': '1 Day',
      'date': '12/08/2025',
      'partType': 'Engine',
      'image': Assets.imagesCar1,
    },
    {
      'brand': 'MERCEDES BENZ',
      'model': 'C 300 AMG Line',
      'offers': 2,
      'days': '3 Days',
      'date': '09/08/2025',
      'partType': 'Transmission',
      'image': Assets.imagesCar1,
    },
    {
      'brand': 'FORD',
      'model': 'Mustang GT',
      'offers': 6,
      'days': '5 Days',
      'date': '04/08/2025',
      'partType': 'Brakes',
      'image': Assets.imagesCar1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        hasBackButton: false,
        title: "Request Status Tracking",
        action: [
          // AddPartRequestPage had zero inbound navigation in lib/ before this.
          MyRippleEffect(
            radius: 100,
            onTap: () => Get.to(() => const AddPartRequestPage()),
            splashColor: kSecondaryColor.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: CommonImageView(
                width: 22,
                svgPath: Assets.imagesMsAdd,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            // Search bar
            MySearchBar(),
            //Cards List
            ..._requests.map(
              (r) => _Card(
                brand: r['brand'],
                model: r['model'],
                offersCount: r['offers'],
                days: r['days'],
                date: r['date'],
                partType: r['partType'],
                image: r['image'],
                onViewOffers: () {
                  Get.to(
                    () => ComparisonPage(
                      title: r['model'],
                      partType: r['partType'],
                      offersCount: r['offers'],
                      image: r['image'],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

class MySearchBar extends StatelessWidget {
  const MySearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return MyTextField(
      hintText: "Search Vehicle",
      prefix: SizedBox(
        width: 30,
        child: MyRippleEffect(
          onTap: () {},
          splashColor: kSecondaryColor.withValues(alpha: 0.2),
          child: Center(
            child: CommonImageView(
              width: 25,
              imagePath: Assets.imagesSearchPrimaryIcon,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      suffix: SizedBox(
        width: 30,
        child: MyRippleEffect(
          onTap: () {},
          splashColor: kSecondaryColor.withValues(alpha: 0.2),
          child: Center(
            child: CommonImageView(
              width: 25,
              imagePath: Assets.imagesFunnelIcon,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      radius: 9,
    );
  }
}

class _Card extends StatelessWidget {
  final String brand;
  final String model;
  final int offersCount;
  final String days;
  final String date;
  final String partType;
  final String image;
  final VoidCallback? onViewOffers;

  const _Card({
    this.brand = 'TOYOTA',
    this.model = '21 i8 Gran Coupe',
    this.offersCount = 4,
    this.days = '1 Day',
    this.date = '12/08/2025',
    this.partType = 'Engine',
    this.image = Assets.imagesCar1,
    this.onViewOffers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBlackColor.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left content
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand + View Offers row
              MyText(
                text: brand,
                size: 11,
                color: kGreyTextColor,
                weight: FontWeight.w700,
              ),
              MyText(
                onTap: onViewOffers,
                text: 'View Offers',
                size: 12,
                color: kSecondaryColor,
                weight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model name
                  MyText(
                    paddingTop: 2,
                    text: model,
                    size: 14,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // ── Row 1: Offers + Days
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 90,
                        child: _InfoChip(
                          icon: Assets.imagesRsA,
                          label: '$offersCount Offers',
                        ),
                      ),
                      const SizedBox(width: 5),
                      _InfoChip(icon: Assets.imagesRsB, label: days),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Row 2: Date + Part type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 90,
                        child: _InfoChip(icon: Assets.imagesRsC, label: date),
                      ),
                      const SizedBox(width: 5),
                      _InfoChip(icon: Assets.imagesRsD, label: partType),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 10),
              // ── Car image
              CommonImageView(
                imagePath: image,
                width: 140,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small icon + label chip
class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 80,
      // color: kBlueColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonImageView(svgPath: icon),
          const SizedBox(width: 5),
          MyText(
            text: label,
            size: 12,
            color: kGreyTextColor,
            weight: FontWeight.w500,
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

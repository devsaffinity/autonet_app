import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

class BuyerHomePage extends StatelessWidget {
  const BuyerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildSectionHeader(title: 'Active Requests', onViewAll: () {}),
              const SizedBox(height: 12),
              _buildActiveRequests(),
              const SizedBox(height: 20),
              _buildSectionHeader(title: 'Offers', onViewAll: () {}),
              const SizedBox(height: 12),
              _buildOffers(),
              const SizedBox(height: 20),
              _buildSectionHeader(title: 'Service Providers', onViewAll: () {}),
              const SizedBox(height: 12),
              _buildServiceProviders(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CommonImageView(
          url: 'https://randomuser.me/api/portraits/women/44.jpg',
          height: 44,
          width: 44,
          radius: 22,
          fit: BoxFit.cover,
        ),
        Column(
          children: [
            MyText(
              text: 'Hello',
              size: 13,
              color: kGreyTextColor,
              weight: FontWeight.w400,
            ),
            MyText(
              text: 'Lorem Ipsum',
              size: 16,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
          ],
        ),
        Stack(
          children: [
            Icon(Icons.notifications_outlined, size: 28, color: kBlackColor),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                height: 8,
                width: 8,
                decoration: const BoxDecoration(
                  color: kSecondaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return MyTextField(
      marginBottom: 0,
      hintText: 'Search Here',
      prefix: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Icon(Icons.search, color: kGreyTextColor, size: 20),
      ),
    );
  }

  // ─── Section Header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(
          text: title,
          size: 16,
          weight: FontWeight.w700,
          color: kBlackColor,
        ),
        GestureDetector(
          onTap: onViewAll,
          child: MyText(
            text: 'View All',
            size: 13,
            color: kSecondaryColor,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Active Requests ───────────────────────────────────────────────────────

  Widget _buildActiveRequests() {
    final List<Map<String, String>> requests = [
      {
        'image':
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
        'name': 'Mercedes Benz',
        'id': 'BND-123-66',
        'detail': '1.9MDHJLI',
        'label': 'Part No',
        'value': '4SYP119',
        'condition': 'Engine',
      },
      {
        'image':
            'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400',
        'name': 'Toyota Yaris',
        'id': 'BND-',
        'detail': '',
        'label': 'Condition',
        'value': 'Used',
        'condition': 'Engine',
      },
    ];

    return SizedBox(
      height: 175,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final r = requests[index];
          return _ActiveRequestCard(
            imageUrl: r['image']!,
            name: r['name']!,
            requestId: r['id']!,
            carDetail: r['detail']!,
            infoLabel: r['label']!,
            infoValue: r['value']!,
            conditionLabel: r['condition']!,
          );
        },
      ),
    );
  }

  // ─── Offers ────────────────────────────────────────────────────────────────

  Widget _buildOffers() {
    final List<Map<String, String>> offers = [
      {
        'brand': 'TOYOTA',
        'model': '21 i8 Gran Coupe',
        'date': '12/08/2025',
        'type': 'Engine',
        'price': '\$4000',
        'image':
            'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=400',
      },
      {
        'brand': 'TOYOTA',
        'model': '21 i8 Gran Coupe',
        'date': '12/08/2025',
        'type': 'Transmission',
        'price': '\$2500',
        'image':
            'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?w=400',
      },
    ];

    return Column(
      children: offers
          .map(
            (o) => _OfferCard(
              brand: o['brand']!,
              model: o['model']!,
              date: o['date']!,
              type: o['type']!,
              price: o['price']!,
              imageUrl: o['image']!,
            ),
          )
          .toList(),
    );
  }

  // ─── Service Providers ─────────────────────────────────────────────────────

  Widget _buildServiceProviders() {
    final List<Map<String, String>> providers = [
      {
        'name': 'Abc Garage',
        'brands': 'BMW, Mercedes, KIA +2',
        'rating': '4.5/5.0',
        'image': 'https://randomuser.me/api/portraits/men/32.jpg',
      },
      {
        'name': '123 Motors',
        'brands': 'BMW, Mercedes, KIA +2',
        'rating': '4.5/5.0',
        'image': 'https://randomuser.me/api/portraits/men/45.jpg',
      },
    ];

    return Row(
      children: providers
          .map(
            (p) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: providers.indexOf(p) == 0 ? 8 : 0,
                  left: providers.indexOf(p) == 1 ? 8 : 0,
                ),
                child: _ServiceProviderCard(
                  name: p['name']!,
                  brands: p['brands']!,
                  rating: p['rating']!,
                  imageUrl: p['image']!,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Active Request Card ──────────────────────────────────────────────────────

class _ActiveRequestCard extends StatelessWidget {
  final String imageUrl,
      name,
      requestId,
      carDetail,
      infoLabel,
      infoValue,
      conditionLabel;

  const _ActiveRequestCard({
    required this.imageUrl,
    required this.name,
    required this.requestId,
    required this.carDetail,
    required this.infoLabel,
    required this.infoValue,
    required this.conditionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlackColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CommonImageView(
              url: imageUrl,
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: MyText(
                        text: name,
                        size: 12,
                        weight: FontWeight.w600,
                        color: kBlackColor,
                      ),
                    ),
                    MyText(
                      text: requestId,
                      size: 10,
                      color: kSecondaryColor,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (carDetail.isNotEmpty)
                      MyText(text: carDetail, size: 10, color: kGreyTextColor),
                    const Spacer(),
                    Icon(Icons.settings, size: 12, color: kSecondaryColor),
                    const SizedBox(width: 2),
                    MyText(text: conditionLabel, size: 10, color: kBlackColor),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    MyText(
                      text: '$infoLabel  ',
                      size: 10,
                      color: kGreyTextColor,
                    ),
                    MyText(
                      text: infoValue,
                      size: 10,
                      color: kBlackColor,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Offer Card ──────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final String brand, model, date, type, price, imageUrl;

  const _OfferCard({
    required this.brand,
    required this.model,
    required this.date,
    required this.type,
    required this.price,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlackColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: brand,
                  size: 11,
                  color: kGreyTextColor,
                  weight: FontWeight.w500,
                ),
                const SizedBox(height: 2),
                MyText(
                  text: model,
                  size: 13,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kSecondaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: kWhiteColor,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          MyText(text: date, size: 10, color: kWhiteColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kSecondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.settings,
                            color: kSecondaryColor,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          MyText(text: type, size: 10, color: kSecondaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MyText(
                text: price,
                size: 16,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
              const SizedBox(height: 8),
              CommonImageView(
                url: imageUrl,
                width: 110,
                height: 60,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Service Provider Card ───────────────────────────────────────────────────

class _ServiceProviderCard extends StatelessWidget {
  final String name, brands, rating, imageUrl;

  const _ServiceProviderCard({
    required this.name,
    required this.brands,
    required this.rating,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlackColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CommonImageView(
            url: imageUrl,
            height: 60,
            width: 60,
            radius: 30,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 8),
          MyText(
            text: name,
            size: 13,
            weight: FontWeight.w700,
            color: kBlackColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          MyText(
            text: brands,
            size: 10,
            color: kGreyTextColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              MyText(
                text: rating,
                size: 11,
                color: kBlackColor,
                weight: FontWeight.w500,
              ),
            ],
          ),
          const SizedBox(height: 10),
          MyButton(buttonText: 'Book Now', height: 34, fontSize: 12),
        ],
      ),
    );
  }
}

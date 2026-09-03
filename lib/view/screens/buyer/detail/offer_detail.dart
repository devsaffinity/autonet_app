import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/buyer/detail/order_summary.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OfferDetailPage extends StatefulWidget {
  // ── Seller
  final String sellerName, avatarUrl, rating, reviewCount, location;
  // ── What the offer is for. Not rendered here, but carried through to
  //    OrderSummaryPage so the summary stops inventing its own literals.
  final String vehicle, partName, delivery;
  // ── Part detail
  final String partBrand, partNumber, warranty, condition;
  // ── Money
  final String price, deliveryFee, totalPrice;

  /// Every field defaults to the literal this screen used to hard-code, so an
  /// argument-less `OfferDetailPage()` still renders exactly as before.
  const OfferDetailPage({
    super.key,
    this.sellerName = 'AutoParts Hub',
    this.avatarUrl = 'https://randomuser.me/api/portraits/men/32.jpg',
    this.rating = '4.8',
    this.reviewCount = '234',
    this.location = 'Bole Road, Addis Ababa • USA',
    this.vehicle = '2020 Toyota Corolla',
    this.partName = 'Front Brake Pads',
    this.delivery = 'Today (2–4 hours)',
    this.partBrand = 'Toyota OEM',
    this.partNumber = '04465-02280',
    this.warranty = '12 months',
    this.condition = 'Brand New',
    this.price = '3,200 ETB',
    this.deliveryFee = '300 ETB',
    this.totalPrice = '3,500 ETB',
  });

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFCECEA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header section (pink bg)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 25),
              child: Column(
                children: [
                  // ── Shop info row + X
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonImageView(
                        url: widget.avatarUrl,
                        height: 48,
                        width: 48,
                        radius: 24,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(
                              text: widget.sellerName,
                              size: 16,
                              weight: FontWeight.w700,
                              color: kBlackColor,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 17,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                MyText(
                                  text: widget.rating,
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: kBlackColor,
                                ),
                                MyText(
                                  text: ' (${widget.reviewCount} reviews)',
                                  size: 12,
                                  weight: FontWeight.w400,
                                  color: kGreyTextColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: kGreyTextColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: MyText(
                                    text: widget.location,
                                    size: 16,
                                    weight: FontWeight.w400,
                                    color: kGreyTextColor,
                                    maxLines: 1,
                                    textOverflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: kBlackColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── White body with tab bar + content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
                ),
                child: Column(
                  children: [
                    // ── Tab bar
                    TabBar(
                      controller: _tabController,
                      indicatorColor: kSecondaryColor,
                      indicatorWeight: 2.5,
                      labelColor: kSecondaryColor,
                      unselectedLabelColor: kGreyTextColor,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      tabs: const [
                        Tab(text: 'Details'),
                        Tab(text: 'Reviews'),
                      ],
                    ),

                    // ── Tab views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _DetailsTab(
                            partBrand: widget.partBrand,
                            partNumber: widget.partNumber,
                            warranty: widget.warranty,
                            condition: widget.condition,
                            price: widget.price,
                            deliveryFee: widget.deliveryFee,
                            totalPrice: widget.totalPrice,
                          ),
                          _ReviewsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom buttons
            Container(
              color: kPrimaryColor,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: MyButton(
                      buttonText: 'Delete Offer',
                      height: 48,
                      fontSize: 14,
                      onTap: () {
                        Get.close(1);
                      },
                      radius: 9,
                      haveSvg: true,

                      icon: Assets.imagesDeleteOferIcon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyButton(
                      buttonText: 'Confirm Offer',
                      height: 48,
                      fontSize: 14,
                      radius: 9,
                      backgroundColor: kPrimaryColor,
                      outlineColor: kSecondaryColor,
                      fontColor: kSecondaryColor,
                      haveSvg: true,
                      icon: Assets.imagesCheckOrange,
                      onTap: () {
                        Get.to(
                          () => OrderSummaryPage(
                            vehicle: widget.vehicle,
                            partName: widget.partName,
                            partBrand: widget.partBrand,
                            partNumber: widget.partNumber,
                            sellerName: widget.sellerName,
                            estimatedTime: widget.delivery,
                            partPrice: widget.price,
                            deliveryFee: widget.deliveryFee,
                            totalPrice: widget.totalPrice,
                          ),
                        );
                      },
                    ),
                  ),
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
// Details Tab
// ─────────────────────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final String partBrand, partNumber, warranty, condition;
  final String price, deliveryFee, totalPrice;

  const _DetailsTab({
    required this.partBrand,
    required this.partNumber,
    required this.warranty,
    required this.condition,
    required this.price,
    required this.deliveryFee,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          // ── Part Details card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card header
                Row(
                  children: [
                    CommonImageView(svgPath: Assets.imagesPartBox),
                    const SizedBox(width: 10),
                    MyText(
                      text: 'Part Details',
                      size: 16,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Brand / Part Number
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(label: 'Brand', value: partBrand),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Part Number',
                        value: partNumber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Warranty / Condition
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(label: 'Warranty', value: warranty),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            text: 'Condition',
                            size: 11,
                            color: kGreyTextColor,
                            paddingBottom: 4,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: AppStyling().myDecoration(
                              color: kSecondaryColor.withValues(alpha: .1),
                              borderColor: kTransperentColor,
                              radius: 100,
                            ),
                            child: MyText(
                              text: condition,
                              size: 12,
                              color: kSecondaryColor,
                              weight: FontWeight.w600,
                            ),
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

          // ── Price Breakdown card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Price Breakdown',
                  size: 16,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                  paddingBottom: 16,
                ),

                _PriceRow(label: 'Part Price', value: price),
                const SizedBox(height: 12),
                _PriceRow(label: 'Delivery Fee', value: deliveryFee),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: kGreyTextColor),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText(
                      text: 'Total Price',
                      size: 14,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                    ),
                    MyText(
                      text: totalPrice,
                      size: 14,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews Tab (placeholder)
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: MyText(text: 'No reviews yet', size: 14, color: kGreyTextColor),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable white card container
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBlackColor.withOpacity(0.07)),
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
// Detail label + value pair
// ─────────────────────────────────────────────────────────────────────────────

class _DetailItem extends StatelessWidget {
  final String label, value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: label,
          size: 14,
          weight: FontWeight.w400,
          color: kGreyTextColor,
          paddingBottom: 4,
        ),
        MyText(
          text: value,
          size: 14,
          weight: FontWeight.w600,
          color: kBlackColor,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Price row (label + value)
// ─────────────────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label, value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(
          text: label,
          size: 14,
          weight: FontWeight.w400,
          color: kBlackColor,
        ),
        MyText(
          text: value,
          size: 14,
          weight: FontWeight.w400,
          color: kBlackColor,
        ),
      ],
    );
  }
}

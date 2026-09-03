import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/buyer/detail/order_status.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class OrderSummaryPage extends StatelessWidget {
  const OrderSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "Order Summary", centerdTitle: false),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Order Details card
            _SectionCard(
              title: 'Order Details',
              child: Column(
                children: [
                  _OrderRow(
                    icon: Assets.imagesSummaryA,
                    topLabel: 'Vehicle',
                    mainText: '2020 Toyota Corolla',
                  ),
                  const _Divider(),
                  _OrderRow(
                    icon: Assets.imagesSummaryB,
                    topLabel: 'Part Ordered',
                    mainText: 'Front Brake Pads',
                    bottomWidget: Row(
                      children: [
                        MyText(
                          text: 'Brand: Toyota OEM',
                          size: 12,
                          color: kGreyTextColor,
                        ),
                        const SizedBox(width: 12),
                        MyText(
                          text: 'Part #: 04465-02280',
                          size: 12,
                          color: kGreyTextColor,
                        ),
                      ],
                    ),
                  ),
                  const _Divider(),
                  _OrderRow(
                    icon: Assets.imagesSummaryC,
                    topLabel: 'Seller',
                    mainText: 'AutoParts Hub',
                    bottomWidget: MyText(
                      text: 'Bole Road, Near Atlas Hotel',
                      size: 12,
                      color: kGreyTextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Delivery Method card
            _SectionCard(
              title: 'Delivery Method',
              child: _OrderRow(
                icon: Assets.imagesSummaryD,
                topLabel: 'Delivery to Location',
                mainText: 'Delivered to: Bole, Addis Ababa',
                bottomWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: 'Estimated time: Today (2–4 hours)',
                      size: 12,
                      color: kGreyTextColor,
                    ),
                    const SizedBox(height: 2),
                    MyText(
                      text: 'Delivery fee: 300 ETB',
                      size: 12,
                      color: kSecondaryColor,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Price Breakdown card
            _SectionCard(
              title: 'Price Breakdown',
              child: Column(
                children: [
                  _PriceRow(label: 'Part Price', value: '3,200 ETB'),
                  const SizedBox(height: 12),
                  _PriceRow(label: 'Delivery Fee', value: '300 ETB'),
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
                        text: '3,500 ETB',
                        size: 14,
                        weight: FontWeight.w700,
                        color: kSecondaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Place Order button
            MyButton(
              mBottom: 30,
              buttonText: 'Place Order',
              onTap: () {
                Get.to(() => OrderStatusPage());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card (white rounded card with title)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: MyText(
              text: title,
              size: 16,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order Row (icon + top label + main text + optional bottom widget)
// ─────────────────────────────────────────────────────────────────────────────

class _OrderRow extends StatelessWidget {
  final String icon;
  final String topLabel;
  final String mainText;
  final Widget? bottomWidget;

  const _OrderRow({
    required this.icon,
    required this.topLabel,
    required this.mainText,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container
        CommonImageView(svgPath: icon),
        const SizedBox(width: 12),

        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: topLabel,
                size: 14,
                weight: FontWeight.w400,
                color: kGreyTextColor,
                paddingBottom: 2,
              ),
              MyText(
                text: mainText,
                size: 16,
                weight: FontWeight.w500,
                color: kBlackColor,
              ),
              if (bottomWidget != null) ...[
                const SizedBox(height: 4),
                bottomWidget!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Price Row
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

// ─────────────────────────────────────────────────────────────────────────────
// Thin divider between order rows
// ─────────────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Color(0xffEEEEEE)),
    );
  }
}

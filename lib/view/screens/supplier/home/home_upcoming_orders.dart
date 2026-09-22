import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_order_detail.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_orders.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Upcoming / Active Orders feed matching Figma with status chips, part info,
/// order number, total price, and direct navigation to order fulfillment.
class SupplierUpcomingOrdersSection extends StatelessWidget {
  const SupplierUpcomingOrdersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SupplierHomeController.ensure();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText(
              text: 'Upcoming Orders',
              size: 16,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
            MyRippleEffect(
              radius: 6,
              onTap: () => Get.to(() => SupplierOrdersPage()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: MyText(
                  text: 'View All',
                  size: 13,
                  weight: FontWeight.w700,
                  color: kSecondaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final ordersState = controller.orders.value;

          return switch (ordersState) {
            Loading() => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: kSecondaryColor),
                ),
              ),
            Failed(:final error) => _buildEmptyState(
                context,
                title: 'Unable to load orders',
                subtitle: error.message,
                onRetry: controller.load,
              ),
            Empty() => _buildEmptyState(
                context,
                title: 'No Upcoming Orders',
                subtitle:
                    'When buyers accept your quotes, orders will appear here for fulfillment.',
              ),
            Data<List<Order>>(:final value) => () {
                final upcoming = value
                    .where((o) =>
                        o.status != OrderStatus.delivered &&
                        o.status != OrderStatus.cancelled)
                    .toList();

                if (upcoming.isEmpty) {
                  return _buildEmptyState(
                    context,
                    title: 'No Upcoming Orders',
                    subtitle:
                        'When buyers accept your quotes, orders will appear here for fulfillment.',
                  );
                }

                return Column(
                  children: upcoming
                      .take(2)
                      .map((o) => _UpcomingOrderCard(order: o))
                      .toList(),
                );
              }(),
          };
        }),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF1E88E5),
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          MyText(
            text: title,
            size: 15,
            weight: FontWeight.w700,
            color: kBlackColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          MyText(
            text: subtitle,
            size: 12,
            weight: FontWeight.w400,
            color: kGreyTextColor,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            MyRippleEffect(
              radius: 8,
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: kTertiaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MyText(
                  text: 'Retry',
                  size: 12,
                  weight: FontWeight.w600,
                  color: kBlackColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Order card rendered under Upcoming Orders
class _UpcomingOrderCard extends StatelessWidget {
  final Order order;

  const _UpcomingOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 6
        ? order.id.substring(order.id.length - 6)
        : order.id;
    final title = order.request.partName;
    final priceStr = '£${(order.totalPence / 100).toStringAsFixed(2)}';
    final statusLabel = order.status?.label ?? 'Placed';
    final isOutForDelivery = order.status == OrderStatus.outForDelivery;
    final badgeBg = isOutForDelivery
        ? const Color(0xFFE8F8EE)
        : const Color(0xFFFFF0EC);
    final badgeTextColor = isOutForDelivery
        ? const Color(0xFF34C759)
        : kSecondaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.to(() => SupplierOrderDetailPage(order: order)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title & Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: MyText(
                        text: title,
                        size: 14.5,
                        weight: FontWeight.w800,
                        color: kBlackColor,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Row 2: Order ID & Total
                Row(
                  children: [
                    MyText(
                      text: 'Order #$shortId',
                      size: 12,
                      weight: FontWeight.w500,
                      color: const Color(0xFF555555),
                    ),
                    if (order.deliveryMethod != null) ...[
                      const SizedBox(width: 8),
                      MyText(
                        text: '• ${order.deliveryMethod!.label}',
                        size: 12,
                        weight: FontWeight.w400,
                        color: kGreyTextColor,
                      ),
                    ],
                    const Spacer(),
                    MyText(
                      text: priceStr,
                      size: 14,
                      weight: FontWeight.w800,
                      color: kSecondaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row 3: Action button
                Row(
                  children: [
                    MyRippleEffect(
                      radius: 8,
                      onTap: () =>
                          Get.to(() => SupplierOrderDetailPage(order: order)),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kSecondaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Manage Order',
                          style: TextStyle(
                            color: kWhiteColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

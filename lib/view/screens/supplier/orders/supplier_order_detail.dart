import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/controller/supplier/supplier_orders_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/domain/order_steps.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/order_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupplierOrderDetailPage extends StatefulWidget {
  final Order? order;
  final String? orderId;

  const SupplierOrderDetailPage({
    super.key,
    this.order,
    this.orderId,
  });

  @override
  State<SupplierOrderDetailPage> createState() =>
      _SupplierOrderDetailPageState();
}

class _SupplierOrderDetailPageState extends State<SupplierOrderDetailPage> {
  late final OrdersRepository _ordersRepo;
  Order? _order;
  bool _isLoading = false;
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _ordersRepo = Get.find<OrdersRepository>();
    _order = widget.order;
    if (_order == null && widget.orderId != null && widget.orderId!.isNotEmpty) {
      _loadOrder();
    }
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final res = await _ordersRepo.byId(widget.orderId!);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res is Ok<Order>) _order = res.value;
    });
  }

  OrderStatus? _nextStatusFor(OrderStatus? current) => switch (current) {
    OrderStatus.placed => OrderStatus.preparing,
    OrderStatus.preparing => OrderStatus.outForDelivery,
    OrderStatus.outForDelivery => OrderStatus.delivered,
    _ => null,
  };

  String? _ctaFor(OrderStatus? current) => switch (current) {
    OrderStatus.placed => 'Mark as Preparing',
    OrderStatus.preparing => 'Mark as Out for Delivery',
    OrderStatus.outForDelivery => 'Mark as Delivered',
    _ => null,
  };

  Future<void> _advance() async {
    if (_isAdvancing || _order == null) return;
    final nextStatus = _nextStatusFor(_order!.status);
    if (nextStatus == null) return;

    setState(() => _isAdvancing = true);
    final res = await _ordersRepo.changeStatus(
      orderId: _order!.id,
      status: nextStatus,
    );
    if (!mounted) return;
    setState(() => _isAdvancing = false);

    switch (res) {
      case Err(:final error):
        Get.snackbar('Update Failed', error.message);
      case Ok(:final value):
        setState(() => _order = value);
        Get.snackbar(
          'Order Updated',
          'Fulfillment status is now ${value.status?.label}',
        );
        if (Get.isRegistered<SupplierOrdersController>()) {
          SupplierOrdersController.ensure().refreshForFilter();
        }
        if (Get.isRegistered<SupplierHomeController>()) {
          SupplierHomeController.ensure().load();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: GeneralAppBar(title: 'Order Details', centerdTitle: false),
        body: const Center(
          child: CircularProgressIndicator(color: kSecondaryColor),
        ),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: GeneralAppBar(title: 'Order Details', centerdTitle: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: kGreyTextColor,
                ),
                const SizedBox(height: 12),
                MyText(
                  text: 'Order Not Found',
                  size: 18,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                  paddingBottom: 8,
                ),
                MyText(
                  text:
                      'The requested order details could not be found or loaded.',
                  size: 14,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  textAlign: TextAlign.center,
                  paddingBottom: 20,
                ),
                SizedBox(
                  width: 130,
                  child: MyButton(
                    buttonText: 'Go Back',
                    height: 40,
                    onTap: () => Get.back(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final order = _order!;
    final shortId = order.id.length > 6
        ? order.id.substring(order.id.length - 6)
        : order.id;
    final steps = buildOrderSteps(order.status, order.events);
    final priceStr = '£${(order.totalPence / 100).toStringAsFixed(2)}';
    final nextCta = _ctaFor(order.status);

    return Scaffold(
      appBar: GeneralAppBar(
        title: 'Order #$shortId',
        centerdTitle: false,
        action: [
          if (order.offerId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: MyRippleEffect(
                  radius: 8,
                  onTap: () {
                    Get.to(
                      () => ChatRoomPage(
                        contextId: order.offerId,
                        type: ConversationType.offer,
                        title: 'Buyer Chat - Order #$shortId',
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kSecondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: kSecondaryColor,
                        ),
                        const SizedBox(width: 6),
                        MyText(
                          text: 'Chat',
                          size: 13,
                          weight: FontWeight.w600,
                          color: kSecondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            SupplierCard(
              child: Row(
                children: [
                  CommonImageView(
                    imagePath: Assets.imagesProfileImage,
                    height: 44,
                    width: 44,
                    radius: 100,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: 'Customer Order',
                          size: 16,
                          weight: FontWeight.w700,
                          color: kBlackColor,
                        ),
                        MyText(
                          paddingTop: 2,
                          text: order.request.partName,
                          size: 13,
                          weight: FontWeight.w500,
                          color: kGreyTextColor,
                        ),
                      ],
                    ),
                  ),
                  SupplierStatusBadge(
                    label: order.status?.label ?? 'Placed',
                    color: order.status == OrderStatus.delivered
                        ? const Color(0xff34C759)
                        : order.status == OrderStatus.cancelled
                            ? kRedColor
                            : kSecondaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OrderProgressCard(steps: steps),
            const SizedBox(height: 14),
            SupplierCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SupplierPriceRow(label: 'Item Subtotal', value: priceStr),
                  const SizedBox(height: 12),
                  const SupplierPriceRow(
                    label: 'Delivery & Handling',
                    value: 'Included',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: kGreyTextColor),
                  ),
                  SupplierPriceRow(
                    label: 'Total Order Value',
                    value: priceStr,
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SupplierCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SupplierDetailItem(
                          label: 'Delivery Option',
                          value: order.deliveryMethod?.label ?? 'Standard Delivery',
                        ),
                      ),
                      Expanded(
                        child: SupplierDetailItem(
                          label: 'Deliver to',
                          value: order.deliveryLocation != null &&
                                  order.deliveryLocation!.isNotEmpty
                              ? order.deliveryLocation!
                              : 'United Kingdom',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: nextCta != null
          ? NavButton(
              buttonText: _isAdvancing ? 'Updating...' : nextCta,
              onTap: _advance,
            )
          : null,
    );
  }
}

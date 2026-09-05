import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/domain/order_steps.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/order_progress_card.dart';
import 'package:flutter/material.dart';

/// One accepted order, from the supplier's side.
///
/// The buyer's OrderStatusPage is read-only and ends in 'Give Review'. Only the
/// supplier can advance an order, so this screen swaps that CTA for the
/// OrderStatusEvent write — without it a buyer's tracker can never leave PLACED.
class SupplierOrderDetailPage extends StatefulWidget {
  const SupplierOrderDetailPage({super.key});

  @override
  State<SupplierOrderDetailPage> createState() =>
      _SupplierOrderDetailPageState();
}

class _SupplierOrderDetailPageState extends State<SupplierOrderDetailPage> {
  /// How far the order has been advanced: an index into
  /// [OrderStatus.forwardPath]. The real implementation posts an
  /// OrderStatusEvent and re-reads the order.
  int _stage = 1;

  static const List<String> _ctas = [
    'Mark as Preparing',
    'Mark as Out for Delivery',
    'Mark as Delivered',
  ];

  /// The one stepper in the app now builds these. With no `events[]` behind the
  /// local counter every earlier row comes back `skipped` rather than `done`,
  /// which is the honest rendering of "no OrderStatusEvent was ever read".
  List<OrderStep> get _steps =>
      buildOrderSteps(OrderStatus.forwardPath[_stage], const []);

  // PHASE 2: a local counter with no PATCH behind it. Wiring
  // `PATCH /v1/orders/:id/status` on the supplier side is phase-2 work; until
  // then this advances nothing the buyer's tracker can see.
  void _advance() {
    if (_stage < 3) setState(() => _stage++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Order #4818', centerdTitle: false),
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
                          text: 'Michael Chen',
                          size: 16,
                          weight: FontWeight.w700,
                          color: kBlackColor,
                        ),
                        MyText(
                          paddingTop: 2,
                          text: 'Ford Mustang GT - Brake Discs',
                          size: 12,
                          weight: FontWeight.w400,
                          color: kGreyTextColor,
                        ),
                      ],
                    ),
                  ),
                  SupplierStatusBadge(label: OrderStatus.forwardPath[_stage].label),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OrderProgressCard(steps: _steps),
            const SizedBox(height: 14),
            SupplierCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SupplierPriceRow(label: 'Part Price', value: '240.00'),
                  SizedBox(height: 12),
                  SupplierPriceRow(label: 'Delivery Fee', value: '20.00'),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: kGreyTextColor),
                  ),
                  SupplierPriceRow(
                    label: 'You receive',
                    value: '260.00',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SupplierCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Expanded(
                        child: SupplierDetailItem(
                          label: 'Delivery',
                          value: 'Courier - 1 day',
                        ),
                      ),
                      Expanded(
                        child: SupplierDetailItem(
                          label: 'Deliver to',
                          value: 'London, N1',
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
      bottomNavigationBar: _stage < 3
          ? NavButton(buttonText: _ctas[_stage], onTap: _advance)
          : null,
    );
  }
}

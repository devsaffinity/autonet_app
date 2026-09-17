import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/controller/supplier/supplier_create_offer_controller.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 1 — the Offer price cluster: pricePence, quantity, condition, warrantyMonths.
class SupplierOfferPricingStep extends StatefulWidget {
  final VoidCallback onNext;
  final SupplierCreateOfferController? controller;

  const SupplierOfferPricingStep({
    super.key,
    required this.onNext,
    this.controller,
  });

  @override
  State<SupplierOfferPricingStep> createState() =>
      _SupplierOfferPricingStepState();
}

class _SupplierOfferPricingStepState extends State<SupplierOfferPricingStep> {
  static const List<String> _conditions = [
    'Brand New',
    'Used',
    'Either',
  ];

  late final Set<String> _condition;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    if (c != null) {
      _condition = {c.condition.value.label};
    } else {
      _condition = {'Brand New'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text:
                      'Price the part the buyer asked for. Everything here shows on the offer card they compare.',
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),
                MyTextField(
                  controller: c?.priceController,
                  labelText: 'Price (£)',
                  hintText: 'e.g. 320.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                MyTextField(
                  controller: c?.quantityController,
                  labelText: 'Quantity available',
                  hintText: 'e.g. 1',
                  keyboardType: TextInputType.number,
                ),
                MyText(
                  text: 'Condition',
                  size: 16,
                  weight: FontWeight.w600,
                  paddingBottom: 8,
                ),
                SupplierChoiceChips(
                  options: _conditions,
                  selected: _condition,
                  onToggle: (label) => setState(() {
                    _condition
                      ..clear()
                      ..add(label);
                    if (c != null) {
                      if (label == 'Brand New') {
                        c.condition.value = PartCondition.newPart;
                      } else if (label == 'Used') {
                        c.condition.value = PartCondition.used;
                      } else {
                        c.condition.value = PartCondition.either;
                      }
                    }
                  }),
                ),
                const SizedBox(height: 18),
                MyTextField(
                  controller: c?.warrantyController,
                  labelText: 'Warranty (months)',
                  hintText: 'e.g. 12',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SupplierBottomButton(label: 'Next', onTap: widget.onNext),
      ],
    );
  }
}

/// Step 2 — deliveryOption, deliveryTimeDays, stockStatus and notes.
class SupplierOfferDeliveryStep extends StatefulWidget {
  final VoidCallback onNext;
  final SupplierCreateOfferController? controller;

  const SupplierOfferDeliveryStep({
    super.key,
    required this.onNext,
    this.controller,
  });

  @override
  State<SupplierOfferDeliveryStep> createState() =>
      _SupplierOfferDeliveryStepState();
}

class _SupplierOfferDeliveryStepState extends State<SupplierOfferDeliveryStep> {
  late final Set<String> _delivery;
  late final Set<String> _stock;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    if (c != null) {
      _delivery = {c.deliveryOption.value.label};
      _stock = {c.stockStatus.value.label};
    } else {
      _delivery = {'Standard delivery'};
      _stock = {'In stock'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text:
                      'How does the buyer get the part, and how soon? Delivery is the second thing they sort offers on after price.',
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),
                MyText(
                  text: 'Delivery option',
                  size: 16,
                  weight: FontWeight.w600,
                  paddingBottom: 8,
                ),
                SupplierChoiceChips(
                  options: const [
                    'Standard delivery',
                    'Express',
                    'Local pickup',
                  ],
                  selected: _delivery,
                  onToggle: (d) => setState(() {
                    _delivery
                      ..clear()
                      ..add(d);
                    if (c != null) {
                      if (d == 'Express') {
                        c.deliveryOption.value = DeliveryOption.express;
                      } else if (d == 'Local pickup') {
                        c.deliveryOption.value = DeliveryOption.localPickup;
                      } else {
                        c.deliveryOption.value = DeliveryOption.standard;
                      }
                    }
                  }),
                ),
                const SizedBox(height: 18),
                MyTextField(
                  controller: c?.deliveryTimeController,
                  labelText: 'Delivery time (days)',
                  hintText: 'e.g. 2',
                  keyboardType: TextInputType.number,
                ),
                MyText(
                  text: 'Stock status',
                  size: 16,
                  weight: FontWeight.w600,
                  paddingBottom: 8,
                ),
                SupplierChoiceChips(
                  options: const ['In stock', 'Low stock', 'On order'],
                  selected: _stock,
                  onToggle: (s) => setState(() {
                    _stock
                      ..clear()
                      ..add(s);
                    if (c != null) {
                      if (s == 'Low stock') {
                        c.stockStatus.value = StockStatus.lowStock;
                      } else if (s == 'On order') {
                        c.stockStatus.value = StockStatus.onOrder;
                      } else {
                        c.stockStatus.value = StockStatus.inStock;
                      }
                    }
                  }),
                ),
                const SizedBox(height: 18),
                MyTextField(
                  controller: c?.notesController,
                  labelText: 'Notes for buyer (optional)',
                  hintText: 'e.g. Original OEM part, includes mounting brackets',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SupplierBottomButton(label: 'Next', onTap: widget.onNext),
      ],
    );
  }
}

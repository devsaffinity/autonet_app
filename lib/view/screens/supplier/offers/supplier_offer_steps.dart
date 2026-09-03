import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Step 1 — the Offer price cluster: pricePence, quantity, condition,
/// warrantyMonths.
class SupplierOfferPricingStep extends StatefulWidget {
  final VoidCallback onNext;
  const SupplierOfferPricingStep({super.key, required this.onNext});

  @override
  State<SupplierOfferPricingStep> createState() =>
      _SupplierOfferPricingStepState();
}

class _SupplierOfferPricingStepState extends State<SupplierOfferPricingStep> {
  static const List<String> _conditions = [
    'Brand New',
    'Refurbished',
    'Used - Good',
    'Used - Fair',
  ];
  final Set<String> _condition = {'Brand New'};

  @override
  Widget build(BuildContext context) {
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
                  labelText: 'Price',
                  hintText: 'e.g. 320.00',
                  keyboardType: TextInputType.number,
                ),
                MyTextField(
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
                  onToggle: (c) => setState(() {
                    _condition
                      ..clear()
                      ..add(c);
                  }),
                ),
                const SizedBox(height: 18),
                MyTextField(
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

/// Step 2 — deliveryOption, deliveryTimeDays, stockStatus and photos.
class SupplierOfferDeliveryStep extends StatefulWidget {
  final VoidCallback onNext;
  const SupplierOfferDeliveryStep({super.key, required this.onNext});

  @override
  State<SupplierOfferDeliveryStep> createState() =>
      _SupplierOfferDeliveryStepState();
}

class _SupplierOfferDeliveryStepState extends State<SupplierOfferDeliveryStep> {
  final Set<String> _delivery = {'Courier'};
  final Set<String> _stock = {'In Stock'};

  @override
  Widget build(BuildContext context) {
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
                  options: const ['Courier', 'Collection', 'Own Driver'],
                  selected: _delivery,
                  onToggle: (d) => setState(() {
                    _delivery
                      ..clear()
                      ..add(d);
                  }),
                ),
                const SizedBox(height: 18),
                MyTextField(
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
                  options: const ['In Stock', 'Order In', 'Low Stock'],
                  selected: _stock,
                  onToggle: (s) => setState(() {
                    _stock
                      ..clear()
                      ..add(s);
                  }),
                ),
                const SizedBox(height: 18),
                SupplierCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SupplierTitleRow(
                        icon: Assets.imagesPartBox,
                        title: 'Part photos',
                        subTitle: 'Up to 4 images of the actual unit',
                      ),
                      const SizedBox(height: 15),
                      CommonImageView(svgPath: Assets.imagesUploadDocButton),
                    ],
                  ),
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

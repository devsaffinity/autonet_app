import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/controller/supplier/supplier_create_offer_controller.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Step 3 — review and submit quote.
class SupplierOfferReviewStep extends StatelessWidget {
  final String ctaLabel;
  final VoidCallback onSubmit;
  final SupplierCreateOfferController? controller;

  const SupplierOfferReviewStep({
    super.key,
    required this.ctaLabel,
    required this.onSubmit,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    final priceStr = c != null ? c.formattedPrice : '£320.00';
    final conditionStr = c != null ? c.condition.value.label : 'Brand New';
    final warrantyStr = c != null && c.warrantyController.text.isNotEmpty
        ? '${c.warrantyController.text} months'
        : '12 months';
    final deliveryStr = c != null
        ? '${c.deliveryOption.value.label} - ${c.deliveryTimeController.text.isNotEmpty ? c.deliveryTimeController.text : '2'} days'
        : 'Standard delivery - 2 days';
    final stockStr = c != null ? c.stockStatus.value.label : 'In stock';
    final notesStr = c?.notesController.text;

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
                      'This is exactly what the buyer sees next to every other offer on their request.',
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),
                SupplierCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SupplierPriceRow(label: 'Part Price', value: priceStr),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: kGreyTextColor),
                      ),
                      SupplierPriceRow(
                        label: 'Total Quote',
                        value: priceStr,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SupplierCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Condition',
                              value: conditionStr,
                            ),
                          ),
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Warranty',
                              value: warrantyStr,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Delivery',
                              value: deliveryStr,
                            ),
                          ),
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Stock',
                              value: stockStr,
                            ),
                          ),
                        ],
                      ),
                      if (notesStr != null && notesStr.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SupplierDetailItem(
                          label: 'Notes',
                          value: notesStr,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SupplierBottomButton(label: ctaLabel, onTap: onSubmit),
      ],
    );
  }
}

/// Success sheet shown once an offer is submitted or updated.
class OfferSentBSheet extends StatelessWidget {
  final String title;
  final VoidCallback onContinue;
  const OfferSentBSheet({
    super.key,
    required this.title,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return MyBSheet(
      btnText: 'Proceed',
      onTap: onContinue,
      body: Column(
        children: [
          CommonImageView(width: 150, imagePath: Assets.imagesRequestPartIcon),
          MyText(
            textAlign: TextAlign.center,
            paddingBottom: 20,
            paddingTop: 24,
            text: title,
            size: 20,
            weight: FontWeight.w700,
          ),
          MyText(
            paddingBottom: 24,
            textAlign: TextAlign.center,
            text:
                'The buyer can now compare your offer with other suppliers. You will be notified immediately when they accept or decide.',
            size: 16,
            weight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}

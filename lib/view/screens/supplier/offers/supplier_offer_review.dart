import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Step 3 — review, then the CTA the caller supplies ('Send Offer' on create,
/// 'Update Offer' when editing the one offer this supplier already has).
class SupplierOfferReviewStep extends StatelessWidget {
  final String ctaLabel;
  final VoidCallback onSubmit;
  const SupplierOfferReviewStep({
    super.key,
    required this.ctaLabel,
    required this.onSubmit,
  });

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
                    children: const [
                      SupplierPriceRow(label: 'Part Price', value: '320.00'),
                      SizedBox(height: 12),
                      SupplierPriceRow(label: 'Delivery Fee', value: '30.00'),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: kGreyTextColor),
                      ),
                      SupplierPriceRow(
                        label: 'Total Price',
                        value: '350.00',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SupplierCard(
                  child: Column(
                    children: const [
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Condition',
                              value: 'Brand New',
                            ),
                          ),
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Warranty',
                              value: '12 months',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Delivery',
                              value: 'Courier - 2 days',
                            ),
                          ),
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Stock',
                              value: 'In Stock',
                            ),
                          ),
                        ],
                      ),
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

/// Success sheet, the mirror of the buyer's RequestSendBSheet.
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
                'The buyer can now compare your offer. You will be notified as soon as they accept or reject it.',
            size: 16,
            weight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}

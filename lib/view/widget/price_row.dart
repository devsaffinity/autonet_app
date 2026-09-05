import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// One label/amount line. Replaces the byte-identical `_PriceRow` copies.
///
/// There is deliberately no 'Part Price + Delivery Fee = Total' block to build
/// this out of: no delivery-fee field exists on Offer or Order, and
/// `Order.totalPence` is copied verbatim from `Offer.pricePence`.
class PriceRow extends StatelessWidget {
  const PriceRow({
    super.key,
    required this.label,
    required this.pence,
    this.emphasised = false,
  });

  final String label;
  final int pence;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final size = emphasised ? AppTextScale.subtitle : AppTextScale.body;
    final weight = emphasised ? AppWeights.bold : AppWeights.regular;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText(text: label, size: size, weight: weight,
              color: emphasised ? kBlackColor : kGreyTextColor),
          MyText(text: formatPence(pence), size: size, weight: weight,
              color: kBlackColor),
        ],
      ),
    );
  }
}

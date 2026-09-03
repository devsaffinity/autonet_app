import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The WEEK / MONTH bar chart from TotalBalancePage, re-labelled for credit
/// spend. Same 100px bars, same kSecondaryColor highlight, same 180ms chips.
class SupplierCreditChart extends StatefulWidget {
  const SupplierCreditChart({super.key});

  @override
  State<SupplierCreditChart> createState() => _SupplierCreditChartState();
}

class _SupplierCreditChartState extends State<SupplierCreditChart> {
  int _chartTab = 0; // 0 = WEEK, 1 = MONTH

  static const List<Map<String, dynamic>> _bars = [
    {'day': 'MON', 'value': 0.30},
    {'day': 'TUE', 'value': 0.50},
    {'day': 'WED', 'value': 1.0, 'highlight': true},
    {'day': 'THU', 'value': 0.45},
    {'day': 'FRI', 'value': 0.35},
    {'day': 'SAT', 'value': 0.20},
    {'day': 'SUN', 'value': 0.10},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyling().myShadowDecoration(
        color: kPrimaryColor,
        borderColor: kTertiaryColor,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: 'Credit\nSpend',
                      size: 16,
                      weight: FontWeight.w800,
                      color: kBlackColor,
                    ),
                    MyText(
                      text: 'Unlocks against leads',
                      size: 11,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(2, (i) {
                  const labels = ['WEEK', 'MONTH'];
                  final isSelected = _chartTab == i;
                  return Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                    child: MyRippleEffect(
                      onTap: () => setState(() => _chartTab = i),
                      radius: 20,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? kSecondaryColor : kTertiaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: MyText(
                          text: labels[i],
                          size: 10,
                          weight: FontWeight.w700,
                          color: isSelected ? kWhiteColor : kGreyTextColor,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _bars.map((bar) {
                final isHighlight = bar['highlight'] == true;
                final double val = bar['value'] as double;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isHighlight)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kSecondaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: MyText(
                              text: '14',
                              size: 9,
                              weight: FontWeight.w700,
                              color: kWhiteColor,
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: 100 * val,
                          decoration: BoxDecoration(
                            color: isHighlight
                                ? kSecondaryColor
                                : kSecondaryColor.withValues(alpha: 0.15),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        MyText(
                          text: bar['day'] as String,
                          size: 9,
                          weight: FontWeight.w600,
                          color: isHighlight ? kSecondaryColor : kGreyTextColor,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

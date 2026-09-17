import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The WEEK / MONTH bar chart dynamically computed from the supplier's credit ledger spend.
class SupplierCreditChart extends StatefulWidget {
  final List<Map<String, dynamic>> ledger;

  const SupplierCreditChart({super.key, this.ledger = const []});

  @override
  State<SupplierCreditChart> createState() => _SupplierCreditChartState();
}

class _SupplierCreditChartState extends State<SupplierCreditChart> {
  int _chartTab = 0; // 0 = WEEK, 1 = MONTH

  List<Map<String, dynamic>> _computeWeekBars() {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final counts = <String, int>{for (final d in days) d: 0};

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStartMidnight =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    for (final item in widget.ledger) {
      final atVal = item['at'];
      final delta = (item['delta'] as num?)?.toInt() ?? 0;
      if (delta < 0 && atVal != null) {
        final dt = atVal is DateTime
            ? atVal
            : (atVal is String ? DateTime.tryParse(atVal) : null);
        if (dt != null && dt.isAfter(weekStartMidnight)) {
          final dayIdx = dt.weekday - 1;
          if (dayIdx >= 0 && dayIdx < days.length) {
            counts[days[dayIdx]] = (counts[days[dayIdx]] ?? 0) + delta.abs();
          }
        }
      }
    }

    int maxCount = 0;
    for (final c in counts.values) {
      if (c > maxCount) maxCount = c;
    }

    return days.map((day) {
      final count = counts[day] ?? 0;
      final val = maxCount > 0 ? (count / maxCount) : 0.0;
      final isMax = maxCount > 0 && count == maxCount;
      return {
        'day': day,
        'value': val,
        'count': count,
        'highlight': isMax,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _computeMonthBars() {
    const weeks = ['WK 1', 'WK 2', 'WK 3', 'WK 4'];
    final counts = <String, int>{for (final w in weeks) w: 0};
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    for (final item in widget.ledger) {
      final atVal = item['at'];
      final delta = (item['delta'] as num?)?.toInt() ?? 0;
      if (delta < 0 && atVal != null) {
        final dt = atVal is DateTime
            ? atVal
            : (atVal is String ? DateTime.tryParse(atVal) : null);
        if (dt != null && dt.isAfter(monthStart)) {
          final weekIdx = ((dt.day - 1) ~/ 7).clamp(0, 3);
          counts[weeks[weekIdx]] = (counts[weeks[weekIdx]] ?? 0) + delta.abs();
        }
      }
    }

    int maxCount = 0;
    for (final c in counts.values) {
      if (c > maxCount) maxCount = c;
    }

    return weeks.map((w) {
      final count = counts[w] ?? 0;
      final val = maxCount > 0 ? (count / maxCount) : 0.0;
      final isMax = maxCount > 0 && count == maxCount;
      return {
        'day': w,
        'value': val,
        'count': count,
        'highlight': isMax,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bars = _chartTab == 0 ? _computeWeekBars() : _computeMonthBars();

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
            height: 146,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.map((bar) {
                final isHighlight = bar['highlight'] == true;
                final double val = (bar['value'] as num).toDouble();
                final int count = bar['count'] as int? ?? 0;
                final barHeight =
                    val > 0 ? (78 * val).clamp(8.0, 78.0) : 6.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isHighlight && count > 0)
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
                              text: '$count',
                              size: 9,
                              weight: FontWeight.w700,
                              color: kWhiteColor,
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isHighlight
                                ? kSecondaryColor
                                : (val > 0
                                    ? kSecondaryColor.withValues(alpha: 0.15)
                                    : kTertiaryColor),
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

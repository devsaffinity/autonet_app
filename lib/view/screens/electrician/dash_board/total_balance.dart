import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/electrician/review/review.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usage:
//   body: TotalBalancePage()
// ─────────────────────────────────────────────────────────────────────────────

class TotalBalancePage extends StatefulWidget {
  const TotalBalancePage({super.key});

  @override
  State<TotalBalancePage> createState() => _TotalBalancePageState();
}

class _TotalBalancePageState extends State<TotalBalancePage> {
  // ── Chart tab ──────────────────────────────────────────────────────────────
  int _chartTab = 0; // 0 = WEEK, 1 = MONTH

  // ── Bar chart data ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _weekBars = [
    {'day': 'MON', 'value': 0.35},
    {'day': 'TUE', 'value': 0.55},
    {'day': 'WED', 'value': 1.0, 'highlight': true},
    {'day': 'THU', 'value': 0.40},
    {'day': 'FRI', 'value': 0.28},
    {'day': 'SAT', 'value': 0.20},
    {'day': 'SUN', 'value': 0.15},
  ];

  // ── Income streams ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _incomeStreams = [
    {
      'label': 'Repair Services',
      'amount': '\$2,840',
      'icon': Icons.build_circle_outlined,
      'color': kSecondaryColor,
    },
    {
      'label': 'Installations',
      'amount': '\$1,250',
      'icon': Icons.electrical_services_outlined,
      'color': kSecondaryColor,
    },
    {
      'label': 'Consultations',
      'amount': '\$490',
      'icon': Icons.chat_bubble_outline_rounded,
      'color': kSecondaryColor,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyBackButton(),
              // ── Total Balance header ───────────────────────────────────────
              _buildBalanceHeader(),
              const SizedBox(height: 20),

              // ── Stat cards ─────────────────────────────────────────────────
              _buildStatCard(
                label: 'JOBS COMPLETED',
                value: '124',
                icon: Icons.check_circle_outline_rounded,
                iconColor: kSecondaryColor,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                label: 'AVG. TICKET',
                value: '\$145',
                icon: Icons.receipt_long_outlined,
                iconColor: kSecondaryColor,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                label: 'ACTIVE LEADS',
                value: '12',
                icon: Icons.bolt_rounded,
                iconColor: kSecondaryColor,
              ),
              const SizedBox(height: 28),

              // ── Earnings Performance chart ─────────────────────────────────
              _buildEarningsChart(),
              const SizedBox(height: 24),

              // ── Monthly Income Streams ─────────────────────────────────────
              _buildIncomeStreams(),
              const SizedBox(height: 20),

              // ── Growth Opportunity ────────────────────────────────────────
              _buildGrowthOpportunity(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Balance Header ─────────────────────────────────────────────────────────
  Widget _buildBalanceHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'CURRENT LIQUIDITY',
          size: 11,
          weight: FontWeight.w700,
          color: kGreyTextColor,
          paddingBottom: 4,
        ),
        MyText(
          text: 'Total Balance:\n\$4,580',
          size: 32,
          weight: FontWeight.w800,
          color: kBlackColor,
        ),
      ],
    );
  }

  // ── Stat Card ──────────────────────────────────────────────────────────────
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: AppStyling().myShadowDecoration(
        color: kPrimaryColor,
        borderColor: kTertiaryColor,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text: label,
                size: 12,
                weight: FontWeight.w700,
                color: kGreyTextColor,
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: kLightOrangeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MyText(
            text: value,
            size: 30,
            weight: FontWeight.w800,
            color: kBlackColor,
          ),
        ],
      ),
    );
  }

  // ── Earnings Performance Chart ─────────────────────────────────────────────
  Widget _buildEarningsChart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: AppStyling().myShadowDecoration(
        color: kPrimaryColor,
        borderColor: kTertiaryColor,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + tabs
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: 'Earnings\nPerformance',
                      size: 16,
                      weight: FontWeight.w800,
                      color: kBlackColor,
                    ),
                    MyText(
                      text: 'Weekly growth trajectory',
                      size: 11,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // WEEK / MONTH chips
              Row(
                children: List.generate(2, (i) {
                  final labels = ['WEEK', 'MONTH'];
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

          // Bar chart
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weekBars.map((bar) {
                final isHighlight = bar['highlight'] == true;
                final double val = bar['value'] as double;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tooltip on highlighted bar
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
                              text: '\$841',
                              size: 9,
                              weight: FontWeight.w700,
                              color: kWhiteColor,
                            ),
                          ),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: 100 * val,
                          decoration: BoxDecoration(
                            color: isHighlight
                                ? kSecondaryColor
                                : kSecondaryColor.withOpacity(0.15),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Day label
                        MyText(
                          text: bar['day'],
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

  // ── Monthly Income Streams ─────────────────────────────────────────────────
  Widget _buildIncomeStreams() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: AppStyling().myDecoration(
        color: kLightBlueColor,
        borderColor: kTertiaryColor,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'Monthly Income Streams',
            size: 15,
            weight: FontWeight.w800,
            color: kBlackColor,
            paddingBottom: 16,
          ),
          ..._incomeStreams.map((s) => _buildIncomeRow(s)),
        ],
      ),
    );
  }

  Widget _buildIncomeRow(Map<String, dynamic> s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kLightOrangeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              s['icon'] as IconData,
              size: 16,
              color: s['color'] as Color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MyText(
              text: s['label'],
              size: 14,
              weight: FontWeight.w500,
              color: kBlackColor,
            ),
          ),
          MyText(
            text: s['amount'],
            size: 15,
            weight: FontWeight.w700,
            color: kBlackColor,
          ),
        ],
      ),
    );
  }

  // ── Growth Opportunity ─────────────────────────────────────────────────────
  Widget _buildGrowthOpportunity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kLightBlueColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Decorative bg icon
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.trending_up_rounded,
              size: 64,
              color: const Color(0xff4A6CF7).withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Growth Opportunity',
                size: 15,
                weight: FontWeight.w800,
                color: kBlackColor,
                paddingBottom: 6,
              ),
              MyText(
                text:
                    'Upsell to increase your average ticket by 22% this month.',
                size: 13,
                weight: FontWeight.w400,
                color: kGreyTextColor,
                paddingBottom: 16,
              ),
              MyButton(
                buttonText: 'View Recommendations',
                onTap: () {
                  Get.to(() => ElectricianReviewPage());
                },
                backgroundColor: kSecondaryColor,
                fontColor: kWhiteColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 44,
                radius: 100,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

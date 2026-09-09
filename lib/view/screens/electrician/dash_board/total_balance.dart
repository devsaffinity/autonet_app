import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/electrician/provider_dashboard_controller.dart';
import 'package:autonect/data/models/provider_dashboard.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// What the provider has earned.
///
/// NOT A BALANCE, and the copy on this screen is load-bearing. The buyer pays
/// the provider directly; Autonect holds no money, takes no commission and has
/// no payout rail. Every figure is a record of work completed, so nothing here
/// says 'balance', 'available' or 'withdraw' — a provider reading it that way
/// would be waiting on money that is never coming.
class TotalBalancePage extends StatefulWidget {
  const TotalBalancePage({super.key});

  @override
  State<TotalBalancePage> createState() => _TotalBalancePageState();
}

class _TotalBalancePageState extends State<TotalBalancePage> {
  final ProviderDashboardController c = ProviderDashboardController.ensure();

  @override
  void initState() {
    super.initState();
    c.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Every Rx is read HERE, in the Obx closure — StateView.builder runs
        // in its own build, outside the tracking zone, and a read down there
        // subscribes to nothing. GetX throws, and release paints it grey.
        child: Obx(() {
          final state = c.state.value;
          final tab = c.chartTab.value;

          return StateView<ProviderDashboard>(
            state: state,
            onRetry: c.load,
            builder: (_, d) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MyBackButton(),
                  _header(d),
                  const SizedBox(height: 20),

                  _statCard(
                    label: 'JOBS COMPLETED',
                    value: '${d.completedCount}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _statCard(
                    label: 'AVERAGE JOB',
                    // Null, not zero, when nothing priced has completed:
                    // '£0.00' is a claim about the work.
                    value: d.averageJobPence == null
                        ? '—'
                        : formatPence(d.averageJobPence!),
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 12),
                  _statCard(
                    label: 'AWAITING YOUR REPLY',
                    value: '${d.pendingCount}',
                    icon: Icons.bolt_rounded,
                  ),
                  const SizedBox(height: 28),

                  _chart(d, tab),
                  const SizedBox(height: 24),

                  if (d.byServiceType.isNotEmpty) ...[
                    _byService(d),
                    const SizedBox(height: 20),
                  ],

                  if (d.unpricedCompletedCount > 0) _unpricedNotice(d),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _header(ProviderDashboard d) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MyText(
        // 'CURRENT LIQUIDITY' promised a pot of money. This is a record of
        // work done, and nothing is held on the provider's behalf.
        text: 'WORK COMPLETED',
        size: 11,
        weight: FontWeight.w700,
        color: kGreyTextColor,
        paddingBottom: 4,
      ),
      MyText(
        text: formatPence(d.workCompletedPence),
        size: 32,
        weight: FontWeight.w800,
        color: kBlackColor,
        paddingBottom: 4,
      ),
      MyText(
        text: d.thisMonthPence > 0
            ? '${formatPence(d.thisMonthPence)} this month · paid to you '
                  'directly by each customer'
            : 'Paid to you directly by each customer',
        size: 12,
        weight: FontWeight.w400,
        color: kGreyTextColor,
      ),
    ],
  );

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) => Container(
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
              child: Icon(icon, size: 16, color: kSecondaryColor),
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

  Widget _chart(ProviderDashboard d, int tab) {
    final series = c.seriesFor(d);
    final peak = c.peakPence(d);

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
                      text: 'Earnings\nPerformance',
                      size: 16,
                      weight: FontWeight.w800,
                      color: kBlackColor,
                    ),
                    MyText(
                      text: tab == 0
                          ? 'The last seven days'
                          : 'The last six months',
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
                  final isSelected = tab == i;
                  return Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                    child: MyRippleEffect(
                      onTap: () => c.selectChartTab(i),
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
              children: series.map((point) {
                // The tallest bar is labelled, and ONLY when something was
                // actually earned — normalising an empty week against its own
                // maximum would draw seven full bars out of nothing.
                final isPeak = peak > 0 && point.totalPence == peak;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isPeak)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kSecondaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: MyText(
                              text: formatPence(point.totalPence),
                              size: 8,
                              weight: FontWeight.w700,
                              color: kWhiteColor,
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: 100 * c.barHeightFor(d, point),
                          decoration: BoxDecoration(
                            color: isPeak
                                ? kSecondaryColor
                                : kSecondaryColor.withValues(alpha: 0.15),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        MyText(
                          text: _pointLabel(point, tab),
                          size: 9,
                          weight: FontWeight.w600,
                          color: isPeak ? kSecondaryColor : kGreyTextColor,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (peak == 0)
            MyText(
              text: 'No completed work in this period yet.',
              size: 12,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              paddingTop: 12,
            ),
        ],
      ),
    );
  }

  /// 'MON' for a day bucket, 'SEP' for a month one. The server sends
  /// `YYYY-MM-DD` and `YYYY-MM`; parsing rather than formatting server-side
  /// keeps the wire a plain date and the wording a client concern.
  String _pointLabel(EarningsPoint point, int tab) {
    final parts = point.label.split('-').map(int.tryParse).toList();
    if (parts.length < 2 || parts[0] == null || parts[1] == null) return '';
    if (tab == 1) return kMonthNames[parts[1]! - 1].substring(0, 3).toUpperCase();
    if (parts.length < 3 || parts[2] == null) return '';
    return weekdayAbbrev(DateTime(parts[0]!, parts[1]!, parts[2]!).weekday);
  }

  Widget _byService(ProviderDashboard d) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    decoration: AppStyling().myDecoration(
      color: kPrimaryColor,
      borderColor: kTertiaryColor,
      radius: 14,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Where it came from',
          size: 15,
          weight: FontWeight.w800,
          color: kBlackColor,
          paddingBottom: 12,
        ),
        ...d.byServiceType.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: kLightOrangeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.build_circle_outlined,
                    size: 18,
                    color: kSecondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: s.serviceType!.label,
                        size: 14,
                        weight: FontWeight.w700,
                        color: kBlackColor,
                      ),
                      MyText(
                        text:
                            '${s.completedCount} '
                            '${s.completedCount == 1 ? 'job' : 'jobs'}',
                        size: 12,
                        weight: FontWeight.w400,
                        color: kGreyTextColor,
                      ),
                    ],
                  ),
                ),
                MyText(
                  text: formatPence(s.totalPence),
                  size: 15,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  /// A total that quietly omits work is worse than one that explains the gap.
  Widget _unpricedNotice(ProviderDashboard d) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kLightBlueColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Not counted above',
          size: 15,
          weight: FontWeight.w800,
          color: kBlackColor,
          paddingBottom: 6,
        ),
        MyText(
          text:
              '${d.unpricedCompletedCount} completed '
              '${d.unpricedCompletedCount == 1 ? 'job has' : 'jobs have'} no '
              'price recorded. Add one from the booking and it will be '
              'included here.',
          size: 13,
          weight: FontWeight.w400,
          color: kGreyTextColor,
        ),
      ],
    ),
  );
}

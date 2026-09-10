import 'package:autonect/controller/electrician/provider_dashboard_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/provider_dashboard.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/view/screens/electrician/dash_board/total_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// MOUNTING THE REAL SCREEN — see providers_list_mount_test.dart for why every
/// screen needs one of these.
///
/// This screen also carries a product rule that is pure copy: Autonect holds
/// no money and takes no commission, so the word 'balance' must not appear.
/// The assertion below is the only thing stopping it coming back.
ProviderDashboard _dashboard({
  int workPence = 125000,
  int? averagePence = 25000,
  int unpriced = 0,
  List<int> week = const [0, 5000, 120000, 0, 0, 0, 0],
}) => ProviderDashboard.fromJson({
  'completedCount': 5,
  'upcomingCount': 2,
  'pendingCount': 3,
  'workCompletedPence': workPence,
  'thisMonthPence': 40000,
  'averageJobPence': averagePence,
  'unpricedCompletedCount': unpriced,
  'byServiceType': [
    {'serviceType': 'DIAGNOSTIC', 'completedCount': 2, 'totalPence': 12000},
  ],
  'last7Days': [
    for (var i = 0; i < week.length; i++)
      {'date': '2026-05-0${i + 1}', 'totalPence': week[i]},
  ],
  'last6Months': [
    {'month': '2026-04', 'totalPence': 5000},
    {'month': '2026-05', 'totalPence': 9000},
  ],
});

Future<void> _pump(
  WidgetTester tester, {
  required ApiResult<ProviderDashboard> result,
}) async {
  final repo = FakeBookingsRepository()..dashboardResult = result;
  Get.put<BookingsRepository>(repo);
  Get.put(
    ProviderDashboardController(
      repo,
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    ),
  );
  await tester.pumpWidget(const GetMaterialApp(home: TotalBalancePage()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  testWidgets('builds and shows the real total in pounds', (tester) async {
    await _pump(tester, result: Ok(_dashboard()));

    expect(tester.takeException(), isNull);
    expect(find.text('£1,250.00'), findsOneWidget);
    expect(find.text('WORK COMPLETED'), findsOneWidget);
  });

  testWidgets('never calls the figure a balance, and never uses dollars', (
    tester,
  ) async {
    await _pump(tester, result: Ok(_dashboard()));

    // Autonect holds no money and takes no commission. A provider reading
    // 'balance' would be waiting on a payout that does not exist.
    expect(find.textContaining('Balance'), findsNothing);
    expect(find.textContaining('balance'), findsNothing);
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('an empty period says so instead of drawing full bars', (
    tester,
  ) async {
    await _pump(
      tester,
      result: Ok(
        _dashboard(workPence: 0, averagePence: null, week: const [0, 0, 0, 0, 0, 0, 0]),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('No completed work in this period yet.'), findsOneWidget);
    // No average to report, rather than a £0.00 that reads as a valuation.
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('explains completed work it could not count', (tester) async {
    await _pump(tester, result: Ok(_dashboard(unpriced: 2)));

    expect(tester.takeException(), isNull);
    expect(find.text('Not counted above'), findsOneWidget);
    expect(find.textContaining('2 completed jobs have no price'), findsOneWidget);
  });

  testWidgets('switching to MONTH redraws from the other series', (
    tester,
  ) async {
    await _pump(tester, result: Ok(_dashboard()));

    await tester.tap(find.text('MONTH'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('The last six months'), findsOneWidget);
  });

  testWidgets('a failed load renders the failure, not zeroes', (tester) async {
    await _pump(tester, result: const Err(ApiError.network()));

    expect(tester.takeException(), isNull);
    // Zeroes would read as 'you have earned nothing', which is a different
    // claim from 'we could not load this'.
    expect(find.text('WORK COMPLETED'), findsNothing);
  });
}

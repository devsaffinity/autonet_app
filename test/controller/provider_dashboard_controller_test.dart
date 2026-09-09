import 'package:autonect/controller/electrician/provider_dashboard_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/provider_dashboard.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// Provider earnings.
///
/// RECORDED WORK, NOT A BALANCE — nothing here is payable, and the two states
/// that could mislead are pinned: an average over no priced work, and a chart
/// with nothing in it.
ProviderDashboard _dashboard({
  int completed = 0,
  int workPence = 0,
  int? averagePence,
  int unpriced = 0,
  List<int> week = const [0, 0, 0, 0, 0, 0, 0],
}) => ProviderDashboard.fromJson({
  'completedCount': completed,
  'upcomingCount': 2,
  'pendingCount': 3,
  'workCompletedPence': workPence,
  'thisMonthPence': 0,
  'averageJobPence': averagePence,
  'unpricedCompletedCount': unpriced,
  'byServiceType': [
    {'serviceType': 'DIAGNOSTIC', 'completedCount': 2, 'totalPence': 12000},
    {'serviceType': 'NOT_A_REAL_SERVICE', 'completedCount': 9, 'totalPence': 999},
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

ProviderDashboardController _controller(FakeBookingsRepository repo) =>
    ProviderDashboardController(
      repo,
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    );

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  test('an empty chart scales to zero rather than to itself', () async {
    final repo = FakeBookingsRepository()..dashboardResult = Ok(_dashboard());
    final c = _controller(repo);
    await c.load();
    final d = (c.state.value as Data<ProviderDashboard>).value;

    // Normalising an empty week against its own maximum draws seven
    // full-height bars out of nothing — the most flattering possible lie.
    expect(c.peakPence(d), 0);
    for (final point in d.last7Days) {
      expect(c.barHeightFor(d, point), 0);
    }
  });

  test('bars are scaled against the tallest, not against the total', () async {
    final repo = FakeBookingsRepository()
      ..dashboardResult = Ok(
        _dashboard(week: const [0, 5000, 10000, 0, 2500, 0, 0]),
      );
    final c = _controller(repo);
    await c.load();
    final d = (c.state.value as Data<ProviderDashboard>).value;

    expect(c.peakPence(d), 10000);
    expect(c.barHeightFor(d, d.last7Days[2]), 1.0);
    expect(c.barHeightFor(d, d.last7Days[1]), 0.5);
    expect(c.barHeightFor(d, d.last7Days[4]), 0.25);
  });

  test('the tab switches which series the chart reads', () async {
    final repo = FakeBookingsRepository()..dashboardResult = Ok(_dashboard());
    final c = _controller(repo);
    await c.load();
    final d = (c.state.value as Data<ProviderDashboard>).value;

    expect(c.seriesFor(d), hasLength(7));
    c.selectChartTab(1);
    expect(c.seriesFor(d), hasLength(2));
  });

  test('an unknown service type is dropped, not rendered', () async {
    final repo = FakeBookingsRepository()..dashboardResult = Ok(_dashboard());
    final c = _controller(repo);
    await c.load();
    final d = (c.state.value as Data<ProviderDashboard>).value;

    // A new enum value shipping server-side must not put a broken row on an
    // old client.
    expect(d.byServiceType, hasLength(1));
    expect(d.byServiceType.single.serviceType, BookingServiceType.diagnostic);
  });

  test('no priced work leaves the average null, not zero', () async {
    final repo = FakeBookingsRepository()
      ..dashboardResult = Ok(_dashboard(completed: 1, unpriced: 1));
    final c = _controller(repo);
    await c.load();
    final d = (c.state.value as Data<ProviderDashboard>).value;

    // '£0.00 average' is a claim about the work; 'no completed jobs priced
    // yet' is the truth, and only null can carry it to the screen.
    expect(d.averageJobPence, isNull);
    expect(d.unpricedCompletedCount, 1);
  });

  test('a failed load leaves the screen on Failed', () async {
    final repo = FakeBookingsRepository()
      ..dashboardResult = const Err(ApiError.network());
    final c = _controller(repo);

    await c.load();

    expect(c.state.value, isA<Failed<ProviderDashboard>>());
  });
}

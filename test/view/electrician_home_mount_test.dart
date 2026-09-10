import 'package:autonect/controller/electrician/availability_controller.dart';
import 'package:autonect/controller/electrician/provider_bookings_controller.dart';
import 'package:autonect/controller/electrician/provider_dashboard_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/provider_dashboard.dart';
import 'package:autonect/data/models/provider_schedule.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/view/screens/electrician/home/home.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// MOUNTING THE ELECTRICIAN HOME.
///
/// It drives FOUR Obx closures off THREE controllers, which is exactly the
/// shape that shipped a grey Services screen: an Rx read from inside a
/// `ListView.itemBuilder` subscribes to nothing, GetX throws, and release
/// paints it as a blank rectangle. Only pumping the widget can catch that.
///
/// It also carries the rule that nothing on this screen may be invented. The
/// assertions below pin the figures that used to be hardcoded — '4 Bookings',
/// '20% increase from yesterday', '$1,240', '75% of goal' and three named
/// customers who did not exist.
Map<String, dynamic> _bookingJson({
  required String id,
  String? buyerName = 'Priya Raman',
  int? quotedPence = 8500,
}) => {
  'id': id,
  'buyerId': 'b1',
  'electricianId': 'e1',
  'scheduledAt': '2026-05-14T09:00:00.000Z',
  'createdAt': '2026-05-01T09:00:00.000Z',
  'serviceType': 'DIAGNOSTIC',
  'status': 'CONFIRMED',
  'region': 'LONDON',
  'regNumber': 'AB12 CDE',
  'quotedPence': quotedPence,
  if (buyerName != null) 'buyer': {'id': 'b1', 'name': buyerName},
};

Map<String, dynamic> _dashboardJson({
  int upcoming = 2,
  int pending = 1,
  int weekPence = 15000,
}) => {
  'completedCount': 4,
  'upcomingCount': upcoming,
  'pendingCount': pending,
  'workCompletedPence': 120000,
  'thisMonthPence': 40000,
  'averageJobPence': 30000,
  'unpricedCompletedCount': 0,
  'byServiceType': const [],
  'last7Days': [
    {'date': '2026-05-08', 'totalPence': weekPence},
    {'date': '2026-05-09', 'totalPence': 0},
  ],
  'last6Months': const [
    {'month': '2026-05', 'totalPence': 9000},
  ],
};

Future<FakeBookingsRepository> _pump(
  WidgetTester tester, {
  List<Map<String, dynamic>> bookings = const [],
  Map<String, dynamic>? dashboard,
  List<String> workingBandsToday = const ['MORNING'],
}) async {
  final rows = bookings.map(Booking.fromJson).toList();
  final repo = FakeBookingsRepository()
    ..dashboardResult = Ok(
      ProviderDashboard.fromJson(dashboard ?? _dashboardJson()),
    )
    ..listResult = Ok(
      Paged<Booking>(
        rows,
        PageMeta(
          page: 1,
          limit: 20,
          pageSize: rows.length,
          total: rows.length,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      ),
    )
    ..scheduleResult = Ok(
      ProviderSchedule.fromJson({
        'configured': true,
        'days': [
          {'weekday': DateTime.now().weekday, 'bands': workingBandsToday},
        ],
        'slotBands': const ['MORNING', 'AFTERNOON'],
      }),
    );

  Get.put<BookingsRepository>(repo);
  Get.put(
    ProviderDashboardController(
      repo,
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    ),
  );
  // Registered under the same tag `ensure()` uses for an unfiltered list.
  Get.put(
    ProviderBookingsController(
      repo,
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    ),
    tag: 'all',
  );
  Get.put(
    AvailabilityController(repo, toast: (_) {}, showBusy: () {}, hideBusy: () {}),
  );

  await tester.pumpWidget(const GetMaterialApp(home: ElectricianHomePage()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return repo;
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  testWidgets('builds without throwing and shows real figures', (tester) async {
    await _pump(tester, bookings: [_bookingJson(id: 'bk1')]);

    expect(tester.takeException(), isNull);
    expect(find.text('2 bookings'), findsOneWidget);
    expect(find.text('1 request needs your answer'), findsOneWidget);
    expect(find.text('£150.00'), findsOneWidget);
    expect(find.text('Priya Raman'), findsOneWidget);
  });

  testWidgets('none of the fabricated figures survive', (tester) async {
    await _pump(tester, bookings: [_bookingJson(id: 'bk1')]);

    expect(find.text('4 Bookings'), findsNothing);
    expect(find.text('20% increase from yesterday'), findsNothing);
    expect(find.text('75% of goal'), findsNothing);
    expect(find.textContaining(r'$'), findsNothing);
    // The three customers who never existed.
    expect(find.text('Sarah Johnson'), findsNothing);
    expect(find.text('Michael Chen'), findsNothing);
    expect(find.text('Elena Ross'), findsNothing);
  });

  testWidgets('says so when there are no bookings yet', (tester) async {
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('No bookings yet'), findsOneWidget);
  });

  testWidgets('an unquoted booking says so rather than showing a price', (
    tester,
  ) async {
    await _pump(
      tester,
      bookings: [_bookingJson(id: 'bk1', quotedPence: null)],
    );

    expect(tester.takeException(), isNull);
    // The row itself shows the time; the price only appears on the detail
    // screen, and it must not be invented on the way there.
    expect(find.text('Priya Raman'), findsOneWidget);
  });

  testWidgets('a buyer with no name falls back to a true label', (
    tester,
  ) async {
    await _pump(tester, bookings: [_bookingJson(id: 'bk1', buyerName: null)]);

    expect(tester.takeException(), isNull);
    expect(find.text('Customer'), findsOneWidget);
  });

  // Two tests rather than one that re-pumps: the second pumpWidget hands
  // Flutter the same const widget, so the element is reused and initState
  // never runs again — the screen would still be holding the first schedule.
  testWidgets('the status chip says so on a day they work', (tester) async {
    await _pump(tester, workingBandsToday: const ['MORNING']);
    expect(find.text('WORKING TODAY'), findsOneWidget);
  });

  testWidgets('the status chip reflects the schedule, not a local flag', (
    tester,
  ) async {
    await _pump(tester, workingBandsToday: const []);

    // The old chip was a local bool: a provider could tap it to OFFLINE and
    // still be booked all day. This one can only say what the schedule says.
    expect(find.text('OFF TODAY'), findsOneWidget);
    expect(find.text('ONLINE'), findsNothing);
  });
}

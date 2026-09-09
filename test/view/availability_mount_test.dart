import 'package:autonect/controller/electrician/availability_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/provider_schedule.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/view/screens/electrician/dash_board/electrician_avalibilty_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// MOUNTING THE REAL SCREEN.
///
/// The availability page reads six observables and hands a subtree to
/// `StateView.builder`, which runs in ITS build rather than inside the `Obx`
/// closure. An Rx read down there registers no dependency, GetX throws
/// 'improper use of a GetX', and a release build paints that as a plain grey
/// rectangle — no crash, no log. A controller test cannot see it, because it
/// never builds a widget. This does.
ProviderSchedule _schedule({
  required bool configured,
  Map<int, List<String>> days = const {},
}) => ProviderSchedule.fromJson({
  'configured': configured,
  'days': [
    for (var w = 1; w <= 7; w++) {'weekday': w, 'bands': days[w] ?? const []},
  ],
  'slotBands': const ['MORNING', 'MORNING', 'AFTERNOON', 'EVENING'],
});

Future<FakeBookingsRepository> _pump(
  WidgetTester tester, {
  required ApiResult<ProviderSchedule> schedule,
}) async {
  final repo = FakeBookingsRepository()..scheduleResult = schedule;
  Get.put<BookingsRepository>(repo);
  Get.put(
    AvailabilityController(repo, toast: (_) {}, showBusy: () {}, hideBusy: () {}),
  );
  await tester.pumpWidget(
    const GetMaterialApp(home: ElectricianAvailabilityPage()),
  );
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

  testWidgets('builds without throwing on a configured week', (tester) async {
    await _pump(
      tester,
      schedule: Ok(
        _schedule(configured: true, days: {
          1: ['MORNING'],
          2: ['MORNING', 'AFTERNOON'],
        }),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Availability'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(3));
  });

  testWidgets('an unset schedule says so instead of showing a closed week', (
    tester,
  ) async {
    await _pump(tester, schedule: Ok(_schedule(configured: false)));

    expect(tester.takeException(), isNull);
    // The single most important sentence on the screen: nothing set means
    // bookable in every slot, which is the opposite of what seven off-looking
    // days would suggest.
    expect(
      find.textContaining('buyers can book you in any slot'),
      findsOneWidget,
    );
  });

  testWidgets('a failed load renders the failure, not a blank week', (
    tester,
  ) async {
    await _pump(tester, schedule: const Err(ApiError.network()));

    expect(tester.takeException(), isNull);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('toggling a band enables Save and does not write through', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      schedule: Ok(_schedule(configured: true, days: {
        DateTime.now().weekday: ['MORNING'],
      })),
    );
    repo.calls.clear();

    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Save availability'), findsOneWidget);
    // The draft is local until Save — see the controller test for why.
    expect(repo.calls, isEmpty);
  });

  testWidgets('warns before saving a week that clears the schedule', (
    tester,
  ) async {
    // Today is the selected day and it works one band; switching that off
    // leaves every day empty, which the server stores as 'never set'.
    await _pump(
      tester,
      schedule: Ok(_schedule(configured: true, days: {
        DateTime.now().weekday: ['MORNING'],
      })),
    );

    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('clears your working hours'),
      findsOneWidget,
    );
  });
}

import 'package:autonect/controller/electrician/availability_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/provider_schedule.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// The provider's weekly working pattern.
///
/// THE LOAD-BEARING RULE, asserted first and hardest: a provider who has never
/// set a schedule is FULLY AVAILABLE, never fully closed. The server stores
/// that as no rows, and every provider on the platform predates the feature —
/// so a client that read absence as 'works nothing' would tell them the
/// opposite of what buyers can see.
ProviderSchedule _schedule({
  required bool configured,
  Map<int, List<String>> days = const {},
}) => ProviderSchedule.fromJson({
  'configured': configured,
  'days': [
    for (var w = 1; w <= 7; w++) {'weekday': w, 'bands': days[w] ?? const []},
  ],
  'slotBands': const [
    'MORNING',
    'MORNING',
    'MORNING',
    'AFTERNOON',
    'AFTERNOON',
    'EVENING',
  ],
});

AvailabilityController _controller(FakeBookingsRepository repo) =>
    AvailabilityController(
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

  test('an unset schedule reads as every band on, not none', () async {
    final repo = FakeBookingsRepository()
      ..scheduleResult = Ok(_schedule(configured: false));
    final c = _controller(repo);

    await c.load();

    expect(c.configured.value, isFalse);
    for (var weekday = 1; weekday <= 7; weekday++) {
      expect(
        c.draft[weekday],
        AvailabilityBand.values.toSet(),
        reason: 'weekday $weekday must default to fully available',
      );
    }
  });

  test('a configured schedule keeps the days it was given', () async {
    final repo = FakeBookingsRepository()
      ..scheduleResult = Ok(
        _schedule(
          configured: true,
          days: {
            1: ['MORNING'],
            3: ['AFTERNOON', 'EVENING'],
          },
        ),
      );
    final c = _controller(repo);

    await c.load();

    expect(c.draft[1], {AvailabilityBand.morning});
    expect(c.draft[3], {AvailabilityBand.afternoon, AvailabilityBand.evening});
    // A weekday the server listed with no bands is a day they do not work —
    // NOT a day they never mentioned. Only `configured: false` means the
    // latter, and it is decided once, for the whole week.
    expect(c.draft[2], isEmpty);
  });

  test('toggling edits a draft and does not touch the network', () async {
    final repo = FakeBookingsRepository()
      ..scheduleResult = Ok(
        _schedule(configured: true, days: {
          2: ['MORNING'],
        }),
      );
    final c = _controller(repo);
    await c.load();
    repo.calls.clear();

    c.selectWeekday(2);
    c.toggle(AvailabilityBand.evening);

    expect(c.draft[2], {AvailabilityBand.morning, AvailabilityBand.evening});
    expect(c.dirty.value, isTrue);
    // A toggle that wrote through would race three whole-week replaces when a
    // provider switches three bands off, and the last to LAND would win.
    expect(repo.calls, isEmpty);
  });

  test('save sends the whole week and adopts what comes back', () async {
    final repo = FakeBookingsRepository()
      ..scheduleResult = Ok(
        _schedule(configured: true, days: {
          1: ['MORNING'],
        }),
      )
      ..setScheduleResult = Ok(
        _schedule(configured: true, days: {
          1: ['MORNING', 'AFTERNOON'],
        }),
      );
    final c = _controller(repo);
    await c.load();
    c.selectWeekday(1);
    c.toggle(AvailabilityBand.afternoon);
    repo.calls.clear();

    final ok = await c.save();

    expect(ok, isTrue);
    // Every weekday travels, not just the one that changed: an omitted day
    // means 'not working', so a partial send silently closes the rest.
    expect(repo.calls.single, contains('1=MORNING+AFTERNOON'));
    expect(repo.calls.single, contains('2='));
    expect(repo.calls.single, contains('7='));
    expect(c.dirty.value, isFalse);
    expect(c.draft[1], {AvailabilityBand.morning, AvailabilityBand.afternoon});
  });

  test('a failed save keeps the draft so the edit is not lost', () async {
    final repo = FakeBookingsRepository()
      ..scheduleResult = Ok(_schedule(configured: true, days: {1: ['MORNING']}))
      ..setScheduleResult = const Err(ApiError.network());
    final c = _controller(repo);
    await c.load();
    c.selectWeekday(1);
    c.toggle(AvailabilityBand.evening);

    final ok = await c.save();

    expect(ok, isFalse);
    // Still dirty, still holding what they typed — dropping it would make a
    // flaky connection cost them the whole week's edit.
    expect(c.dirty.value, isTrue);
    expect(c.draft[1], {AvailabilityBand.morning, AvailabilityBand.evening});
  });

  test('an all-off week is flagged as clearing, not as closing', () async {
    final repo = FakeBookingsRepository()
      ..scheduleResult = Ok(_schedule(configured: true, days: {1: ['MORNING']}));
    final c = _controller(repo);
    await c.load();

    expect(c.wouldClearSchedule, isFalse);
    c.selectWeekday(1);
    c.toggle(AvailabilityBand.morning);

    // Saving this stores no rows, and no rows is how the server records
    // 'never set' — so it comes back FULLY AVAILABLE. The provider has to be
    // told that before they save, or they will believe the week is blocked.
    expect(c.wouldClearSchedule, isTrue);
  });

  test('the day-off row turns a whole day off and back on', () async {
    final repo = FakeBookingsRepository()
      ..scheduleResult = Ok(
        _schedule(configured: true, days: {
          4: ['MORNING', 'EVENING'],
        }),
      );
    final c = _controller(repo);
    await c.load();
    c.selectWeekday(4);

    c.toggleDayOff();
    expect(c.draft[4], isEmpty);

    // Back on restores EVERY band rather than the two they had: the draft no
    // longer knows what they were, and guessing would be inventing a schedule.
    c.toggleDayOff();
    expect(c.draft[4], AvailabilityBand.values.toSet());
  });

  test('a failed load leaves the screen on Failed, not on empty toggles',
      () async {
    final repo = FakeBookingsRepository()
      ..scheduleResult = const Err(ApiError.malformed());
    final c = _controller(repo);

    await c.load();

    expect(c.state.value, isA<Failed<ProviderSchedule>>());
    // Not a week of switched-off days, which would read as a real schedule.
    expect(c.draft, isEmpty);
  });

  test('slot counts come from the server grid, not a local copy', () async {
    final repo = FakeBookingsRepository()
      ..scheduleResult = Ok(_schedule(configured: false));
    final c = _controller(repo);

    await c.load();

    expect(c.slotCounts[AvailabilityBand.morning], 3);
    expect(c.slotCounts[AvailabilityBand.afternoon], 2);
    expect(c.slotCounts[AvailabilityBand.evening], 1);
  });
}

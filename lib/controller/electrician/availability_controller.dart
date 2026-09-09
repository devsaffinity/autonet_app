import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/provider_schedule.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// The provider's weekly working pattern — `GET`/`PUT /v1/bookings/schedule`.
///
/// EDITS A LOCAL DRAFT, saved explicitly. A toggle that wrote straight through
/// would fire one request per tap, and a provider turning off three bands
/// would race three whole-week replaces against each other — the last to land
/// wins, and it is not necessarily the last one they tapped. The draft also
/// makes 'unsaved changes' something the screen can show rather than guess.
class AvailabilityController extends ApiController {
  AvailabilityController(
    this._repo, {
    super.toast,
    super.showBusy,
    super.hideBusy,
  });

  final BookingsRepository _repo;

  static const StateSlot _scheduleSlot = StateSlot('schedule');

  static AvailabilityController ensure() =>
      Get.isRegistered<AvailabilityController>()
      ? Get.find<AvailabilityController>()
      : Get.put(AvailabilityController(Get.find<BookingsRepository>()));

  final Rx<ViewState<ProviderSchedule>> state =
      Rx<ViewState<ProviderSchedule>>(const Loading());

  /// 1 = Monday .. 7 = Sunday, matching `DateTime.weekday` so a date from the
  /// strip maps to its row with no arithmetic.
  final RxInt selectedWeekday = DateTime.now().weekday.obs;

  /// The week being edited, held apart from [state] so Cancel is just
  /// discarding it. Every weekday 1..7 is present once loaded, so a lookup
  /// never has to distinguish 'absent' from 'works nothing'.
  final RxMap<int, Set<AvailabilityBand>> draft =
      <int, Set<AvailabilityBand>>{}.obs;

  /// Whether the loaded schedule was ever SET, as opposed to set to nothing.
  /// A provider who has never touched this is fully available, and the screen
  /// has to say so rather than showing seven closed days.
  final RxBool configured = false.obs;

  final RxBool dirty = false.obs;

  /// How many of the day's slots fall in each band — the count under a toggle.
  /// From the server's own grid, so it stays right if the grid changes.
  final RxMap<AvailabilityBand, int> slotCounts =
      <AvailabilityBand, int>{}.obs;

  /// The Monday-to-Sunday dates around today, for the strip. Derived rather
  /// than stored: the pattern is weekly, so the dates are only a way to point
  /// at a weekday in words the provider recognises.
  List<DateTime> get weekDates {
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    return List<DateTime>.generate(7, (i) => monday.add(Duration(days: i)));
  }

  Set<AvailabilityBand> get selectedBands =>
      draft[selectedWeekday.value] ?? <AvailabilityBand>{};

  bool isOn(AvailabilityBand band) => selectedBands.contains(band);

  /// True when the provider works no band at all on the selected day.
  bool get selectedDayIsOff => selectedBands.isEmpty;

  /// Whether they work at all TODAY.
  ///
  /// Reads today's weekday explicitly rather than [selectedBands]: that
  /// follows whatever day the availability screen last selected, so a caller
  /// elsewhere — the home screen's status chip — would silently start
  /// reporting the day the provider happened to tap last.
  ///
  /// False before the schedule has loaded. The chip it feeds says 'off today',
  /// which is the safer way round to be briefly wrong: it invites a look at
  /// the schedule, where 'working' would invite ignoring it.
  bool get worksToday =>
      (draft[DateTime.now().weekday] ?? const <AvailabilityBand>{}).isNotEmpty;

  Future<void> load() => runRead<ProviderSchedule>(
    _scheduleSlot,
    _repo.schedule,
    (r) {
      switch (r) {
        case Err(:final error):
          absorbSuperseded(error);
          state.value = Failed(error);
        case Ok(:final value):
          _adopt(value);
          state.value = Data(value);
      }
    },
  );

  /// Take the server's answer as the new baseline, discarding any draft.
  ///
  /// Called on load AND after a successful save, so what is on screen is
  /// always what the server last confirmed rather than what was typed at it.
  void _adopt(ProviderSchedule s) {
    configured.value = s.configured;
    draft.value = <int, Set<AvailabilityBand>>{
      for (var weekday = 1; weekday <= 7; weekday++)
        weekday: <AvailabilityBand>{...s.bandsOn(weekday)},
    };
    slotCounts.value = <AvailabilityBand, int>{
      for (final band in AvailabilityBand.values) band: s.slotCountFor(band),
    };
    dirty.value = false;
  }

  void toggle(AvailabilityBand band) {
    final bands = <AvailabilityBand>{...selectedBands};
    if (!bands.remove(band)) bands.add(band);
    _setDay(selectedWeekday.value, bands);
  }

  /// Turn the whole day off, or — if it is already off — back on.
  ///
  /// This is a WEEKLY pattern, so it is 'I do not work Mondays', not 'I am
  /// away on the 14th'. A one-off day away is a different model (a dated
  /// exception) and is not built; the screen says which of the two this is
  /// rather than implying the other.
  void toggleDayOff() => _setDay(
    selectedWeekday.value,
    selectedDayIsOff
        ? AvailabilityBand.values.toSet()
        : <AvailabilityBand>{},
  );

  void _setDay(int weekday, Set<AvailabilityBand> bands) {
    draft[weekday] = bands;
    // A Map's contents changing is not a new Map: assign through `draft[...]`
    // and then mark, so anything watching either one rebuilds.
    draft.refresh();
    dirty.value = true;
  }

  void selectWeekday(int weekday) => selectedWeekday.value = weekday;

  /// Whether saving this draft would clear the schedule entirely.
  ///
  /// The server records 'works nothing' as no rows, and no rows is also how it
  /// records 'never set' — so an all-off week comes back as FULLY AVAILABLE
  /// rather than fully closed. The screen must say that before the provider
  /// saves, or they will believe they have closed the week and be booked all
  /// of it.
  bool get wouldClearSchedule =>
      draft.values.every((bands) => bands.isEmpty);

  Future<bool> save() async {
    var saved = false;
    await runWrite<ProviderSchedule, void>(
      _scheduleSlot,
      () => _repo.setSchedule(draft),
      (r, claim) {
        switch (r) {
          case Err(:final error):
            absorb(error);
          case Ok(:final value):
            saved = true;
            // Publish through the claim: the load this write overtook must not
            // land afterwards and paint the pre-save week back on.
            claim.publish(() {
              _adopt(value);
              state.value = Data(value);
            });
        }
      },
    );
    if (saved) toast('Availability updated');
    return saved;
  }
}

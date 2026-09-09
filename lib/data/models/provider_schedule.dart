import 'package:autonect/data/models/request_enums.dart' show enumFromWire;

/// The half-days a provider works — `AvailabilityBand` on the wire.
///
/// A BAND rather than a pair of times: the bookable slots are a fixed grid the
/// product owns, and 'not Monday mornings' is a coarser, more stable statement
/// than enumerating instants. The grid can change without rewriting anybody's
/// schedule.
///
/// The ranges below are LABELS, not the rule. The server decides which slot
/// falls in which band (noon and 17:00 are the boundaries) and sends
/// `slotBands` back so the client never has to hold a second copy of that.
enum AvailabilityBand {
  morning('MORNING', 'Morning', '09:00 – 12:00'),
  afternoon('AFTERNOON', 'Afternoon', '12:00 – 17:00'),
  evening('EVENING', 'Evening', '17:00 – 21:00');

  const AvailabilityBand(this.wire, this.label, this.timeRange);

  final String wire;
  final String label;

  /// What the provider reads under the band's name.
  final String timeRange;

  static AvailabilityBand? fromWire(String? v) =>
      enumFromWire(values, v, (e) => e.wire);
}

/// One weekday of the pattern. [weekday] is 1 = Monday .. 7 = Sunday, matching
/// `DateTime.weekday` exactly, so a date maps to its row with no arithmetic.
class ScheduleDay {
  const ScheduleDay({required this.weekday, required this.bands});

  final int weekday;
  final Set<AvailabilityBand> bands;

  bool get worksNothing => bands.isEmpty;

  static ScheduleDay fromJson(Map<String, dynamic> j) => ScheduleDay(
    weekday: (j['weekday'] as num).toInt(),
    bands: ((j['bands'] as List?) ?? const [])
        .map((b) => AvailabilityBand.fromWire(b as String?))
        .whereType<AvailabilityBand>()
        .toSet(),
  );
}

/// A provider's whole week.
///
/// [configured] is the difference between 'works nothing' and 'has never set
/// one', which an empty [days] alone cannot say. NOT CONFIGURED MEANS FULLY
/// AVAILABLE — the server treats absence of rows that way, because every
/// provider predates the feature, and a client that rendered it as 'closed all
/// week' would tell them the opposite of what buyers can see.
class ProviderSchedule {
  const ProviderSchedule({
    required this.configured,
    required this.days,
    required this.slotBands,
  });

  final bool configured;
  final List<ScheduleDay> days;

  /// Which band each slot in the day's grid belongs to, in slot order. Sent by
  /// the server so the client renders the same division the server applies
  /// rather than hardcoding a copy that can drift.
  final List<AvailabilityBand> slotBands;

  /// The bands worked on [weekday], read the way the SERVER reads them: an
  /// unconfigured provider works everything.
  Set<AvailabilityBand> bandsOn(int weekday) {
    if (!configured) return AvailabilityBand.values.toSet();
    for (final day in days) {
      if (day.weekday == weekday) return day.bands;
    }
    return <AvailabilityBand>{};
  }

  /// How many of the grid's slots fall in [band] — the '2 slots' under a
  /// toggle. Derived from [slotBands] rather than counted here, so it stays
  /// right if the grid gains an evening slot.
  int slotCountFor(AvailabilityBand band) =>
      slotBands.where((b) => b == band).length;

  static ProviderSchedule fromJson(Map<String, dynamic> j) => ProviderSchedule(
    configured: j['configured'] as bool? ?? false,
    days: ((j['days'] as List?) ?? const [])
        .map((d) => ScheduleDay.fromJson((d as Map).cast<String, dynamic>()))
        .toList(),
    slotBands: ((j['slotBands'] as List?) ?? const [])
        .map((b) => AvailabilityBand.fromWire(b as String?))
        .whereType<AvailabilityBand>()
        .toList(),
  );
}

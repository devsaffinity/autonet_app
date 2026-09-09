import 'package:autonect/data/models/request_enums.dart' show enumFromWire;

/// The callouts a provider takes — `BookingServiceType` on the wire.
///
/// The labels are the DESIGN's words, not the enum's: the comp's tabs and
/// chips read 'Diagnostics' and 'ECU Tuning' where the schema says DIAGNOSTIC
/// and ECU_CODING. Keeping the mapping here means the wire value is what
/// travels and the human word is what renders, and neither has to be spelled
/// out again at a call site.
enum BookingServiceType {
  diagnostic('DIAGNOSTIC', 'Diagnostics', 'Fault finding and fault codes'),
  ecuCoding('ECU_CODING', 'ECU Tuning', 'Remapping, coding and key programming'),
  installation('INSTALLATION', 'Installation', 'Dashcams, alarms and retrofits'),
  repair('REPAIR', 'Repair', 'Wiring, looms and electrical repair'),
  inspection('INSPECTION', 'Inspection', 'Pre-purchase and condition checks');

  const BookingServiceType(this.wire, this.label, this.blurb);

  final String wire;

  /// What the buyer reads on a chip or a tab.
  final String label;

  /// The second line on the profile's Specializations tiles.
  final String blurb;

  static BookingServiceType? fromWire(String? v) =>
      enumFromWire(values, v, (e) => e.wire);
}

/// Where a booking is in its life — `BookingStatus` on the wire.
///
/// PENDING means the provider has not answered yet, which is why the buyer
/// can still cancel it; past IN_PROGRESS they have travelled and started, and
/// cancelling is a dispute rather than a state change.
enum BookingStatus {
  pending('PENDING', 'Awaiting confirmation'),
  confirmed('CONFIRMED', 'Confirmed'),
  inProgress('IN_PROGRESS', 'In progress'),
  completed('COMPLETED', 'Completed'),
  cancelled('CANCELLED', 'Cancelled');

  const BookingStatus(this.wire, this.label);

  final String wire;
  final String label;

  /// The two states the server accepts a cancellation from. Mirrored here so
  /// the UI can hide a button that would only earn a 409 — the server remains
  /// the authority, this just stops us offering a control that cannot work.
  bool get isCancellable => this == pending || this == confirmed;

  static BookingStatus? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

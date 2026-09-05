/// Wire enums for the part-request funnel, mirroring the Prisma enums in
/// autonect-backend/prisma/schema.prisma. This file imports nothing on purpose:
/// models, repositories, controllers and widgets all need it.
library;

/// The shared unknown-value policy for every enum below: null rather than a
/// throw, so a member added to a backend enum degrades to a null field on one
/// item instead of failing the decode of a whole list.
T? enumFromWire<T>(List<T> values, String? wire, String Function(T) wireOf) {
  if (wire == null) return null;
  for (final v in values) {
    if (wireOf(v) == wire) return v;
  }
  return null;
}

enum Region {
  london('LONDON', 'London'),
  southEast('SOUTH_EAST', 'South East'),
  southWest('SOUTH_WEST', 'South West'),
  eastOfEngland('EAST_OF_ENGLAND', 'East of England'),
  eastMidlands('EAST_MIDLANDS', 'East Midlands'),
  westMidlands('WEST_MIDLANDS', 'West Midlands'),
  northEast('NORTH_EAST', 'North East'),
  northWest('NORTH_WEST', 'North West'),
  yorkshire('YORKSHIRE', 'Yorkshire'),
  scotland('SCOTLAND', 'Scotland'),
  wales('WALES', 'Wales'),
  northernIreland('NORTHERN_IRELAND', 'Northern Ireland');

  const Region(this.wire, this.label);
  final String wire;
  final String label;

  static Region? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

/// Exactly three. There is no `REFURBISHED` on the wire.
enum PartCondition {
  newPart('NEW', 'New'),
  used('USED', 'Used'),
  either('EITHER', 'Either');

  const PartCondition(this.wire, this.label);
  final String wire;
  final String label;

  static PartCondition? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

/// There is no `NORMAL` on the wire; `STANDARD` is its value.
enum RequestUrgency {
  urgent('URGENT', 'Urgent'),
  standard('STANDARD', 'Standard'),
  low('LOW', 'Low');

  const RequestUrgency(this.wire, this.label);
  final String wire;
  final String label;

  static RequestUrgency? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

enum RequestStatus {
  open('OPEN', 'Open'),
  closed('CLOSED', 'Closed'),
  cancelled('CANCELLED', 'Cancelled');

  const RequestStatus(this.wire, this.label);
  final String wire;
  final String label;

  static RequestStatus? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

/// The verbs accepted by `PATCH /v1/requests/{id}` body `{action}`. A SEPARATE
/// TYPE from [RequestStatus], deliberately: the PATCH verbs and the statuses
/// they produce are different strings, so sending 'CLOSED' where 'CLOSE' is
/// expected is a 400. Two types make that unrepresentable, not merely unlikely.
enum CloseAction {
  close('CLOSE'),
  cancel('CANCEL');

  const CloseAction(this.wire);
  final String wire;

  static CloseAction? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

/// `POST /v1/vehicles/lookup` → `modelSource`.
enum ModelSource {
  provider('PROVIDER'),
  manualRequired('MANUAL_REQUIRED'),
  manual('MANUAL');

  const ModelSource(this.wire);
  final String wire;

  /// MANUAL_REQUIRED means the provider had no model, so the buyer must type one.
  bool get needsManualModel => this == ModelSource.manualRequired;

  static ModelSource? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

enum VehicleSource {
  dvla('DVLA'),
  manual('MANUAL'),
  thirdParty('THIRD_PARTY');

  const VehicleSource(this.wire);
  final String wire;

  static VehicleSource? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

/// Mirrors UPLOAD.IMAGE_MIME_TYPES / IMAGE_MAX_BYTES in the backend's
/// src/config/constants.ts; anything else 400s at `POST /v1/requests/image-url`.
const List<String> kImageMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
const int kMaxRequestImages = 5;
const int kMaxImageBytes = 5 * 1024 * 1024;

import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/request_enums.dart';

/// A vehicle row. Two shapes reach the app and this one type covers both:
/// the full row embedded in a request (REQUEST_INCLUDE's `vehicle: true`) and
/// the seven-column projection returned by `POST /v1/vehicles/lookup`
/// (vehicles.service.ts `toResponse`). [source] and [fetchedAt] are nullable
/// because the lookup projection drops them.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.regNumber,
    this.make,
    this.model,
    this.fuel,
    this.colour,
    this.year,
    this.source,
    this.fetchedAt,
  });

  final String id;

  /// Already normalised by the server (uppercase, whitespace stripped).
  final String regNumber;
  final String? make;
  final String? model;
  final String? fuel;
  final String? colour;
  final int? year;
  final VehicleSource? source;
  final DateTime? fetchedAt;

  factory Vehicle.fromJson(Map<String, dynamic> j) {
    final fetchedAt = j['fetchedAt'];
    return Vehicle(
      id: jsonString(j, 'id'),
      regNumber: jsonString(j, 'regNumber'),
      make: j['make'] as String?,
      model: j['model'] as String?,
      fuel: j['fuel'] as String?,
      colour: j['colour'] as String?,
      year: (j['year'] as num?)?.toInt(),
      source: VehicleSource.fromWire(j['source'] as String?),
      fetchedAt: fetchedAt is String ? DateTime.tryParse(fetchedAt) : null,
    );
  }
}

/// `POST /v1/vehicles/lookup` response.
class VehicleLookup {
  const VehicleLookup({required this.vehicle, this.modelSource});

  final Vehicle vehicle;
  final ModelSource? modelSource;

  /// Gate for the wizard's manual-model field. A null [modelSource] (an enum
  /// member the app does not know) still asks for the model when there is none,
  /// so the buyer is never blocked by an unrecognised wire value.
  bool get needsManualModel =>
      modelSource?.needsManualModel == true || vehicle.model == null;

  factory VehicleLookup.fromJson(Map<String, dynamic> j) => VehicleLookup(
    vehicle: Vehicle.fromJson((j['vehicle'] as Map).cast<String, dynamic>()),
    modelSource: ModelSource.fromWire(j['modelSource'] as String?),
  );
}

import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/vehicle.dart';

/// `POST /v1/vehicles/lookup` — the wizard's step-1 DVLA lookup.
abstract class VehiclesRepository {
  /// NEVER auto-retry a failure here. A negative lookup is not cached
  /// server-side, so every retry re-hits the DVLA provider for the same answer.
  ///
  /// A 404 is not a dead end for the buyer: `POST /v1/requests` does its own
  /// find-or-create on `regNumber` and needs no prior lookup.
  Future<ApiResult<VehicleLookup>> lookup(String regNumber);
}

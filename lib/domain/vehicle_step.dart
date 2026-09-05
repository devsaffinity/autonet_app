import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/models/vehicle.dart';
import 'package:autonect/domain/failure_copy.dart';

/// Step 1 of the new-request wizard: the reg-number lookup.
///
/// The field-enabled/required/can-advance answers are DERIVED from the step, so
/// there is no separate bool a controller can forget to flip back when the
/// buyer edits the registration and the lookup restarts.
sealed class VehicleStep {
  const VehicleStep();

  /// The manual model field is shown only when the server could not supply a
  /// model (MANUAL_REQUIRED) or the plate is unknown to it entirely.
  bool get modelFieldEnabled =>
      this is VehicleManualModel || this is VehicleUnknownReg;

  bool get modelFieldRequired => modelFieldEnabled;

  bool get canAdvance =>
      this is VehicleResolved ||
      this is VehicleManualModel ||
      this is VehicleUnknownReg;
}

final class VehicleIdle extends VehicleStep {
  const VehicleIdle();
}

final class VehicleLooking extends VehicleStep {
  const VehicleLooking();
}

/// The server knew the vehicle AND its model; nothing to type.
final class VehicleResolved extends VehicleStep {
  const VehicleResolved(this.lookup);

  final VehicleLookup lookup;
}

/// The server knew the vehicle but not its model.
final class VehicleManualModel extends VehicleStep {
  const VehicleManualModel(this.lookup);

  final VehicleLookup lookup;
}

/// A 404 from the lookup. The buyer may still proceed by typing the model.
final class VehicleUnknownReg extends VehicleStep {
  const VehicleUnknownReg(this.reg);

  final String reg;
}

final class VehicleFailed extends VehicleStep {
  const VehicleFailed(this.error);

  final ApiError error;

  String get message => userMessageFor(error);

  bool get retryable => isRetryable(error);
}

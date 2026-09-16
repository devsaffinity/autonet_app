import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/vehicle.dart';
import 'package:autonect/data/repositories/vehicles_repository.dart';
import 'package:autonect/domain/reg_number.dart';

class VehiclesApiRepository implements VehiclesRepository {
  /// [tokens] is accepted but not retained — see CatalogApiRepository for why
  /// every buyer repository takes the same pair.
  VehiclesApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  /// The reg is normalised BEFORE it goes out even though the server normalises
  /// it too: `isValidReg` judges the NORMALISED form, so sending the raw text
  /// would mean the string the client passed is not the string the server
  /// validates. Sending the same bytes it checked keeps the two verdicts
  /// identical.
  @override
  Future<ApiResult<VehicleLookup>> lookup(String regNumber) => _c.send(
    method: 'POST',
    path: '/v1/vehicles/lookup',
    body: {'regNumber': normaliseReg(regNumber)},
    decode: (d) => VehicleLookup.fromJson((d as Map).cast<String, dynamic>()),
  );

  @override
  Future<ApiResult<VehicleLookup>> saveCustom({
    required String regNumber,
    required String make,
    required String model,
    int? year,
    String? fuel,
    String? colour,
  }) => _c.send(
    method: 'POST',
    path: '/v1/vehicles/custom',
    body: {
      'regNumber': normaliseReg(regNumber),
      'make': make.trim(),
      'model': model.trim(),
      if (year != null) 'year': year,
      if (fuel != null && fuel.trim().isNotEmpty) 'fuel': fuel.trim(),
      if (colour != null && colour.trim().isNotEmpty) 'colour': colour.trim(),
    },
    decode: (d) => VehicleLookup.fromJson((d as Map).cast<String, dynamic>()),
  );
}

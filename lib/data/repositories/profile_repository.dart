import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/request_enums.dart';

/// The supplier's business registration payload.
///
/// A value object rather than seven positional arguments because the wizard
/// builds it across five screens, and a half-filled draft must be a thing the
/// controller can hold.
class SupplierBusinessDraft {
  const SupplierBusinessDraft({
    required this.businessName,
    required this.address,
    required this.regionsServed,
    required this.categoryIds,
    this.brands = const [],
    this.specialization,
  });

  final String businessName;
  final String address;
  final List<Region> regionsServed;
  final List<String> categoryIds;
  final List<String> brands;
  final String? specialization;

  /// The server requires at least one region and at least one category, so a
  /// draft failing this would 400. Checked before submit so the wizard can say
  /// which step is incomplete instead of surfacing a validation error.
  bool get isComplete =>
      businessName.trim().isNotEmpty &&
      address.trim().isNotEmpty &&
      regionsServed.isNotEmpty &&
      categoryIds.isNotEmpty;

  Map<String, Object?> toBody() => {
    'businessName': businessName.trim(),
    'address': address.trim(),
    'regionsServed': [for (final r in regionsServed) r.wire],
    'categoryIds': categoryIds,
    'brands': brands,
    // OMITTED when empty, never sent as ''. The server validates it as
    // `z.string().min(1).optional()`, so an empty string is a 400 where an
    // absent key is simply "not provided".
    if (specialization case final s? when s.trim().isNotEmpty)
      'specialization': s.trim(),
  };
}

/// `GET /v1/me` and `POST /v1/supplier/business`.
abstract class ProfileRepository {
  /// The fuller user record, and the ONLY source of a supplier's `approved`
  /// flag. Every gate on shell access must read this rather than local storage.
  Future<ApiResult<MeProfile>> me();

  /// Creates or replaces the supplier's business registration. Returns the
  /// refreshed profile, so a caller never needs a second read to learn the
  /// resulting KYC status.
  Future<ApiResult<MeProfile>> registerSupplierBusiness(
    SupplierBusinessDraft draft,
  );
}

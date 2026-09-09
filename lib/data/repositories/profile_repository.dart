import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/upload_ticket.dart';

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
    this.monetizationModel,
  });

  final String businessName;
  final String address;
  final List<Region> regionsServed;
  final List<String> categoryIds;
  final List<String> brands;
  final String? specialization;

  /// SUBSCRIPTION | CREDITS | COMMISSION. A stated preference: nothing bills
  /// on it, and the server treats it as optional.
  final String? monetizationModel;

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
    // Omitted when absent, so re-submitting without touching the plan step
    // cannot clear a choice already recorded. The `?` goes on the VALUE — on
    // the key it would mean "omit when the key is null", which is never.
    'monetizationModel': ?monetizationModel,
  };
}

/// A provider describing themselves — `POST /v1/electrician/registration`.
///
/// [fullName] is the ONLY field the server requires. Everything else is
/// optional and additive, so a provider who skips a step still registers
/// rather than being trapped on it.
///
/// [services] and [skills] are different things and the wizard collects both:
/// services are the callouts they TAKE (a fixed enum the buyer's filters use),
/// skills are what they DO in their own words. Conflating them made the
/// directory's chips unbuildable.
class ElectricianRegistrationDraft {
  const ElectricianRegistrationDraft({
    required this.fullName,
    this.phone,
    this.location,
    this.region,
    this.yearsExperience,
    this.brands = const [],
    this.services = const [],
    this.skills = const [],
    this.headline,
    this.bio,
    this.vehiclesServiced,
  });

  final String fullName;
  final String? phone;
  final String? location;
  final Region? region;
  final int? yearsExperience;
  final List<String> brands;
  final List<BookingServiceType> services;
  final List<String> skills;
  final String? headline;
  final String? bio;

  /// The profile card's vehicles-serviced counter. Nullable: a provider who
  /// has not told us leaves it out rather than claiming zero.
  final int? vehiclesServiced;

  bool get isComplete => fullName.trim().isNotEmpty;

  Map<String, Object?> toBody() => {
    'fullName': fullName.trim(),
    // Each optional field is validated as `min(1).optional()` server-side, so
    // an empty string is a 400 where an absent key is simply "not given".
    if (phone case final v? when v.trim().isNotEmpty) 'phone': v.trim(),
    if (location case final v? when v.trim().isNotEmpty) 'location': v.trim(),
    if (region case final r?) 'region': r.wire,
    if (yearsExperience case final y?) 'yearsExperience': y,
    // Scalar lists are always sent, including empty: the column cannot be
    // null, so "not sent" and "none selected" must land on the same value.
    'brands': brands,
    'services': [for (final s in services) s.wire],
    'skills': skills,
    if (headline case final v? when v.trim().isNotEmpty) 'headline': v.trim(),
    if (bio case final v? when v.trim().isNotEmpty) 'bio': v.trim(),
    if (vehiclesServiced case final n?) 'vehiclesServiced': n,
  };
}

/// `GET /v1/me`, `POST /v1/supplier/business` and
/// `POST /v1/electrician/registration`.
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

  /// Creates or replaces the ELECTRICIAN's registration. Returns the refreshed
  /// profile, whose `approved` flag decides where the wizard lands — a
  /// provider is NOT approved by registering, and the wizard must not assume
  /// otherwise.
  Future<ApiResult<MeProfile>> registerElectrician(
    ElectricianRegistrationDraft draft,
  );

  /// Step 1 of 3 for a new profile photo: a presigned PUT.
  ///
  /// The key is server-generated under `avatars/<userId>/`, and
  /// `PUT /v1/me/profile` refuses an avatarKey outside the caller's own prefix
  /// — so the client can neither choose the key nor point at someone else's.
  Future<ApiResult<UploadTicket>> createAvatarUploadTicket(String contentType);

  /// Step 3, after the bytes are in S3. Returns the refreshed profile, whose
  /// `avatarUrl` is a freshly presigned GET.
  Future<ApiResult<MeProfile>> setAvatar(String avatarKey);
}

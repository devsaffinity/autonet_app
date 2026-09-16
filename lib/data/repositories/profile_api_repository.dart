import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/electrician_service.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/repositories/profile_repository.dart';

class ProfileApiRepository implements ProfileRepository {
  /// [tokens] is accepted but not retained, so main.dart constructs every
  /// repository identically. Both routes are `requireAuth`, and ApiClient
  /// attaches the bearer itself.
  ProfileApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  /// Deliberately NOT memoised, unlike the category list.
  ///
  /// `approved` changes underneath the app the moment an admin acts on the
  /// review queue, and it is the flag that decides whether the supplier shell
  /// opens. A cached copy here would keep an approved supplier locked out for
  /// the life of the session, with no way to refresh short of a restart. The
  /// server already caches this response briefly.
  @override
  Future<ApiResult<MeProfile>> me() => _c.send(
    method: 'GET',
    path: '/v1/me',
    decode: _one,
  );

  @override
  Future<ApiResult<MeProfile>> registerSupplierBusiness(
    SupplierBusinessDraft draft,
  ) => _c.send(
    method: 'POST',
    // No /v1/profile prefix — the route is mounted at the top level.
    path: '/v1/supplier/business',
    body: draft.toBody(),
    // Returns the refreshed profile, so the caller learns the resulting
    // kycStatus without a second round trip.
    decode: _one,
  );

  @override
  Future<ApiResult<MeProfile>> registerElectrician(
    ElectricianRegistrationDraft draft,
  ) => _c.send(
    method: 'POST',
    path: '/v1/electrician/registration',
    body: draft.toBody(),
    // The refreshed profile, so the wizard reads the resulting `approved`
    // flag rather than assuming a successful registration means approved.
    decode: (d) => MeProfile.fromJson((d as Map).cast<String, dynamic>()),
  );

  @override
  Future<ApiResult<MeProfile>> updateElectricianTier(String tier) => _c.send(
    method: 'PATCH',
    path: '/v1/electrician/tier',
    body: {'tier': tier},
    decode: (d) => MeProfile.fromJson((d as Map).cast<String, dynamic>()),
  );

  @override
  Future<ApiResult<UploadTicket>> createAvatarUploadTicket(String contentType) =>
      _c.send(
        method: 'POST',
        path: '/v1/me/avatar-url',
        body: {'contentType': contentType},
        decode: (d) =>
            UploadTicket.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// PUT, not PATCH — the route is profileRouter.put('/me/profile').
  ///
  /// Sends ONLY avatarKey: every other field on updateProfileBodySchema is
  /// optional, and including a null name would blank the user's name.
  @override
  Future<ApiResult<MeProfile>> setAvatar(String avatarKey) => _c.send(
    method: 'PUT',
    path: '/v1/me/profile',
    body: {'avatarKey': avatarKey},
    decode: _one,
  );

  @override
  Future<ApiResult<MeProfile>> updateProfile({
    String? name,
    String? location,
    String? contact,
    String? avatarKey,
  }) => _c.send(
    method: 'PUT',
    path: '/v1/me/profile',
    body: {
      if (name case final v? when v.trim().isNotEmpty) 'name': v.trim(),
      if (location case final v? when v.trim().isNotEmpty) 'location': v.trim(),
      if (contact case final v? when v.trim().isNotEmpty) 'contact': v.trim(),
      if (avatarKey case final v? when v.trim().isNotEmpty) 'avatarKey': v.trim(),
    },
    decode: _one,
  );

  @override
  Future<ApiResult<List<ElectricianService>>> getElectricianServices() => _c.send(
    method: 'GET',
    path: '/v1/electrician/services',
    decode: (d) => [
      for (final item in (d as List))
        ElectricianService.fromJson((item as Map).cast<String, dynamic>()),
    ],
  );

  @override
  Future<ApiResult<ElectricianService>> createElectricianService({
    required String name,
    required String price,
    required String pricingType,
    String? description,
    BookingServiceType? serviceType,
  }) => _c.send(
    method: 'POST',
    path: '/v1/electrician/services',
    body: {
      'name': name.trim(),
      'price': price.trim(),
      'pricingType': pricingType,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (serviceType != null) 'serviceType': serviceType.wire,
    },
    decode: (d) =>
        ElectricianService.fromJson((d as Map).cast<String, dynamic>()),
  );

  @override
  Future<ApiResult<ElectricianService>> updateElectricianService({
    required String id,
    String? name,
    String? price,
    String? pricingType,
    String? description,
    BookingServiceType? serviceType,
    bool? isActive,
  }) => _c.send(
    method: 'PUT',
    path: '/v1/electrician/services/$id',
    body: {
      if (name != null) 'name': name.trim(),
      if (price != null) 'price': price.trim(),
      if (pricingType != null) 'pricingType': pricingType,
      if (description != null) 'description': description.trim(),
      if (serviceType != null) 'serviceType': serviceType.wire,
      if (isActive != null) 'isActive': isActive,
    },
    decode: (d) =>
        ElectricianService.fromJson((d as Map).cast<String, dynamic>()),
  );

  @override
  Future<ApiResult<void>> deleteElectricianService(String id) => _c.send(
    method: 'DELETE',
    path: '/v1/electrician/services/$id',
    decode: (_) {},
  );

  static MeProfile _one(Object? d) =>
      MeProfile.fromJson((d as Map).cast<String, dynamic>());
}

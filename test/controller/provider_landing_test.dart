import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_role.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:autonect/services/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where a supplier lands after signing in.
///
/// The bug these lock down: `landingRoute` read `providerOnboarded` from
/// SharedPreferences, and `_localTeardown` clears that on every sign-out — so a
/// supplier who had registered AND been approved was sent back through the
/// registration wizard on their next login, and RoleGuard redirected them there
/// again every time they tried to leave.

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.result);

  ApiResult<MeProfile> result;
  int calls = 0;

  @override
  Future<ApiResult<MeProfile>> me() async {
    calls++;
    return result;
  }

  @override
  Future<ApiResult<MeProfile>> registerSupplierBusiness(
    SupplierBusinessDraft draft,
  ) async => throw UnimplementedError();

  @override
  Future<ApiResult<MeProfile>> registerElectrician(
    ElectricianRegistrationDraft draft,
  ) async => me();

  // The avatar endpoints are not exercised here; the seam requires them.
  @override
  Future<ApiResult<UploadTicket>> createAvatarUploadTicket(String contentType) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<MeProfile>> setAvatar(String avatarKey) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<MeProfile>> updateProfile({
    String? name,
    String? location,
    String? contact,
    String? avatarKey,
  }) => throw UnimplementedError();
}

MeProfile _profile({Map<String, dynamic>? supplier}) => MeProfile.fromJson({
  'id': 'u1',
  'email': 's@example.com',
  'role': 'SUPPLIER',
  if (supplier != null) 'supplierProfile': supplier,
});

Map<String, dynamic> _supplier({bool approved = false}) => {
  'businessName': 'JIN Motors',
  'address': 'Jinnah Center',
  'regionsServed': const ['LONDON'],
  'brands': const <String>[],
  'categories': const <Map<String, dynamic>>[],
  'kycStatus': approved ? 'APPROVED' : 'SUBMITTED',
  'approved': approved,
};

void main() {
  late RoleController c;
  late _FakeProfileRepository repo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SessionStore.init();
    repo = _FakeProfileRepository(Ok(_profile()));
    Get.put<ProfileRepository>(repo);
    c = RoleController();
    c.onInit();
    c.selectRole(AppRole.supplier);
  });

  tearDown(Get.reset);

  test('an unregistered supplier goes to the wizard', () async {
    repo.result = Ok(_profile());
    await c.syncProviderAccess();
    expect(c.landingRoute, AppLinks.supplierOnboarding);
  });

  test('a REGISTERED but unapproved supplier goes to the waiting screen', () async {
    // Not the wizard: they already submitted, and re-registering would be busy
    // work. Not the shell either: every supplier route 403s until approval.
    repo.result = Ok(_profile(supplier: _supplier()));
    await c.syncProviderAccess();
    expect(c.landingRoute, AppLinks.supplierAwaitingApproval);
  });

  test('an APPROVED supplier goes straight to the shell', () async {
    // THE REPORTED BUG: this used to return supplierOnboarding, because the
    // local flag is false on a fresh install and after every sign-out.
    repo.result = Ok(_profile(supplier: _supplier(approved: true)));
    await c.syncProviderAccess();
    expect(c.landingRoute, AppLinks.supplierShell);
  });

  test('the server overrides a stale local flag in BOTH directions', () async {
    // Locally onboarded, server says no profile: back to the wizard.
    c.completeProviderOnboarding();
    repo.result = Ok(_profile());
    await c.syncProviderAccess();
    expect(c.landingRoute, AppLinks.supplierOnboarding);

    // And the reverse, which is the case the user hit.
    repo.result = Ok(_profile(supplier: _supplier(approved: true)));
    await c.syncProviderAccess();
    expect(c.landingRoute, AppLinks.supplierShell);
  });

  test('a failed read leaves the flags alone rather than stranding them',
      () async {
    repo.result = Ok(_profile(supplier: _supplier(approved: true)));
    await c.syncProviderAccess();
    expect(c.landingRoute, AppLinks.supplierShell);

    // Network drops on the next launch. Ejecting an approved supplier back to
    // the wizard because a request timed out would be worse than being stale.
    repo.result = const Err(ApiError.network('offline'));
    final ok = await c.syncProviderAccess();
    expect(ok, isFalse);
    expect(c.landingRoute, AppLinks.supplierShell);
  });

  test('a buyer never triggers the extra read', () async {
    c.selectRole(AppRole.buyer);
    expect(await c.syncProviderAccess(), isFalse);
    expect(repo.calls, 0, reason: 'only a supplier needs GET /v1/me to route');
    expect(c.landingRoute, AppLinks.homeFor(AppRole.buyer));
  });

  test('landingRoute is idempotent, which RoleGuard depends on', () async {
    // The guard redirects to landingRoute and stops when target == route. A
    // landingRoute that moved on re-entry would loop forever.
    repo.result = Ok(_profile(supplier: _supplier()));
    await c.syncProviderAccess();
    final first = c.landingRoute;
    expect(c.landingRoute, first);
    expect(c.landingRoute, first);
  });
}

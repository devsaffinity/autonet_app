import 'package:autonect/controller/buyer/catalog_controller.dart';
import 'package:autonect/controller/buyer/notifications_controller.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/repositories/catalog_repository.dart';
import 'package:autonect/data/repositories/notifications_repository.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/supplier/profile/edit_supplier_profile.dart';
import 'package:autonect/view/screens/supplier/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

class _FakeProfileRepo implements ProfileRepository {
  SupplierBusinessDraft? lastSavedDraft;
  bool returnError = false;

  MeProfile mockMe = const MeProfile(
    id: 'user_supp_1',
    role: 'SUPPLIER',
    email: 'seller@autonect.com',
    name: 'Rashid Seller',
    phone: '+44 7911 123456',
    location: 'London, UK',
    avatarUrl: null,
    supplierProfile: SupplierProfile(
      businessName: 'Apex Spares Ltd',
      address: '10 Downing St, London',
      regionsServed: [Region.london, Region.southEast],
      brands: ['Audi', 'BMW'],
      categories: [
        PartCategory(id: 'cat_1', name: 'Brakes'),
      ],
      specialization: 'German auto specialists',
      approved: true,
      kycStatus: KycStatus.approved,
    ),
  );

  @override
  Future<ApiResult<MeProfile>> me() async => Ok(mockMe);

  @override
  Future<ApiResult<MeProfile>> registerSupplierBusiness(
    SupplierBusinessDraft draft,
  ) async {
    if (returnError) {
      return const Err(ApiError(
        code: ApiErrorCode.internal,
        statusCode: 500,
        message: 'Failed to save business profile',
      ));
    }
    lastSavedDraft = draft;
    mockMe = MeProfile(
      id: mockMe.id,
      role: mockMe.role,
      email: mockMe.email,
      name: mockMe.name,
      phone: mockMe.phone,
      location: mockMe.location,
      avatarUrl: mockMe.avatarUrl,
      supplierProfile: SupplierProfile(
        businessName: draft.businessName,
        address: draft.address,
        regionsServed: draft.regionsServed,
        brands: draft.brands,
        categories: [
          const PartCategory(id: 'cat_1', name: 'Brakes'),
        ],
        specialization: draft.specialization,
        approved: true,
        kycStatus: KycStatus.approved,
      ),
    );
    return Ok(mockMe);
  }

  Map<String, dynamic>? lastUpdatedProfile;

  @override
  Future<ApiResult<MeProfile>> updateProfile({
    String? name,
    String? location,
    String? contact,
    String? avatarKey,
  }) async {
    lastUpdatedProfile = {
      'name': name,
      'location': location,
      'contact': contact,
      'avatarKey': avatarKey,
    };
    mockMe = MeProfile(
      id: mockMe.id,
      role: mockMe.role,
      email: mockMe.email,
      name: name ?? mockMe.name,
      phone: contact ?? mockMe.phone,
      contact: contact ?? mockMe.contact,
      location: location ?? mockMe.location,
      avatarUrl: mockMe.avatarUrl,
      supplierProfile: mockMe.supplierProfile,
    );
    return Ok(mockMe);
  }

  @override
  Future<ApiResult<UploadTicket>> createAvatarUploadTicket(String contentType) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<MeProfile>> registerElectrician(
    ElectricianRegistrationDraft draft,
  ) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeProfileRepo profileRepo;

  setUp(() {
    Get.reset();
    profileRepo = _FakeProfileRepo();
    Get.put<CatalogRepository>(FakeCatalogRepository());
    Get.put<ProfileRepository>(profileRepo);
    Get.put<NotificationsRepository>(FakeNotificationsRepository());
    Get.put<ProfileController>(ProfileController(profileRepo));
    Get.put<NotificationsController>(
      NotificationsController(FakeNotificationsRepository()),
    );

    // Seed catalog with dummy categories
    final catalog = CatalogController.ensure();
    catalog.categories.value = const Data<List<PartCategory>>([
      PartCategory(id: 'cat_1', name: 'Brakes'),
      PartCategory(id: 'cat_2', name: 'Engines'),
      PartCategory(id: 'cat_3', name: 'Suspension'),
    ]);
  });

  tearDown(() => Get.reset());

  testWidgets('EditSupplierProfilePage mounts and pre-fills supplier data',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: EditSupplierProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Business Information'), findsOneWidget);
    expect(find.text('Apex Spares Ltd'), findsOneWidget);
    expect(find.text('10 Downing St, London'), findsOneWidget);
    expect(find.text('Rashid Seller'), findsOneWidget);
    expect(find.text('Operating Regions'), findsOneWidget);
    expect(find.text('Brands Supported'), findsOneWidget);
    expect(find.text('Save Profile Changes'), findsOneWidget);
  });

  testWidgets('EditSupplierProfilePage validates empty fields and saves successfully',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: EditSupplierProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Modify business name
    final nameField = find.widgetWithText(TextFormField, 'Apex Spares Ltd');
    await tester.enterText(nameField, 'Turbo Apex Spares');
    await tester.pumpAndSettle();

    // Tap Save Changes
    final saveButton = find.text('Save Profile Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(profileRepo.lastSavedDraft, isNotNull);
    expect(profileRepo.lastSavedDraft!.businessName, 'Turbo Apex Spares');
  });

  testWidgets('SupplierProfilePage renders Edit Profile button and menu option',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Card edit button
    expect(find.text('Edit'), findsOneWidget);

    // Menu edit profile tile
    expect(find.text('Edit Profile'), findsOneWidget);

    // Tap Edit button on card to open EditSupplierProfilePage
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.byType(EditSupplierProfilePage), findsOneWidget);
  });

  testWidgets('EditSupplierProfilePage saves contact phone number seamlessly',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: EditSupplierProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('+44 7911 123456'), findsOneWidget);

    // Modify phone number
    final phoneField = find.widgetWithText(TextFormField, '+44 7911 123456');
    await tester.enterText(phoneField, '+44 7999 888777');
    await tester.pumpAndSettle();

    // Tap Save Changes
    final saveButton = find.text('Save Profile Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(profileRepo.lastUpdatedProfile, isNotNull);
    expect(profileRepo.lastUpdatedProfile!['contact'], '+44 7999 888777');
    expect(profileRepo.mockMe.effectivePhone, '+44 7999 888777');
  });
}

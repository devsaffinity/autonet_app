import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/auth_user.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/services/image_picker_service.dart';
import 'package:autonect/services/session_store.dart';
import 'package:autonect/view/screens/buyer/profile/buyer_profile_creation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_buyer_repositories.dart';

MeProfile _sampleBuyerProfile({
  String name = 'John Doe',
  String location = 'West Lincon Road, Virginia',
  String phone = '+44 75 9876643',
  String? avatarUrl,
}) => MeProfile.fromJson({
  'id': 'u_buyer_1',
  'email': 'john@example.com',
  'role': 'BUYER',
  'name': name,
  'location': location,
  'phone': phone,
  if (avatarUrl != null) 'avatarUrl': avatarUrl,
});

class _FakePicker implements ImagePickerService {
  PickedImage? imageToReturn;

  @override
  Future<List<PickedImage>> pick({required int remaining}) async {
    if (imageToReturn != null) return [imageToReturn!];
    return const [];
  }
}

Future<FakeProfileRepository> _pump(
  WidgetTester tester, {
  bool isInitialSetup = false,
  MeProfile? profile,
}) async {
  final repo = FakeProfileRepository()..meResult = Ok(profile ?? _sampleBuyerProfile());
  final tokenStore = InMemoryTokenStore(
    user: const AuthUser(
      id: 'u_buyer_1',
      email: 'john@example.com',
      role: 'BUYER',
      status: 'ACTIVE',
      name: 'John Doe',
    ),
  );

  Get.put<TokenStore>(tokenStore);
  Get.put<ProfileRepository>(repo);
  Get.put(RoleController());
  Get.put<ImagePickerService>(_FakePicker());
  Get.put(ProfileController(repo, toast: (_) {}));

  await tester.pumpWidget(
    GetMaterialApp(
      home: BuyerProfileCreationPage(isInitialSetup: isInitialSetup),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return repo;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStore.init();
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  testWidgets('mounts cleanly in initial setup mode with Next button and comp layout', (
    tester,
  ) async {
    await _pump(tester, isInitialSetup: true);

    expect(tester.takeException(), isNull);
    expect(find.text('Profile Creation'), findsOneWidget);
    expect(find.text('Profile Image'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Image must be under 2MB'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('mounts cleanly in edit mode with Save button and back action', (
    tester,
  ) async {
    await _pump(tester, isInitialSetup: false);

    expect(tester.takeException(), isNull);
    expect(find.text('Profile Creation'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('pre-fills fields from server profile', (tester) async {
    await _pump(
      tester,
      profile: _sampleBuyerProfile(
        name: 'Sarah Connor',
        location: 'London Bridge',
        phone: '+44 71 2345678',
      ),
    );

    expect(find.text('Sarah Connor'), findsOneWidget);
    expect(find.text('London Bridge'), findsOneWidget);
    expect(find.text('+44 71 2345678'), findsOneWidget);
  });

  testWidgets('submitting calls updateProfile on repository with edited values', (
    tester,
  ) async {
    final repo = await _pump(tester, isInitialSetup: false);

    // Edit the name field
    final nameField = find.widgetWithText(TextFormField, 'John Doe');
    await tester.enterText(nameField, 'Jane Doe');
    await tester.pump();

    // Tap Save button
    await tester.ensureVisible(find.text('Save'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdatedProfile, isNotNull);
    expect(repo.lastUpdatedProfile!['name'], 'Jane Doe');
    expect(repo.lastUpdatedProfile!['location'], 'West Lincon Road, Virginia');
    expect(repo.lastUpdatedProfile!['contact'], '+44 75 9876643');
  });

  testWidgets('empty name triggers validation error and blocks submission', (
    tester,
  ) async {
    final repo = await _pump(tester, isInitialSetup: false);

    final nameField = find.widgetWithText(TextFormField, 'John Doe');
    await tester.enterText(nameField, '');
    await tester.pump();

    await tester.ensureVisible(find.text('Save'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
    expect(repo.lastUpdatedProfile, isNull);
  });

  testWidgets(
      'pre-fills contact field from profile with contact key and allows updating contact',
      (tester) async {
    final repo = await _pump(
      tester,
      profile: MeProfile.fromJson({
        'id': 'u_buyer_1',
        'email': 'john@example.com',
        'role': 'BUYER',
        'name': 'Sarah Connor',
        'location': 'London Bridge',
        'contact': '+44 71 9998888',
      }),
    );

    expect(find.text('+44 71 9998888'), findsOneWidget);

    // Edit the contact field
    final contactField = find.widgetWithText(TextFormField, '+44 71 9998888');
    await tester.enterText(contactField, '+44 79 1122334');
    await tester.pump();

    // Tap Save button
    await tester.ensureVisible(find.text('Save'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdatedProfile, isNotNull);
    expect(repo.lastUpdatedProfile!['contact'], '+44 79 1122334');
  });
}

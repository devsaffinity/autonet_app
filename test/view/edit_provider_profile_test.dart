import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/controller/electrician/electrician_registration_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/view/screens/electrician/profile/edit_provider_profile.dart';
import 'package:flutter/material.dart';
import 'package:autonect/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// A provider editing their own profile.
///
/// THE RULE THIS PINS: the endpoint is an UPSERT, so a save REPLACES the row.
/// A form that did not pre-fill would silently clear every field it did not
/// show — which is why the load matters as much as the save.
MeProfile _me({
  String fullName = 'Jack Brennan',
  String? headline = 'ECU Specialist',
  String? bio = 'Fifteen years on German marques.',
  List<String> brands = const ['BMW', 'Audi'],
  List<String> services = const ['ECU_CODING'],
  int? years = 15,
  int? vehicles = 1240,
}) => MeProfile.fromJson({
  'id': 'u1',
  'email': 'jack@test.local',
  'role': 'ELECTRICIAN',
  'name': 'Jack B',
  'electricianProfile': {
    'fullName': fullName,
    'approved': true,
    'headline': headline,
    'bio': bio,
    'phone': '07700 900000',
    'location': 'Camden, London',
    'region': 'LONDON',
    'yearsExperience': years,
    'vehiclesServiced': vehicles,
    'brands': brands,
    'services': services,
    'skills': const ['Coding'],
  },
});

Future<FakeProfileRepository> _pump(
  WidgetTester tester, {
  MeProfile? profile,
}) async {
  final repo = FakeProfileRepository()..meResult = Ok(profile ?? _me());
  Get.put<ProfileRepository>(repo);
  // _save re-reads approval afterwards: an admin may have approved or revoked
  // while the provider was editing.
  Get.put(RoleController());
  Get.put(ProfileController(repo, toast: (_) {}));
  Get.put(
    ElectricianRegistrationController(
      repo,
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    ),
  );
  await tester.pumpWidget(
    const GetMaterialApp(home: EditProviderProfilePage()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return repo;
}

void main() {
  setUp(() async {
    // RoleController reads SessionStore on init, which needs prefs.
    SharedPreferences.setMockInitialValues({});
    await SessionStore.init();
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  testWidgets('builds without throwing and pre-fills from the server', (
    tester,
  ) async {
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Jack Brennan'), findsOneWidget);
    expect(find.text('ECU Specialist'), findsOneWidget);
    expect(find.text('Fifteen years on German marques.'), findsOneWidget);
  });

  testWidgets('a save re-sends everything, not just what was edited', (
    tester,
  ) async {
    final repo = await _pump(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'ECU Specialist'),
      'Senior Automotive Electrician',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Save profile'));
    await tester.pump();
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    final draft = repo.electricianDraft!;
    expect(draft.headline, 'Senior Automotive Electrician');
    // The UPSERT replaces the row, so everything it did NOT touch has to
    // travel too — otherwise editing a headline wipes the bio, the brands and
    // the services with it.
    expect(draft.bio, 'Fifteen years on German marques.');
    expect(draft.brands, ['BMW', 'Audi']);
    expect(draft.services, [BookingServiceType.ecuCoding]);
    expect(draft.yearsExperience, 15);
    expect(draft.vehiclesServiced, 1240);
    expect(draft.region, Region.london);
  });

  testWidgets('an empty vehicles field means unsaid, not zero', (tester) async {
    final repo = await _pump(tester, profile: _me(vehicles: null));

    await tester.ensureVisible(find.text('Save profile'));
    await tester.pump();
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    // '0 vehicles serviced' on a profile card is worse than no counter at all.
    expect(repo.electricianDraft!.vehiclesServiced, isNull);
    expect(repo.electricianDraft!.toBody().containsKey('vehiclesServiced'),
        isFalse);
  });

  testWidgets('Save is disabled until the profile has loaded', (tester) async {
    // Nothing pumped yet beyond the first frame: saving here would submit an
    // empty draft over a real profile.
    final repo = FakeProfileRepository()..meResult = Ok(_me());
    Get.put<ProfileRepository>(repo);
    Get.put(RoleController());
  // _save re-reads approval afterwards: an admin may have approved or revoked
  // while the provider was editing.
  Get.put(RoleController());
    Get.put(ProfileController(repo, toast: (_) {}));
    Get.put(
      ElectricianRegistrationController(
        repo,
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      ),
    );
    await tester.pumpWidget(
      const GetMaterialApp(home: EditProviderProfilePage()),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(repo.electricianDraft, isNull);
  });

  testWidgets('a profile with no headline yet still edits', (tester) async {
    await _pump(tester, profile: _me(headline: null, bio: null));

    expect(tester.takeException(), isNull);
    // The hint is what tells them what the field is FOR — it is the line the
    // buyer's directory card renders under their name.
    expect(find.text('e.g. ECU Specialist'), findsOneWidget);
  });
}

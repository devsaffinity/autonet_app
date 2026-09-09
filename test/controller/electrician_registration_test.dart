import 'package:autonect/controller/electrician/electrician_registration_controller.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// The electrician registration wizard.
///
/// THE REGRESSION THIS FILE EXISTS FOR: the wizard submitted NOTHING. Five
/// steps of state were discarded on finish and a local flag was set instead —
/// which, once the approval gate read server truth, sent the provider straight
/// back to the wizard on next launch. It looped.
ElectricianRegistrationController _controller(FakeProfileRepository repo) =>
    ElectricianRegistrationController(
      repo,
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    );

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  test('submits what the wizard collected', () async {
    final repo = FakeProfileRepository();
    final c = _controller(repo);
    c.fullName.value = 'Jack Brennan';
    c.phone.value = '07700 900000';
    c.location.value = 'Camden, London';
    c.region.value = Region.london;
    c.setExperience(12);
    c.toggleService(BookingServiceType.ecuCoding);
    c.toggleService(BookingServiceType.diagnostic);
    c.toggleBrand('BMW');
    c.toggleBrand('Audi');

    final profile = await c.submit();

    expect(profile, isNotNull);
    final draft = repo.electricianDraft!;
    expect(draft.fullName, 'Jack Brennan');
    expect(draft.region, Region.london);
    expect(draft.yearsExperience, 12);
    expect(draft.brands, ['BMW', 'Audi']);
    expect(draft.services, [
      BookingServiceType.ecuCoding,
      BookingServiceType.diagnostic,
    ]);
  });

  test('the body omits blanks rather than sending empty strings', () {
    final repo = FakeProfileRepository();
    final c = _controller(repo);
    c.fullName.value = '  Jack Brennan  ';
    c.phone.value = '   ';

    final body = c.draft.toBody();

    // Each optional field is `min(1).optional()` server-side, so '' is a 400
    // where an absent key is simply "not given".
    expect(body['fullName'], 'Jack Brennan');
    expect(body.containsKey('phone'), isFalse);
    expect(body.containsKey('location'), isFalse);
    // Scalar lists ALWAYS travel, including empty: the column cannot be null,
    // so "not sent" and "none selected" must land on the same value.
    expect(body['brands'], isEmpty);
    expect(body['services'], isEmpty);
  });

  test('refuses to submit without a name, and says which step', () async {
    final repo = FakeProfileRepository();
    final c = _controller(repo);
    c.toggleService(BookingServiceType.repair);

    final profile = await c.submit();

    expect(profile, isNull);
    expect(c.formError.value, 'Add your full name');
    // Nothing was sent — a 400 surfacing on the last step gives no clue which
    // of three screens to go back to.
    expect(repo.electricianDraft, isNull);
  });

  test('refuses to submit with no services picked', () async {
    final repo = FakeProfileRepository();
    final c = _controller(repo);
    c.fullName.value = 'Jack Brennan';

    expect(await c.submit(), isNull);
    expect(c.formError.value, 'Pick at least one service you offer');
  });

  test('services are seeded EMPTY, not pre-ticked', () {
    final c = _controller(FakeProfileRepository());
    // The step used to arrive with 'ECU Coding' already selected — a claim
    // about the provider they never made, and the field a buyer filters on.
    expect(c.services, isEmpty);
    expect(c.canSubmit, isFalse);
  });

  test('skills mirror the services rather than being invented', () {
    final c = _controller(FakeProfileRepository());
    c.fullName.value = 'Jack Brennan';
    c.toggleService(BookingServiceType.ecuCoding);

    expect(c.draft.skills, [BookingServiceType.ecuCoding.label]);
  });

  test('toggling a service off removes it', () {
    final c = _controller(FakeProfileRepository());
    c.toggleService(BookingServiceType.repair);
    c.toggleService(BookingServiceType.repair);
    expect(c.services, isEmpty);
  });
}

import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/vehicle.dart';
import 'package:autonect/domain/vehicle_step.dart';
import 'package:autonect/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_buyer_repositories.dart';
import '../fakes/fake_image_picker.dart';

Ok<VehicleLookup> _lookup({String? model, ModelSource? source}) => Ok(
  VehicleLookup(
    vehicle: Vehicle(id: 'veh_1', regNumber: 'LM19XYZ', make: 'BMW', model: model),
    modelSource: source,
  ),
);

final PartRequest _created = PartRequest.fromJson({
  'id': 'req_1',
  'buyerId': 'usr_buyer',
  'regNumber': 'LM19XYZ',
  'categoryId': 'cat_brakes',
  'partName': 'Front brake discs',
  'status': 'OPEN',
  'offerCount': 0,
  'createdAt': '2026-09-01T10:15:00.000Z',
  'updatedAt': '2026-09-01T10:15:00.000Z',
  'category': {'id': 'cat_brakes', 'name': 'Brakes'},
  'images': <Object?>[],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRequestsRepository requests;
  late FakeVehiclesRepository vehicles;
  late FakeImagePickerService picker;
  late NewRequestController c;

  /// Everything `validate()` demands, so a test that is about submit is not
  /// silently about validation instead.
  void fillValidDraft() {
    c.draft
      ..regNumber = 'LM19XYZ'
      ..categoryId = 'cat_brakes'
      ..region = Region.london
      ..partName = 'Front brake discs'
      ..condition = PartCondition.newPart
      ..urgency = RequestUrgency.standard;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStore.init();
    requests = FakeRequestsRepository();
    vehicles = FakeVehiclesRepository();
    picker = FakeImagePickerService();
    c = NewRequestController(
      requests: requests,
      vehicles: vehicles,
      uploader: FakeBlobUploader(),
      picker: picker,
      tokens: InMemoryTokenStore(),
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    );
  });

  // saveNow() cancels the debounce timer; the controller is never Get.put so
  // onClose() is never called for us.
  tearDown(() => c.saveNow());

  test('MANUAL_REQUIRED unlocks the model field and marks it required', () async {
    vehicles.result = _lookup(source: ModelSource.manualRequired);
    await c.lookupVehicle(' yb68 abc ');
    expect(c.vehicle.value, isA<VehicleManualModel>());
    expect(c.draft.manualModelRequired, isTrue);
    expect(c.vehicle.value.modelFieldEnabled, isTrue);
    expect(c.vehicle.value.modelFieldRequired, isTrue);
    expect(c.vehicle.value.canAdvance, isTrue);
    expect(vehicles.calls, ['lookup:yb68 abc']);
  });

  test('a PROVIDER result leaves vehicleModel OUT of the create body', () async {
    vehicles.result = _lookup(model: '320d', source: ModelSource.provider);
    await c.lookupVehicle('LM19XYZ');
    expect(c.vehicle.value, isA<VehicleResolved>());
    expect(c.draft.manualModelRequired, isFalse);
    expect(c.vehicle.value.modelFieldEnabled, isFalse);

    fillValidDraft();
    // A model left over from an earlier manual attempt must NOT be sent:
    // vehicles are keyed by regNumber @unique, so it would overwrite the shared
    // row and flip its source to MANUAL for every other buyer on that plate.
    c.draft.vehicleModel = '320d Touring';
    expect(c.draft.toBody().containsKey('vehicleModel'), isFalse);
  });

  test('a 404 lookup is not a dead end — the buyer can still advance', () async {
    vehicles.result = const Err(
      ApiError(code: ApiErrorCode.notFound, statusCode: 404, message: 'Vehicle not found'),
    );
    await c.lookupVehicle('XX99XXX');
    expect(c.vehicle.value, isA<VehicleUnknownReg>());
    expect(c.vehicle.value.canAdvance, isTrue);
    expect(c.draft.manualModelRequired, isTrue);
    // POST /v1/requests does its own find-or-create on regNumber, so this is
    // not a failure to show the buyer.
    expect(c.formError.value, isNull);
  });

  test('a 5xx lookup is retryable, and continueWithoutLookup escapes it', () async {
    vehicles.result = const Err(
      ApiError(code: ApiErrorCode.internal, statusCode: 500, message: 'Server error'),
    );
    await c.lookupVehicle('LM19XYZ');
    final failed = c.vehicle.value;
    expect(failed, isA<VehicleFailed>());
    expect((failed as VehicleFailed).retryable, isTrue);
    expect(failed.canAdvance, isFalse);

    c.continueWithoutLookup();
    expect(c.vehicle.value, isA<VehicleUnknownReg>());
    expect(c.vehicle.value.canAdvance, isTrue);
  });

  test('submit() on an invalid draft never reaches the repository', () async {
    final outcome = await c.submit();
    expect(outcome, SubmitOutcome.invalid);
    expect(requests.createCalls, 0);
    expect(c.fieldErrorFor('regNumber'), isNotNull);
    expect(c.fieldErrorFor('categoryId'), isNotNull);
  });

  test('two rapid submit() calls produce exactly ONE request', () async {
    fillValidDraft();
    requests.createResult = Ok(_created);
    // Deliberately not awaited in turn: creating a request broadcasts PUSH and
    // IN_APP notifications to every matching supplier, so a double-tap that got
    // through would be a second real broadcast.
    final first = c.submit();
    final second = c.submit();
    final outcomes = await Future.wait([first, second]);

    expect(requests.createCalls, 1);
    expect(outcomes, contains(SubmitOutcome.created));
    expect(c.created.value?.id, 'req_1');
    expect(SessionStore.lastRegionWire, Region.london.wire);
  });

  test('a confirmed create SPENDS the draft — the wizard reopens empty',
      () async {
    fillValidDraft();
    picker.next.add(FakeImagePickerService.image());
    await c.images.addFromPicker();
    await c.images.uploadAll();
    c.goTo(2);
    final spentKey = c.draft.uploadedKeys.single;
    requests.createResult = Ok(_created);

    expect(await c.submit(), SubmitOutcome.created);

    // This controller is a session-long singleton, so reading it back here IS
    // reopening the wizard. Before the fix it clearing only the PERSISTED draft
    // left this one whole: step 3/3, pre-filled, Send Request live, and
    // toBody() still carrying `spentKey` — s3Key @unique -> P2002 -> 409.
    expect(spentKey, isNotEmpty, reason: 'precondition: a key was consumed');
    expect(c.step.value, 0);
    expect(c.draft.partName, isEmpty);
    expect(c.draft.uploadedKeys, isEmpty);
    expect(c.images.slots, isEmpty);
    expect(c.vehicle.value, isA<VehicleIdle>());
    expect(c.draft.validate(), isNotEmpty, reason: 'Send Request is inert');
    // The two things that must SURVIVE: the region a buyer does not want to
    // re-pick, and `created` — the confirm step reads it back to show the sent
    // sheet the moment submit() returns.
    expect(c.draft.region, Region.london);
    expect(c.created.value?.id, 'req_1');
  });

  test('a network failure on submit reports unconfirmed, not failed', () async {
    fillValidDraft();
    requests.createResult = const Err(ApiError.network());
    final outcome = await c.submit();
    expect(outcome, SubmitOutcome.unconfirmed);
    expect(c.formError.value, contains('could not confirm'));
    expect(c.created.value, isNull);
    expect(requests.createCalls, 1);
  });

  test('custom vehicle entry sets VehicleCustom and toBody emits all vehicle fields', () async {
    c.switchToCustomVehicle();
    expect(c.draft.isCustomVehicle, isTrue);
    expect(c.vehicle.value, isA<VehicleCustom>());
    expect(c.vehicle.value.canAdvance, isTrue);

    c.setCustomVehicleDetails(
      regNumber: 'WM68ABC',
      make: 'BMW',
      model: '3 Series',
      year: 2018,
      fuel: 'DIESEL',
      colour: 'BLACK',
    );

    expect(c.draft.regNumber, 'WM68ABC');
    expect(c.draft.vehicleMake, 'BMW');
    expect(c.draft.vehicleModel, '3 Series');
    expect(c.draft.vehicleYear, 2018);
    expect(c.draft.vehicleFuel, 'DIESEL');
    expect(c.draft.vehicleColour, 'BLACK');

    fillValidDraft();
    final body = c.draft.toBody();
    expect(body['vehicleMake'], 'BMW');
    expect(body['vehicleModel'], '3 Series');
    expect(body['vehicleYear'], 2018);
    expect(body['vehicleFuel'], 'DIESEL');
    expect(body['vehicleColour'], 'BLACK');
  });
}

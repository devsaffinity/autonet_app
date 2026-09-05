import 'dart:async';

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/controller/buyer/request_images_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/blob_uploader.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/vehicle.dart';
import 'package:autonect/data/repositories/requests_repository.dart';
import 'package:autonect/data/repositories/vehicles_repository.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/request_draft.dart';
import 'package:autonect/domain/vehicle_step.dart';
import 'package:autonect/services/image_picker_service.dart';
import 'package:autonect/services/request_draft_store.dart';
import 'package:autonect/services/session_store.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// `unconfirmed` is NOT a failure — see [NewRequestController.submit].
enum SubmitOutcome { created, invalid, failed, unconfirmed }

/// The three-step new-request wizard: owns the [RequestDraft] and the image
/// tray, owns no TextEditingController, never navigates.
class NewRequestController extends ApiController with WidgetsBindingObserver {
  NewRequestController({
    required RequestsRepository requests,
    required VehiclesRepository vehicles,
    required BlobUploader uploader,
    required ImagePickerService picker,
    required TokenStore tokens,
    super.toast, super.showBusy, super.hideBusy,
  }) : _requests = requests, _vehicles = vehicles, _tokens = tokens {
    images = RequestImagesController(
        requests: requests, uploader: uploader, picker: picker,
        onChanged: scheduleSave);
    final id = _userId;
    _adoptDraft(id == null ? null : RequestDraftStore.load(id));
  }

  final RequestsRepository _requests;
  final VehiclesRepository _vehicles;
  final TokenStore _tokens;
  late final RequestImagesController images;

  static NewRequestController ensure() =>
      Get.isRegistered<NewRequestController>()
      ? Get.find<NewRequestController>()
      : Get.put(NewRequestController(
          requests: Get.find<RequestsRepository>(),
          vehicles: Get.find<VehiclesRepository>(),
          uploader: Get.find<BlobUploader>(),
          picker: Get.find<ImagePickerService>(),
          tokens: Get.find<TokenStore>()));

  RequestDraft draft = RequestDraft();
  final Rx<VehicleStep> vehicle = Rx<VehicleStep>(const VehicleIdle());
  final RxInt step = 0.obs;
  final Rxn<PartRequest> created = Rxn<PartRequest>();

  Timer? _saveTimer;
  String? get _userId => _tokens.user?.id;

  void goTo(int index) {
    step.value = index;
    scheduleSave();
  }

  /// Call from onChanged. Debounced: a 12-character part name is 12 writes.
  void scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), saveNow);
  }

  void saveNow() {
    _saveTimer?.cancel();
    draft.step = step.value;
    if (_userId case final id?) RequestDraftStore.save(id, draft);
  }

  /// Never auto-retried: a negative lookup is not cached server-side, so every
  /// retry re-bills the DVLA provider for the same miss.
  Future<void> lookupVehicle(String reg) async {
    if (busy.value) return;
    final trimmed = reg.trim();
    draft.regNumber = trimmed;
    vehicle.value = const VehicleLooking();
    await run<VehicleLookup, void>(null, () => _vehicles.lookup(trimmed), (r) {
      switch (r) {
        case Ok(:final value):
          draft.manualModelRequired = value.needsManualModel;
          vehicle.value = value.needsManualModel
              ? VehicleManualModel(value) : VehicleResolved(value);
        case Err(:final error):
          _lookupFailed(error, trimmed);
      }
    }, silent: true);
    scheduleSave();
  }

  /// A 404 — or a buyer who declines to wait for a flaky provider — is NOT a
  /// dead end: `POST /v1/requests` does its own find-or-create on `regNumber`.
  void continueWithoutLookup() {
    draft.manualModelRequired = true;
    vehicle.value = VehicleUnknownReg(draft.regNumber);
    scheduleSave();
  }

  void _lookupFailed(ApiError e, String reg) {
    if (e.code == ApiErrorCode.notFound) {
      draft.manualModelRequired = true;
      vehicle.value = VehicleUnknownReg(reg);
    } else if (e.code == ApiErrorCode.validationError) {
      vehicle.value = const VehicleIdle();
      absorb(e);
      if (fieldErrors.isEmpty) fieldErrors['regNumber'] = userMessageFor(e);
    } else {
      vehicle.value = VehicleFailed(e);
    }
  }

  /// Single-flight and NEVER auto-retried: creating a request fans out PUSH and
  /// IN_APP notifications to every matching supplier and invalidates their feed
  /// caches, so a duplicate submit is a second real broadcast. NOT gated on
  /// uploads — `imageKeys` defaults to `[]`, so 3 of 4 photos still ships.
  Future<SubmitOutcome> submit() {
    final invalid = draft.validate();
    if (invalid.isNotEmpty) {
      clearErrors();
      fieldErrors.addAll(invalid);
      return Future.value(SubmitOutcome.invalid);
    }
    return run<PartRequest, SubmitOutcome>(
        null, () => _requests.create(draft), _afterCreate);
  }

  SubmitOutcome _afterCreate(ApiResult<PartRequest> r) {
    switch (r) {
      case Ok(:final value):
        // [created] FIRST and never cleared here: the confirm step reads it
        // back to show the sent sheet the moment this returns.
        created.value = value;
        SessionStore.lastRegionWire = draft.region?.wire;
        if (_userId case final id?) RequestDraftStore.clear(id);
        // The draft is SPENT. Clearing only the PERSISTED copy left this
        // singleton's in-memory one whole: reopening landed on 3/3, pre-filled,
        // with toBody() still carrying the consumed S3 keys -> P2002 -> 409.
        _adoptDraft(null);
        return SubmitOutcome.created;
      case Err(:final error):
        final c = error.code;
        if (c == ApiErrorCode.network || c == ApiErrorCode.timeout) {
          formError.value = 'We could not confirm your request was sent — '
              'check My Requests before trying again.';
          return SubmitOutcome.unconfirmed;
        }
        absorb(error);
        return SubmitOutcome.failed;
    }
  }

  /// The wizard's [ApiController.beginEntity]: the entity IS the draft, so
  /// step, vehicle stage and image tray are all re-seeded from [d] — or, when
  /// [d] is null, from an empty draft carrying only the region forward.
  void _adoptDraft(RequestDraft? d) {
    _saveTimer?.cancel();
    draft = d ??
        RequestDraft(region: Region.fromWire(SessionStore.lastRegionWire));
    step.value = draft.step;
    vehicle.value = draft.manualModelRequired
        ? VehicleUnknownReg(draft.regNumber)
        : const VehicleIdle();
    images.adopt(draft.images);
    // The tray BECOMES the draft's list: ONE copy of every single-use S3 key.
    draft.images = images.slots;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The last moment before the OS may reclaim the wizard and its
    // single-use S3 keys, so it ignores the debounce.
    if (state == AppLifecycleState.paused) saveNow();
  }

  @override
  void onClose() {
    _saveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}

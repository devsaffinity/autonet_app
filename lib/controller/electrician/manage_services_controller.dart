import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/electrician_service.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// Controller for the Electrician 'Manage Services' screen.
/// Loads, adds, updates and deletes provider services inventory via the backend API.
class ManageServicesController extends ApiController {
  ManageServicesController(
    this._repo, {
    super.toast,
    super.showBusy,
    super.hideBusy,
  });

  final ProfileRepository _repo;

  static ManageServicesController ensure() =>
      Get.isRegistered<ManageServicesController>()
          ? Get.find<ManageServicesController>()
          : Get.put(ManageServicesController(Get.find<ProfileRepository>()));

  final Rx<ViewState<List<ElectricianService>>> state =
      Rx<ViewState<List<ElectricianService>>>(const Loading());

  final RxList<ElectricianService> services = <ElectricianService>[].obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadServices();
  }

  /// Fetches the electrician services inventory from GET /v1/electrician/services.
  Future<void> loadServices({bool silent = false}) async {
    if (!silent) {
      state.value = const Loading();
    }
    final res = await _repo.getElectricianServices();
    switch (res) {
      case Ok(:final value):
        services.assignAll(value);
        state.value = value.isEmpty ? const Empty() : Data(value);
      case Err(:final error):
        if (!silent) {
          state.value = Failed(error);
        }
        toast(error.message);
    }
  }

  /// Adds a new service to active inventory via POST /v1/electrician/services.
  Future<bool> addService({
    required String name,
    required String price,
    required String pricingType,
    String? description,
  }) async {
    if (name.trim().isEmpty) {
      toast('Please enter a service name');
      return false;
    }
    if (price.trim().isEmpty) {
      toast('Please enter a price');
      return false;
    }

    isSubmitting.value = true;
    showBusy();
    try {
      final res = await _repo.createElectricianService(
        name: name.trim(),
        price: price.trim(),
        pricingType: pricingType,
        description: description?.trim(),
      );

      switch (res) {
        case Ok(:final value):
          services.add(value);
          state.value = Data(services.toList());
          toast('Service added to active inventory');
          return true;
        case Err(:final error):
          toast(error.message);
          return false;
      }
    } finally {
      isSubmitting.value = false;
      hideBusy();
    }
  }

  /// Updates an existing service via PUT /v1/electrician/services/:id.
  Future<bool> updateService({
    required String id,
    required String name,
    required String price,
    required String pricingType,
    String? description,
  }) async {
    if (name.trim().isEmpty) {
      toast('Please enter a service name');
      return false;
    }
    if (price.trim().isEmpty) {
      toast('Please enter a price');
      return false;
    }

    isSubmitting.value = true;
    showBusy();
    try {
      final res = await _repo.updateElectricianService(
        id: id,
        name: name.trim(),
        price: price.trim(),
        pricingType: pricingType,
        description: description?.trim(),
      );

      switch (res) {
        case Ok(:final value):
          final idx = services.indexWhere((s) => s.id == id);
          if (idx != -1) {
            services[idx] = value;
          }
          state.value = Data(services.toList());
          toast('Service updated successfully');
          return true;
        case Err(:final error):
          toast(error.message);
          return false;
      }
    } finally {
      isSubmitting.value = false;
      hideBusy();
    }
  }

  /// Deletes a service from active inventory via DELETE /v1/electrician/services/:id.
  Future<bool> deleteService(String id) async {
    isSubmitting.value = true;
    showBusy();
    try {
      final res = await _repo.deleteElectricianService(id);
      switch (res) {
        case Ok():
          services.removeWhere((s) => s.id == id);
          state.value =
              services.isEmpty ? const Empty() : Data(services.toList());
          toast('Service removed from inventory');
          return true;
        case Err(:final error):
          toast(error.message);
          return false;
      }
    } finally {
      isSubmitting.value = false;
      hideBusy();
    }
  }
}

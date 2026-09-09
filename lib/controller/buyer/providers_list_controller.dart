import 'dart:async';

import 'package:autonect/controller/base/paged_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/providers_repository.dart';
import 'package:get/get.dart';

/// The full provider directory behind View All — `GET /v1/providers`, paged.
class ProvidersListController extends PagedController<ServiceProvider> {
  ProvidersListController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final ProvidersRepository _repo;

  static ProvidersListController ensure() =>
      Get.isRegistered<ProvidersListController>()
      ? Get.find<ProvidersListController>()
      : Get.put(ProvidersListController(Get.find<ProvidersRepository>()));

  /// Server-side over the provider's name AND location, so 'cardiff' finds a
  /// garage whose name never mentions it.
  final RxString query = ''.obs;

  /// null is 'All regions', and the repository then omits the key.
  final Rxn<Region> region = Rxn<Region>();

  Timer? _queryTimer;

  /// Debounced at 350ms, matching the requests search — one request per
  /// keystroke would reset the cursor on every letter.
  void setQuery(String value) {
    _queryTimer?.cancel();
    if (value.trim() == query.value) return;
    _queryTimer = Timer(const Duration(milliseconds: 350), () {
      query.value = value.trim();
      refreshForFilter();
    });
  }

  /// [refreshForFilter], not `refreshFirst`: the previous region's rows must be
  /// blanked rather than sit under a chip that no longer describes them.
  Future<void> setRegion(Region? value) {
    region.value = value;
    return refreshForFilter();
  }

  @override
  void onClose() {
    _queryTimer?.cancel();
    super.onClose();
  }

  @override
  Future<ApiResult<Paged<ServiceProvider>>> fetchPage(int page) =>
      _repo.list(page: page, region: region.value, q: query.value);

  @override
  String idOf(ServiceProvider item) => item.id;
}

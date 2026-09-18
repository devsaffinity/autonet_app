import 'dart:async';

import 'package:autonect/controller/base/paged_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:get/get.dart';

class SupplierLeadsController extends PagedController<SupplierLead> {
  SupplierLeadsController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final SupplierRepository _repo;

  static SupplierLeadsController ensure() =>
      Get.isRegistered<SupplierLeadsController>()
          ? Get.find<SupplierLeadsController>()
          : Get.put(SupplierLeadsController(Get.find<SupplierRepository>()));

  final RxString query = ''.obs;
  final Rxn<Region> regionFilter = Rxn<Region>();
  final Rxn<PartCondition> conditionFilter = Rxn<PartCondition>();
  final Rxn<RequestUrgency> urgencyFilter = Rxn<RequestUrgency>();
  final RxSet<String> activeFilterLabels = <String>{}.obs;

  Timer? _debounceTimer;

  void setQuery(String value) {
    _debounceTimer?.cancel();
    if (value.trim() == query.value) return;
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      query.value = value.trim();
      refreshForFilter();
    });
  }

  void toggleFilter(String label) {
    if (label == 'All') {
      activeFilterLabels.clear();
      _applyActiveFilterLabels();
      refreshForFilter();
      return;
    }
    if (activeFilterLabels.contains(label)) {
      activeFilterLabels.remove(label);
    } else {
      activeFilterLabels.add(label);
    }
    _applyActiveFilterLabels();
    refreshForFilter();
  }

  void clearFilters() {
    activeFilterLabels.clear();
    query.value = '';
    _applyActiveFilterLabels();
    refreshForFilter();
  }

  void _applyActiveFilterLabels() {
    // Reset filters
    regionFilter.value = null;
    conditionFilter.value = null;
    urgencyFilter.value = null;

    for (final label in activeFilterLabels) {
      // Check region
      for (final r in Region.values) {
        if (r.label.toLowerCase() == label.toLowerCase()) {
          regionFilter.value = r;
        }
      }
      // Check condition
      if (label.toLowerCase() == 'new') conditionFilter.value = PartCondition.newPart;
      if (label.toLowerCase() == 'used') conditionFilter.value = PartCondition.used;

      // Check urgency
      if (label.toLowerCase() == 'urgent') urgencyFilter.value = RequestUrgency.urgent;
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  @override
  Future<ApiResult<Paged<SupplierLead>>> fetchPage(int page) =>
      _repo.feed(
        page: page,
        partName: query.value.isEmpty ? null : query.value,
        region: regionFilter.value,
        condition: conditionFilter.value,
        urgency: urgencyFilter.value,
      );

  @override
  String idOf(SupplierLead item) => item.id;
}

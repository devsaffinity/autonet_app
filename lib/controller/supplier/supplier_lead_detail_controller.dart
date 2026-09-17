import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

class SupplierLeadDetailController extends ApiController {
  SupplierLeadDetailController(
    this.requestId,
    this._repo, {
    super.toast,
    super.showBusy,
    super.hideBusy,
  });

  final String requestId;
  final SupplierRepository _repo;

  static const StateSlot _slot = StateSlot('supplierLeadDetail');

  final Rx<ViewState<SupplierLeadDetail>> state =
      Rx<ViewState<SupplierLeadDetail>>(const Loading());

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() {
    state.value = const Loading();
    return runRead<SupplierLeadDetail>(
      _slot,
      () => _repo.leadDetail(requestId),
      (r) {
        switch (r) {
          case Err(:final error):
            state.value = Failed(error);
          case Ok(:final value):
            state.value = Data(value);
        }
      },
    );
  }
}

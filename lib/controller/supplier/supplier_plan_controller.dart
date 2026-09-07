import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// The registration wizard's plan step.
///
/// Read-only: there is no purchase path from the app. See [BillingRepository].
class SupplierPlanController extends ApiController {
  SupplierPlanController(this._repo);

  static SupplierPlanController ensure() =>
      Get.isRegistered<SupplierPlanController>()
      ? Get.find<SupplierPlanController>()
      : Get.put(SupplierPlanController(Get.find<BillingRepository>()));

  final BillingRepository _repo;

  static const StateSlot _plansRead = StateSlot('billingPlans');

  final Rx<ViewState<List<BillingPlan>>> plans =
      Rx<ViewState<List<BillingPlan>>>(const Loading());

  /// [runRead], not [run]: the step's Try again is this same call, and a retry
  /// tapped while the first was in flight would otherwise be dropped as
  /// re-entrant and leave the non-retryable "please wait" message over a list
  /// whose only retry control had gone.
  Future<void> load() => runRead(_plansRead, _repo.plans, (r) {
    switch (r) {
      case Err(:final error):
        plans.value = Failed<List<BillingPlan>>(error);
      case Ok(:final value):
        plans.value = value.isEmpty
            ? const Empty<List<BillingPlan>>('No plans available')
            : Data<List<BillingPlan>>(value);
    }
  });
}

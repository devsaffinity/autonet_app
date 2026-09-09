import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/providers_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// One provider — `GET /v1/providers/{id}`.
class ProviderDetailController extends ApiController {
  ProviderDetailController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final ProvidersRepository _repo;

  static ProviderDetailController ensure() =>
      Get.isRegistered<ProviderDetailController>()
      ? Get.find<ProviderDetailController>()
      : Get.put(ProviderDetailController(Get.find<ProvidersRepository>()));

  static const StateSlot _detailRead = StateSlot('providerDetail');

  final Rx<ViewState<ServiceProvider>> provider =
      Rx<ViewState<ServiceProvider>>(const Loading());

  /// BLANKS FIRST, unconditionally — unlike the list controllers.
  ///
  /// This controller is reused across pushes, so opening provider B while A's
  /// data is still in the Rx would paint A's name under B's route for a frame.
  /// [runRead] then makes the last id win if two opens race.
  Future<void> load(String id) {
    provider.value = const Loading();
    return runRead(
      _detailRead,
      () => _repo.byId(id),
      (r) {
        switch (r) {
          case Err(:final error):
            provider.value = Failed<ServiceProvider>(error);
          case Ok(:final value):
            provider.value = Data<ServiceProvider>(value);
        }
      },
    );
  }
}

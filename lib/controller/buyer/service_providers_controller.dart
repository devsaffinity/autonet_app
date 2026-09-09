import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/providers_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// The home screen's Service Providers section — `GET /v1/providers`.
///
/// Its own controller for the same reason BuyerOffersController is: the three
/// home sections load independently and fail independently, and one controller
/// holding all of them would blank a good carousel because a different call
/// timed out.
class ServiceProvidersController extends ApiController {
  ServiceProvidersController(
    this._repo, {
    super.toast,
    super.showBusy,
    super.hideBusy,
  });

  final ProvidersRepository _repo;

  static ServiceProvidersController ensure() =>
      Get.isRegistered<ServiceProvidersController>()
      ? Get.find<ServiceProvidersController>()
      : Get.put(ServiceProvidersController(Get.find<ProvidersRepository>()));

  /// A preview strip, like the requests carousel. The full directory is behind
  /// View All, so paging here would duplicate that screen.
  static const int _previewLimit = 6;

  static const StateSlot _providersRead = StateSlot('serviceProviders');

  final Rx<ViewState<List<ServiceProvider>>> providers =
      Rx<ViewState<List<ServiceProvider>>>(const Loading());

  /// [runRead], NOT [run]: home loads on mount and again on every
  /// pull-to-refresh, and `run` drops the refresh as re-entrant, leaving a
  /// non-retryable 'please wait' on the landing screen.
  Future<void> load() {
    if (providers.value is! Data<List<ServiceProvider>>) {
      providers.value = const Loading();
    }
    return runRead(
      _providersRead,
      () => _repo.list(limit: _previewLimit),
      (r) {
        switch (r) {
          case Err(:final error):
            providers.value = Failed<List<ServiceProvider>>(error);
          case Ok(:final value):
            // `meta.total` is counted in the same transaction as the page, so
            // an empty `items` against a non-zero total is a paging bug rather
            // than an empty directory.
            providers.value = value.meta.total == 0
                ? const Empty<List<ServiceProvider>>(
                    'No providers yet',
                    'Approved garages and electricians appear here.',
                  )
                : Data<List<ServiceProvider>>(value.items);
        }
      },
    );
  }
}

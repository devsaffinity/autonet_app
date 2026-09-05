import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/requests_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// The buyer home summary: the newest open requests, and how many offers are
/// waiting across them.
class BuyerHomeController extends ApiController {
  BuyerHomeController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final RequestsRepository _repo;

  static BuyerHomeController ensure() =>
      Get.isRegistered<BuyerHomeController>()
      ? Get.find<BuyerHomeController>()
      : Get.put(BuyerHomeController(Get.find<RequestsRepository>()));

  /// Five is the whole section; the full list lives behind My Requests.
  static const int _previewLimit = 5;

  static const StateSlot _requestsRead = StateSlot('activeRequests');

  final Rx<ViewState<List<PartRequest>>> activeRequests =
      Rx<ViewState<List<PartRequest>>>(const Loading());

  List<PartRequest> get _items => switch (activeRequests.value) {
    Data<List<PartRequest>>(:final value) => value,
    _ => const [],
  };

  /// Summed from the `offerCount` the payload already carries. There is no
  /// cross-request buyer offers endpoint, so the alternative is one call per
  /// request — an N+1 that walks straight into the 300 req/60s global limiter.
  int get totalOpenOffers {
    var total = 0;
    for (final r in _items) {
      total += r.offerCount;
    }
    return total;
  }

  int get requestsWithOffers => _items.where((r) => r.offerCount > 0).length;

  /// [runRead], NOT [run]: home calls this on mount and again on every
  /// pull-to-refresh, so a refresh started before the first load answered was
  /// dropped as a re-entry and the whole section became a non-retryable 'Please
  /// wait for the current action to finish.' — on the buyer's landing screen,
  /// with no Try again on it.
  Future<void> load() {
    if (activeRequests.value is! Data<List<PartRequest>>) {
      activeRequests.value = const Loading();
    }
    return runRead(
      _requestsRead,
      () => _repo.listMine(limit: _previewLimit, status: RequestStatus.open),
      (r) {
        switch (r) {
          case Err(:final error):
            activeRequests.value = Failed<List<PartRequest>>(error);
          case Ok(:final value):
            activeRequests.value = value.meta.total == 0
                ? const Empty<List<PartRequest>>(
                    'No open requests',
                    'Start one and suppliers will send you offers.',
                  )
                : Data<List<PartRequest>>(value.items);
        }
      },
    );
  }
}

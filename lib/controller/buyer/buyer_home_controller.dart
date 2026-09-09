import 'dart:async';

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

  /// The home search box. Server-side, over partName / partNumber / regNumber
  /// — the same three columns `listRequestsQuerySchema` searches — so it
  /// narrows ALL of the buyer's open requests, not the five already on screen.
  final RxString query = ''.obs;

  Timer? _queryTimer;

  /// Call from onChanged. Debounced, because a 10-character part name is 10
  /// keystrokes and one request each would burn the 300 req/60s global limiter
  /// on a single search.
  ///
  /// Re-issuing is safe at any speed regardless: [load] goes through [runRead],
  /// so a superseded read's answer is discarded rather than rendered.
  void setQuery(String value) {
    _queryTimer?.cancel();
    if (value.trim() == query.value) return;
    _queryTimer = Timer(const Duration(milliseconds: 350), () {
      query.value = value.trim();
      load();
    });
  }

  @override
  void onClose() {
    _queryTimer?.cancel();
    super.onClose();
  }

  List<PartRequest> get _items => switch (activeRequests.value) {
    Data<List<PartRequest>>(:final value) => value,
    _ => const [],
  };

  /// Summed from the `offerCount` the payload already carries, so it costs
  /// nothing. `GET /v1/buyer/offers` now exists and BuyerOffersController reads
  /// it, but that is a paged preview — this is the total across the whole
  /// carousel, and deriving it from a page would undercount.
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
      () => _repo.listMine(
        limit: _previewLimit,
        status: RequestStatus.open,
        q: query.value,
      ),
      (r) {
        switch (r) {
          case Err(:final error):
            activeRequests.value = Failed<List<PartRequest>>(error);
          case Ok(:final value):
            activeRequests.value = value.meta.total == 0
                // The empty copy has to say WHICH emptiness this is, or a
                // search that matched nothing reads as "you have no requests"
                // and the buyer clears a filter they cannot see.
                ? (query.value.isEmpty
                      ? const Empty<List<PartRequest>>(
                          'No open requests',
                          'Start one and suppliers will send you offers.',
                        )
                      : const Empty<List<PartRequest>>(
                          'No matches',
                          'No open request matches that part, number or reg.',
                        ))
                : Data<List<PartRequest>>(value.items);
        }
      },
    );
  }
}

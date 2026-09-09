import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// The home screen's Offers feed — `GET /v1/buyer/offers`.
///
/// Separate from [BuyerHomeController] rather than a second slot on it: the two
/// sections are independently refreshable and independently failable, and one
/// controller holding both would blank a good requests carousel because the
/// offers call timed out.
class BuyerOffersController extends ApiController {
  BuyerOffersController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final OrdersRepository _repo;

  static BuyerOffersController ensure() =>
      Get.isRegistered<BuyerOffersController>()
      ? Get.find<BuyerOffersController>()
      : Get.put(BuyerOffersController(Get.find<OrdersRepository>()));

  /// A preview, like the requests carousel above it. The full list is one tap
  /// away on My Requests, so paging here would duplicate that screen.
  static const int _previewLimit = 5;

  static const StateSlot _offersRead = StateSlot('buyerOffers');

  final Rx<ViewState<List<Offer>>> offers =
      Rx<ViewState<List<Offer>>>(const Loading());

  /// [runRead], NOT [run] — same reason as the requests carousel: home loads on
  /// mount and again on every pull-to-refresh, and `run` would drop the refresh
  /// as a re-entrant call and leave a non-retryable 'please wait' on the
  /// landing screen.
  Future<void> load() {
    if (offers.value is! Data<List<Offer>>) offers.value = const Loading();
    return runRead(
      _offersRead,
      () => _repo.buyerOffers(limit: _previewLimit),
      (r) {
        switch (r) {
          case Err(:final error):
            offers.value = Failed<List<Offer>>(error);
          case Ok(:final value):
            // `meta.total` is authoritative — it is counted in the same
            // transaction as the page, so an empty `items` against a non-zero
            // total is a paging bug, not an empty feed.
            offers.value = value.meta.total == 0
                ? const Empty<List<Offer>>(
                    'No offers yet',
                    'Suppliers reply to your open requests here.',
                  )
                : Data<List<Offer>>(value.items);
        }
      },
    );
  }
}

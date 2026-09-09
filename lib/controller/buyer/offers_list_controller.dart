import 'package:autonect/controller/base/paged_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:get/get.dart';

/// Every offer across all of this buyer's requests, paged — the screen behind
/// the home feed's View All.
///
/// Separate from [BuyerOffersController] rather than a mode on it. That one
/// holds the home teaser: a single short read that reloads whole on every pull,
/// with no cursor and nothing to append to. Merging them would put paging state
/// on the landing screen that the landing screen never advances, and would make
/// a pull-to-refresh on home decide what an unrelated list screen is showing.
class OffersListController extends PagedController<Offer> {
  OffersListController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final OrdersRepository _repo;

  static OffersListController ensure() =>
      Get.isRegistered<OffersListController>()
      ? Get.find<OffersListController>()
      : Get.put(OffersListController(Get.find<OrdersRepository>()));

  /// No status filter, unlike My Requests. `GET /v1/buyer/offers` takes page
  /// and limit only — its DTO is the ORDER status enum, which an offer status
  /// would 400 against — and the service already drops WITHDRAWN server-side,
  /// which is the one exclusion a buyer needs: a retracted offer is not a price
  /// to quote from.
  @override
  Future<ApiResult<Paged<Offer>>> fetchPage(int page) =>
      _repo.buyerOffers(page: page);

  @override
  String idOf(Offer item) => item.id;
}

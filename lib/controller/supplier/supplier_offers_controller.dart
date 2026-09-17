import 'package:autonect/controller/base/paged_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:get/get.dart';

class SupplierOffersController extends PagedController<SupplierOffer> {
  SupplierOffersController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final SupplierRepository _repo;

  static SupplierOffersController ensure() =>
      Get.isRegistered<SupplierOffersController>()
          ? Get.find<SupplierOffersController>()
          : Get.put(SupplierOffersController(Get.find<SupplierRepository>()));

  final RxInt currentTabIndex = 0.obs;

  OfferStatus? get currentStatus => switch (currentTabIndex.value) {
    0 => OfferStatus.pending,
    1 => OfferStatus.accepted,
    2 => OfferStatus.rejected,
    _ => null,
  };

  Future<void> setTab(int index) {
    if (currentTabIndex.value == index) return Future.value();
    currentTabIndex.value = index;
    return refreshForFilter();
  }

  @override
  Future<ApiResult<Paged<SupplierOffer>>> fetchPage(int page) =>
      _repo.listOffers(page: page, status: currentStatus);

  @override
  String idOf(SupplierOffer item) => item.id;

  Future<bool> withdrawOffer(String offerId) => run<SupplierOffer, bool>(
    null,
    () => _repo.withdrawOffer(offerId),
    (r) {
      switch (r) {
        case Err(:final error):
          toast(error.message);
          return false;
        case Ok():
          toast('Offer withdrawn');
          refreshForFilter();
          return true;
      }
    },
  );
}

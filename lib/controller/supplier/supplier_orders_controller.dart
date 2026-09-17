import 'package:autonect/controller/base/paged_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:get/get.dart';

class SupplierOrdersController extends PagedController<Order> {
  SupplierOrdersController(this._ordersRepo, {super.toast, super.showBusy, super.hideBusy});

  final OrdersRepository _ordersRepo;

  static SupplierOrdersController ensure() =>
      Get.isRegistered<SupplierOrdersController>()
          ? Get.find<SupplierOrdersController>()
          : Get.put(SupplierOrdersController(Get.find<OrdersRepository>()));

  final RxInt currentTabIndex = 0.obs;

  OrderStatus? get filterStatus => switch (currentTabIndex.value) {
    1 => OrderStatus.delivered,
    2 => OrderStatus.cancelled,
    _ => null, // Active orders tab
  };

  Future<void> setTab(int index) {
    if (currentTabIndex.value == index) return Future.value();
    currentTabIndex.value = index;
    return refreshForFilter();
  }

  @override
  Future<ApiResult<Paged<Order>>> fetchPage(int page) async {
    final status = filterStatus;
    final res = await _ordersRepo.list(page: page, status: status);

    if (currentTabIndex.value == 0 && res is Ok<Paged<Order>>) {
      // Filter only active orders (PLACED, PREPARING, OUT_FOR_DELIVERY)
      final active = res.value.items
          .where((o) =>
              o.status == OrderStatus.placed ||
              o.status == OrderStatus.preparing ||
              o.status == OrderStatus.outForDelivery)
          .toList(growable: false);
      return Ok(Paged<Order>(active, res.value.meta));
    }

    return res;
  }

  @override
  String idOf(Order item) => item.id;

  OrderStatus? nextStatusFor(OrderStatus? current) => switch (current) {
    OrderStatus.placed => OrderStatus.preparing,
    OrderStatus.preparing => OrderStatus.outForDelivery,
    OrderStatus.outForDelivery => OrderStatus.delivered,
    _ => null,
  };

  Future<bool> advanceOrder(Order order) async {
    final next = nextStatusFor(order.status);
    if (next == null) return false;

    return run<Order, bool>(
      null,
      () => _ordersRepo.changeStatus(orderId: order.id, status: next),
      (r) {
        switch (r) {
          case Err(:final error):
            toast(error.message);
            return false;
          case Ok():
            toast('Order status updated');
            refreshForFilter();
            return true;
        }
      },
    );
  }
}

import 'package:autonect/controller/base/paged_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:get/get.dart';

/// `GET /v1/orders` with an optional status chip.
class MyOrdersController extends PagedController<Order> {
  MyOrdersController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final OrdersRepository _repo;

  static MyOrdersController ensure() => Get.isRegistered<MyOrdersController>()
      ? Get.find<MyOrdersController>()
      : Get.put(MyOrdersController(Get.find<OrdersRepository>()));

  final Rxn<OrderStatus> filter = Rxn<OrderStatus>();

  /// ALL FIVE statuses, PLACED included. The list filter and the PATCH verb
  /// enum are different sets: PLACED is a perfectly ordinary thing to filter
  /// for and an illegal thing to send.
  static const List<SelectOption<OrderStatus?>> filterOptions = [
    SelectOption<OrderStatus?>(null, 'All'),
    SelectOption<OrderStatus?>(OrderStatus.placed, 'Placed'),
    SelectOption<OrderStatus?>(OrderStatus.preparing, 'Preparing'),
    SelectOption<OrderStatus?>(OrderStatus.outForDelivery, 'Out for delivery'),
    SelectOption<OrderStatus?>(OrderStatus.delivered, 'Delivered'),
    SelectOption<OrderStatus?>(OrderStatus.cancelled, 'Cancelled'),
  ];

  /// [PagedController.refreshForFilter], never `refreshFirst`: a chip change
  /// must blank the previous filter's rows, and it must supersede an in-flight
  /// read rather than be dropped by it.
  Future<void> setFilter(OrderStatus? status) {
    filter.value = status;
    return refreshForFilter();
  }

  @override
  Future<ApiResult<Paged<Order>>> fetchPage(int page) =>
      _repo.list(page: page, status: filter.value);

  @override
  String idOf(Order item) => item.id;
}

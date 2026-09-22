import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// Supplier home controller providing dashboard metrics, preview leads and active orders.
class SupplierHomeController extends ApiController {
  SupplierHomeController(
    this._supplierRepo,
    this._ordersRepo, {
    super.toast,
    super.showBusy,
    super.hideBusy,
  });

  final SupplierRepository _supplierRepo;
  final OrdersRepository _ordersRepo;

  static SupplierHomeController ensure() =>
      Get.isRegistered<SupplierHomeController>()
          ? Get.find<SupplierHomeController>()
          : Get.put(
              SupplierHomeController(
                Get.find<SupplierRepository>(),
                Get.find<OrdersRepository>(),
              ),
            );

  static const StateSlot _dashboardRead = StateSlot('supplierDashboard');
  static const StateSlot _leadsRead = StateSlot('supplierHomeLeads');
  static const StateSlot _ordersRead = StateSlot('supplierHomeOrders');
  static const StateSlot _offersRead = StateSlot('supplierHomeOffers');

  final Rx<ViewState<SupplierDashboardData>> dashboard =
      Rx<ViewState<SupplierDashboardData>>(const Loading());

  final Rx<ViewState<List<SupplierLead>>> leads =
      Rx<ViewState<List<SupplierLead>>>(const Loading());

  final Rx<ViewState<List<Order>>> orders =
      Rx<ViewState<List<Order>>>(const Loading());

  final Rx<ViewState<List<SupplierOffer>>> offers =
      Rx<ViewState<List<SupplierOffer>>>(const Loading());

  /// Cache of active offers indexed by requestId for fast lookup
  final RxMap<String, SupplierOffer> offersByRequestId =
      <String, SupplierOffer>{}.obs;

  SupplierOffer? offerForLead(SupplierLead lead) {
    if (lead.myOffer != null) {
      final off = lead.myOffer!;
      return SupplierOffer(
        id: off.id,
        requestId: off.requestId,
        supplierId: '',
        pricePence: off.pricePence,
        quantity: 1,
        status: off.status,
        createdAt: off.createdAt ?? DateTime.now(),
        updatedAt: off.createdAt ?? DateTime.now(),
      );
    }
    return offersByRequestId[lead.id];
  }

  SupplierOffer? offerForRequestId(String requestId) {
    return offersByRequestId[requestId];
  }

  List<Order> get upcomingOrders => switch (orders.value) {
    Data<List<Order>>(:final value) => value
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled)
        .toList(),
    _ => const [],
  };

  int get creditBalance => switch (dashboard.value) {
    Data<SupplierDashboardData>(:final value) => value.creditBalance,
    _ => 0,
  };

  bool get isSubscribed => switch (dashboard.value) {
    Data<SupplierDashboardData>(:final value) => value.subscribed,
    _ => false,
  };

  int get incomingRequests => switch (dashboard.value) {
    Data<SupplierDashboardData>(:final value) => value.incomingRequests,
    _ => 0,
  };

  int get activeNegotiations => switch (dashboard.value) {
    Data<SupplierDashboardData>(:final value) => value.activeNegotiations,
    _ => 0,
  };

  int get todaysEarningsPence => switch (dashboard.value) {
    Data<SupplierDashboardData>(:final value) => value.todaysEarningsPence,
    _ => 0,
  };

  Future<void> load() async {
    if (dashboard.value is! Data<SupplierDashboardData>) {
      dashboard.value = const Loading();
    }
    if (leads.value is! Data<List<SupplierLead>>) {
      leads.value = const Loading();
    }
    if (orders.value is! Data<List<Order>>) {
      orders.value = const Loading();
    }
    if (offers.value is! Data<List<SupplierOffer>>) {
      offers.value = const Loading();
    }

    await Future.wait([
      _loadDashboard(),
      _loadLeads(),
      _loadOrders(),
      _loadOffers(),
    ]);
  }

  Future<void> _loadDashboard() => runRead<SupplierDashboardData>(
    _dashboardRead,
    _supplierRepo.dashboard,
    (r) {
      switch (r) {
        case Err(:final error):
          dashboard.value = Failed(error);
        case Ok(:final value):
          dashboard.value = Data(value);
      }
    },
  );

  Future<void> _loadLeads() => runRead<Paged<SupplierLead>>(
    _leadsRead,
    () => _supplierRepo.feed(limit: 3),
    (r) {
      switch (r) {
        case Err(:final error):
          leads.value = Failed(error);
        case Ok(:final value):
          leads.value = value.items.isEmpty
              ? const Empty(
                  'No matching leads',
                  'New vehicle part requests matching your categories will appear here.',
                )
              : Data(value.items);
      }
    },
  );

  Future<void> _loadOrders() => runRead<Paged<Order>>(
    _ordersRead,
    () => _ordersRepo.list(limit: 2),
    (r) {
      switch (r) {
        case Err(:final error):
          orders.value = Failed(error);
        case Ok(:final value):
          orders.value = value.items.isEmpty
              ? const Empty(
                  'No orders to fulfil',
                  'When buyers accept your offers, orders appear here.',
                )
              : Data(value.items);
      }
    },
  );

  Future<void> _loadOffers() => runRead<Paged<SupplierOffer>>(
    _offersRead,
    () => _supplierRepo.listOffers(limit: 50),
    (r) {
      switch (r) {
        case Err(:final error):
          offers.value = Failed(error);
        case Ok(:final value):
          offersByRequestId.clear();
          for (final o in value.items) {
            offersByRequestId[o.requestId] = o;
          }
          offers.value = value.items.isEmpty
              ? const Empty(
                  'No active negotiations',
                  'When you send quotes on leads, your negotiations appear here.',
                )
              : Data(value.items);
      }
    },
  );
}

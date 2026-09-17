import 'package:autonect/controller/supplier/supplier_create_offer_controller.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/controller/supplier/supplier_leads_controller.dart';
import 'package:autonect/controller/supplier/supplier_offers_controller.dart';
import 'package:autonect/controller/supplier/supplier_orders_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSupplierRepository implements SupplierRepository {
  SupplierDashboardData dashboardData = const SupplierDashboardData(
    incomingRequests: 5,
    activeNegotiations: 2,
    creditBalance: 30,
    subscribed: false,
    todaysEarningsPence: 20000,
  );

  List<SupplierLead> feedItems = [
    SupplierLead(
      id: 'lead_1',
      partName: 'Alternator',
      offerCount: 1,
      createdAt: DateTime.now(),
      region: Region.london,
      condition: PartCondition.newPart,
    ),
  ];

  List<SupplierOffer> offers = [
    SupplierOffer(
      id: 'off_1',
      requestId: 'lead_1',
      supplierId: 'supp_1',
      pricePence: 15000,
      quantity: 1,
      status: OfferStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  bool offerCreated = false;
  bool offerEdited = false;
  bool offerWithdrawn = false;

  static PageMeta _metaFor(int count) => PageMeta(
    page: 1,
    limit: 20,
    pageSize: count,
    total: count,
    totalPages: 1,
    hasNextPage: false,
    hasPreviousPage: false,
  );

  @override
  Future<ApiResult<SupplierDashboardData>> dashboard() async =>
      Ok(dashboardData);

  @override
  Future<ApiResult<Paged<SupplierLead>>> feed({
    int page = 1,
    int limit = 20,
    String? partName,
    Region? region,
    String? make,
    String? model,
    int? minOffers,
    int? maxOffers,
    String? sort,
  }) async =>
      Ok(Paged(feedItems, _metaFor(feedItems.length)));

  @override
  Future<ApiResult<SupplierLeadDetail>> leadDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<ApiResult<SupplierOffer>> createOffer({
    required String requestId,
    required int pricePence,
    required PartCondition condition,
    int? warrantyMonths,
    required DeliveryOption deliveryOption,
    int? deliveryTimeDays,
    required StockStatus stockStatus,
    required int quantity,
    String? notes,
  }) async {
    offerCreated = true;
    return Ok(offers.first);
  }

  @override
  Future<ApiResult<Paged<SupplierOffer>>> listOffers({
    int page = 1,
    int limit = 20,
    OfferStatus? status,
  }) async =>
      Ok(Paged(offers, _metaFor(offers.length)));

  @override
  Future<ApiResult<SupplierOffer>> editOffer({
    required String offerId,
    int? pricePence,
    PartCondition? condition,
    int? warrantyMonths,
    DeliveryOption? deliveryOption,
    int? deliveryTimeDays,
    StockStatus? stockStatus,
    int? quantity,
    String? notes,
  }) async {
    offerEdited = true;
    return Ok(offers.first);
  }

  @override
  Future<ApiResult<SupplierOffer>> withdrawOffer(String offerId) async {
    offerWithdrawn = true;
    return Ok(offers.first);
  }
}

class FakeOrdersRepository implements OrdersRepository {
  List<Order> orders = [
    Order(
      id: 'ord_1',
      offerId: 'off_1',
      requestId: 'lead_1',
      buyerId: 'buyer_1',
      supplierId: 'supp_1',
      totalPence: 15000,
      status: OrderStatus.placed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      offer: const OrderOfferRef(id: 'off_1', pricePence: 15000, quantity: 1),
      request: const OrderRequestRef(
        id: 'lead_1',
        partName: 'Alternator',
        regNumber: 'LM20 XKR',
      ),
      events: const [],
    ),
  ];

  OrderStatus? lastChangedStatus;

  @override
  Future<ApiResult<Order>> acceptOffer({
    required String offerId,
    String? deliveryLocation,
  }) async =>
      throw UnimplementedError();

  @override
  Future<ApiResult<Paged<Offer>>> buyerOffers({int page = 1, int limit = 20}) async =>
      throw UnimplementedError();

  @override
  Future<ApiResult<Order>> byId(String id) async => Ok(orders.first);

  @override
  Future<ApiResult<Order>> changeStatus({
    required String orderId,
    required OrderStatus status,
    String? note,
  }) async {
    lastChangedStatus = status;
    return Ok(orders.first);
  }

  @override
  Future<ApiResult<Paged<Order>>> list({
    int page = 1,
    int limit = 20,
    OrderStatus? status,
  }) async =>
      Ok(Paged(orders, FakeSupplierRepository._metaFor(orders.length)));

  @override
  Future<ApiResult<List<Offer>>> offersForRequest(String requestId) async =>
      throw UnimplementedError();
}

void main() {
  late FakeSupplierRepository supplierRepo;
  late FakeOrdersRepository ordersRepo;

  setUp(() {
    supplierRepo = FakeSupplierRepository();
    ordersRepo = FakeOrdersRepository();
  });

  group('SupplierHomeController', () {
    test('load populates dashboard, leads, and orders', () async {
      final c = SupplierHomeController(
        supplierRepo,
        ordersRepo,
        showBusy: () {},
        hideBusy: () {},
        toast: (_) {},
      );

      await c.load();
      expect(c.creditBalance, 30);
      expect(c.isSubscribed, isFalse);
      expect(c.incomingRequests, 5);
      expect(c.activeNegotiations, 2);
      expect(c.todaysEarningsPence, 20000);
      expect(c.leads.value is Data<List<SupplierLead>>, isTrue);
      expect(c.orders.value is Data<List<Order>>, isTrue);
    });
  });

  group('SupplierLeadsController', () {
    test('fetches paged leads and applies filters', () async {
      final c = SupplierLeadsController(
        supplierRepo,
        showBusy: () {},
        hideBusy: () {},
        toast: (_) {},
      );

      await c.refreshFirst();
      expect(c.state.value is Data<List<SupplierLead>>, isTrue);

      c.toggleFilter('London');
      expect(c.regionFilter.value, Region.london);
    });
  });

  group('SupplierOffersController', () {
    test('switches tabs and handles withdraw', () async {
      final c = SupplierOffersController(
        supplierRepo,
        showBusy: () {},
        hideBusy: () {},
        toast: (_) {},
      );

      await c.refreshFirst();
      expect(c.currentStatus, OfferStatus.pending);

      await c.setTab(1);
      expect(c.currentStatus, OfferStatus.accepted);

      final withdrawn = await c.withdrawOffer('off_1');
      expect(withdrawn, isTrue);
      expect(supplierRepo.offerWithdrawn, isTrue);
    });
  });

  group('SupplierCreateOfferController', () {
    test('validates price > 0 and submits create offer', () async {
      final c = SupplierCreateOfferController(
        requestId: 'req_1',
        repo: supplierRepo,
        showBusy: () {},
        hideBusy: () {},
        toast: (_) {},
      );

      c.priceController.text = '0';
      var ok = await c.submit();
      expect(ok, isFalse);
      expect(supplierRepo.offerCreated, isFalse);

      c.priceController.text = '150.00';
      c.quantityController.text = '1';
      ok = await c.submit();
      expect(ok, isTrue);
      expect(supplierRepo.offerCreated, isTrue);
    });

    test('edits existing offer when existingOffer is provided', () async {
      final c = SupplierCreateOfferController(
        requestId: 'req_1',
        existingOffer: supplierRepo.offers.first,
        repo: supplierRepo,
        showBusy: () {},
        hideBusy: () {},
        toast: (_) {},
      );

      c.onInit();
      expect(c.isEdit, isTrue);
      expect(c.priceController.text, '150.00');

      c.priceController.text = '180.00';
      final ok = await c.submit();
      expect(ok, isTrue);
      expect(supplierRepo.offerEdited, isTrue);
    });
  });

  group('SupplierOrdersController', () {
    test('switches status tabs and advances order', () async {
      final c = SupplierOrdersController(
        ordersRepo,
        showBusy: () {},
        hideBusy: () {},
        toast: (_) {},
      );

      await c.refreshFirst();
      expect(c.filterStatus, isNull); // Active tab

      await c.setTab(1);
      expect(c.filterStatus, OrderStatus.delivered);

      final advanced = await c.advanceOrder(ordersRepo.orders.first);
      expect(advanced, isTrue);
      expect(ordersRepo.lastChangedStatus, OrderStatus.preparing);
    });
  });
}

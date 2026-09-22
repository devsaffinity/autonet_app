import 'package:autonect/controller/buyer/notifications_controller.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/auth_user.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/notifications_repository.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/supplier/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

class _FakeSupplierRepo implements SupplierRepository {
  bool returnEmpty = false;

  @override
  Future<ApiResult<SupplierDashboardData>> dashboard() async => const Ok(
        SupplierDashboardData(
          incomingRequests: 3,
          activeNegotiations: 2,
          creditBalance: 120,
          subscribed: true,
          todaysEarningsPence: 24500,
        ),
      );

  @override
  Future<ApiResult<Paged<SupplierLead>>> feed({
    int page = 1,
    int limit = 20,
    String? partName,
    Region? region,
    PartCondition? condition,
    RequestUrgency? urgency,
    String? make,
    String? model,
    int? minOffers,
    int? maxOffers,
    String? sort,
  }) async =>
      Ok(
        Paged(
          returnEmpty
              ? []
              : [
                  SupplierLead(
                    id: 'lead_1',
                    partName: 'Dual-Clutch Transmission Assembly',
                    offerCount: 3,
                    createdAt: DateTime.now(),
                    vehicleMake: 'BMW',
                    vehicleYear: 2021,
                    region: Region.london,
                  ),
                ],
          PageMeta(
            page: 1,
            limit: 20,
            pageSize: returnEmpty ? 0 : 1,
            total: returnEmpty ? 0 : 1,
            totalPages: returnEmpty ? 0 : 1,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        ),
      );

  @override
  Future<ApiResult<SupplierLeadDetail>> leadDetail(String id) =>
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
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<Paged<SupplierOffer>>> listOffers({
    int page = 1,
    int limit = 20,
    OfferStatus? status,
  }) async =>
      Ok(
        Paged(
          returnEmpty
              ? []
              : [
                  SupplierOffer(
                    id: 'off_1',
                    requestId: 'lead_1',
                    supplierId: 'supp_1',
                    pricePence: 1245000,
                    quantity: 1,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    request: const SupplierOfferRequestRef(
                      id: 'lead_1',
                      partName: 'V10 Engine Block (AudiR8)',
                      offerCount: 2,
                    ),
                  ),
                ],
          PageMeta(
            page: 1,
            limit: 20,
            pageSize: returnEmpty ? 0 : 1,
            total: returnEmpty ? 0 : 1,
            totalPages: returnEmpty ? 0 : 1,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        ),
      );

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
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<SupplierOffer>> withdrawOffer(String offerId) =>
      throw UnimplementedError();
}

class _FakeOrdersRepo implements OrdersRepository {
  List<Order> orders = [];

  @override
  Future<ApiResult<Order>> acceptOffer({
    required String offerId,
    String? deliveryLocation,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<Order>> byId(String orderId) => throw UnimplementedError();

  @override
  Future<ApiResult<Order>> changeStatus({
    required String orderId,
    required OrderStatus status,
    String? note,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<Paged<Order>>> list({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async =>
      Ok(
        Paged(
          orders,
          PageMeta(
            page: 1,
            limit: 20,
            pageSize: orders.length,
            total: orders.length,
            totalPages: 1,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        ),
      );

  @override
  Future<ApiResult<Paged<Offer>>> buyerOffers({int page = 1, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<List<Offer>>> offersForRequest(String requestId) =>
      throw UnimplementedError();
}

void main() {
  setUp(() {
    Get.reset();
    final profileRepo = FakeProfileRepository();
    final notifsRepo = FakeNotificationsRepository();
    final supplierRepo = _FakeSupplierRepo();
    final ordersRepo = _FakeOrdersRepo();

    Get.put<ProfileRepository>(profileRepo);
    Get.put<NotificationsRepository>(notifsRepo);
    Get.put<SupplierRepository>(supplierRepo);
    Get.put<OrdersRepository>(ordersRepo);

    Get.put<ProfileController>(ProfileController(profileRepo));
    Get.put<NotificationsController>(NotificationsController(notifsRepo));
    Get.put<SupplierHomeController>(
      SupplierHomeController(supplierRepo, ordersRepo),
    );
  });

  tearDown(() => Get.reset());

  testWidgets('SupplierHomePage mounts and renders all Figma sections',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierHomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Top bar: dynamic greeting and business name
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Good morning,' ||
                w.data == 'Good afternoon,' ||
                w.data == 'Good evening,'),
      ),
      findsOneWidget,
    );

    // 2. Quick Actions
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Browse\nRequests'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);

    // 3. 3-column Metrics highlights card
    expect(find.text('Credits Balance'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text("Today's Earnings"), findsOneWidget);
    expect(find.text('Buy Credits'), findsOneWidget);
    expect(find.text('Manage Plan'), findsOneWidget);
    expect(find.text('View Reports'), findsOneWidget);

    // 4. Incoming Requests section
    expect(find.text('Incoming Requests'), findsOneWidget);
    expect(find.text('QUOTE SENT'), findsOneWidget);
    expect(find.text('View / Edit Quote'), findsOneWidget);

    // 5. Active Negotiations section
    expect(find.text('Active Negotiations'), findsOneWidget);

    // 6. Upcoming Orders section
    expect(find.text('Upcoming Orders'), findsOneWidget);
    expect(find.text('No Upcoming Orders'), findsOneWidget);
  });

  testWidgets('SupplierHomePage shows clean empty states when leads and offers are empty',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final supplierRepo = Get.find<SupplierRepository>() as _FakeSupplierRepo;
    supplierRepo.returnEmpty = true;

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierHomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Clean empty state for incoming requests
    expect(find.text('No Incoming Requests'), findsOneWidget);

    // Clean empty state for active negotiations
    expect(find.text('No Active Negotiations'), findsOneWidget);

    // Clean empty state for upcoming orders
    expect(find.text('No Upcoming Orders'), findsOneWidget);
  });

  testWidgets(
      'SupplierHomePage renders active upcoming orders when present',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final ordersRepo = Get.find<OrdersRepository>() as _FakeOrdersRepo;
    ordersRepo.orders = [
      Order(
        id: 'ord_12345678',
        offerId: 'off_1',
        requestId: 'lead_1',
        buyerId: 'buy_1',
        supplierId: 'supp_1',
        totalPence: 1245000,
        status: OrderStatus.placed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        offer: const OrderOfferRef(
          id: 'off_1',
          pricePence: 1245000,
          quantity: 1,
        ),
        request: const OrderRequestRef(
          id: 'lead_1',
          partName: 'BMW Dual-Clutch Transmission',
          regNumber: 'AB12 CDE',
        ),
        events: const [],
      ),
    ];

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierHomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Upcoming orders section renders the order
    expect(find.text('Upcoming Orders'), findsOneWidget);
    expect(find.text('Manage Order'), findsOneWidget);
    expect(find.text('Order #345678'), findsOneWidget);
    expect(find.text('BMW Dual-Clutch Transmission'), findsOneWidget);
  });
}

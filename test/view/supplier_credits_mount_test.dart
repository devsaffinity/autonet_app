import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:autonect/view/screens/supplier/dash_board/supplier_credits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeBillingRepo implements BillingRepository {
  List<Map<String, dynamic>> returnLedger = [];

  @override
  Future<ApiResult<Map<String, dynamic>>> wallet() async => Ok({
        'credits': 50,
        'hasActiveSubscription': false,
        'subscription': null,
        'ledger': returnLedger,
      });

  @override
  Future<ApiResult<List<BillingPlan>>> plans() async => const Ok([]);

  @override
  Future<ApiResult<Map<String, dynamic>>> subscribe(String lookupKey) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<Map<String, dynamic>>> purchaseCredits(String lookupKey) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<Map<String, dynamic>>> cancelSubscription() =>
      throw UnimplementedError();
}

class _StubSupplierRepo implements SupplierRepository {
  @override
  Future<ApiResult<SupplierDashboardData>> dashboard() async => const Ok(
        SupplierDashboardData(
          incomingRequests: 5,
          activeNegotiations: 2,
          creditBalance: 50,
          subscribed: false,
          todaysEarningsPence: 0,
        ),
      );

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
      const Ok(
        Paged(
          [],
          PageMeta(
            page: 1,
            limit: 20,
            pageSize: 0,
            total: 0,
            totalPages: 0,
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
      const Ok(
        Paged(
          [],
          PageMeta(
            page: 1,
            limit: 20,
            pageSize: 0,
            total: 0,
            totalPages: 0,
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

class _StubOrdersRepo implements OrdersRepository {
  @override
  Future<ApiResult<Order>> acceptOffer({
    required String offerId,
    String? deliveryLocation,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<Order>> byId(String orderId) =>
      throw UnimplementedError();

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
      const Ok(
        Paged(
          [],
          PageMeta(
            page: 1,
            limit: 20,
            pageSize: 0,
            total: 0,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        ),
      );

  @override
  Future<ApiResult<Paged<Offer>>> buyerOffers({
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<List<Offer>>> offersForRequest(String requestId) =>
      throw UnimplementedError();
}

void main() {
  late _FakeBillingRepo fakeBilling;

  setUp(() {
    Get.reset();
    fakeBilling = _FakeBillingRepo();
    final stubSupplier = _StubSupplierRepo();
    final stubOrders = _StubOrdersRepo();

    Get.put<BillingRepository>(fakeBilling);
    Get.put<SupplierRepository>(stubSupplier);
    Get.put<OrdersRepository>(stubOrders);

    Get.put<SupplierHomeController>(
      SupplierHomeController(stubSupplier, stubOrders),
    );
  });

  tearDown(() => Get.reset());

  testWidgets('SupplierCreditsPage mounts and displays empty state when ledger is empty',
      (tester) async {
    fakeBilling.returnLedger = [];

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierCreditsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AVAILABLE CREDITS'), findsOneWidget);
    expect(find.text('Credit Ledger'), findsOneWidget);
    expect(find.text('No credit transactions yet'), findsOneWidget);
    expect(find.text('Buy Credits & Manage Plans'), findsOneWidget);
  });

  testWidgets('SupplierCreditsPage displays live ledger transactions when populated',
      (tester) async {
    fakeBilling.returnLedger = [
      {
        'id': 'led_1',
        'delta': 50,
        'reason': 'PURCHASE',
        'balanceAfter': 50,
        'at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'led_2',
        'delta': -1,
        'reason': 'LEAD',
        'balanceAfter': 49,
        'at': DateTime.now().toIso8601String(),
      },
    ];

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierCreditsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AVAILABLE CREDITS'), findsOneWidget);
    expect(find.text('Credit purchase'), findsOneWidget);
    expect(find.text('+50'), findsOneWidget);
    expect(find.text('Lead unlock'), findsOneWidget);
    expect(find.text('-1'), findsOneWidget);
  });
}

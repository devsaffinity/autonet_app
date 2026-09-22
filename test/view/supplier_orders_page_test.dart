import 'package:autonect/controller/supplier/supplier_orders_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_orders.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

Order _testOrder({
  required String id,
  required OrderStatus status,
  String partName = 'Front Brake Pads',
}) =>
    Order(
      id: id,
      offerId: 'off_1',
      requestId: 'req_1',
      buyerId: 'usr_buyer',
      supplierId: 'usr_sup1',
      totalPence: 8500,
      status: status,
      createdAt: DateTime(2026, 9, 22, 10),
      updatedAt: DateTime(2026, 9, 22, 10),
      offer: const OrderOfferRef(id: 'off_1', pricePence: 8500, quantity: 1),
      request: OrderRequestRef(
        id: 'req_1',
        partName: partName,
        regNumber: 'AB12CDE',
      ),
      events: const [],
    );

Ok<Paged<Order>> _paged(List<Order> items, {required int total}) => Ok(
      Paged<Order>(
        items,
        PageMeta(
          page: 1,
          limit: 20,
          pageSize: items.length,
          total: total,
          totalPages: total == 0 ? 0 : 1,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      ),
    );

void main() {
  late FakeOrdersRepository repo;

  void register(FakeOrdersRepository r) {
    repo = r;
    Get.put<OrdersRepository>(r);
    Get.put<SupplierOrdersController>(
      SupplierOrdersController(
        r,
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      ),
    );
  }

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(
      const GetMaterialApp(
        home: SupplierOrdersPage(),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('renders empty state when there are no active orders (no crash/grey screen)', (t) async {
    register(
      FakeOrdersRepository()
        ..listResult = _paged(const [], total: 0),
    );

    await pump(t);

    expect(find.text('Customer Orders'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('No active orders yet'), findsOneWidget);
    expect(
      find.text('Orders requiring fulfillment will appear here once accepted.'),
      findsOneWidget,
    );
    // Ensure no ErrorWidget (grey screen of death)
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('renders order card when active orders exist', (t) async {
    final order = _testOrder(id: 'ord_12345678', status: OrderStatus.placed);
    register(
      FakeOrdersRepository()
        ..listResult = _paged([order], total: 1),
    );

    await pump(t);

    expect(find.text('Customer Orders'), findsOneWidget);
    expect(find.text('Order #345678'), findsOneWidget);
    expect(find.text('Front Brake Pads'), findsOneWidget);
    expect(find.byType(SupplierListRow), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('switching tabs loads corresponding empty state without crashing', (t) async {
    register(
      FakeOrdersRepository()
        ..listQueue.addAll([
          _paged(const [], total: 0), // Active tab initial load
          _paged(const [], total: 0), // Delivered tab
          _paged(const [], total: 0), // Cancelled tab
        ]),
    );

    await pump(t);
    expect(find.text('No active orders yet'), findsOneWidget);

    // Tap Delivered tab
    await t.tap(find.text('Delivered'));
    await t.pumpAndSettle();
    expect(find.text('No delivered orders yet'), findsOneWidget);
    expect(
      find.text('Delivered orders will be archived here once completed.'),
      findsOneWidget,
    );
    expect(find.byType(ErrorWidget), findsNothing);

    // Tap Cancelled tab
    await t.tap(find.text('Cancelled'));
    await t.pumpAndSettle();
    expect(find.text('No cancelled orders yet'), findsOneWidget);
    expect(find.text('Cancelled orders will appear here.'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('renders failure state on error and retries successfully', (t) async {
    register(
      FakeOrdersRepository()
        ..listQueue.add(
          const Err(
            ApiError(
              code: ApiErrorCode.internal,
              statusCode: 500,
              message: 'Server error occurred',
            ),
          ),
        )
        ..listQueue.add(
          _paged(
            [_testOrder(id: 'ord_999999', status: OrderStatus.preparing)],
            total: 1,
          ),
        ),
    );

    await pump(t);

    expect(find.text('Unable to load orders'), findsOneWidget);
    expect(find.text('Server error occurred'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);

    // Tap Retry
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();

    expect(find.text('Order #999999'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
  });
}

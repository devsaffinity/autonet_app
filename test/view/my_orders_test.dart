import 'dart:async';

import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/my_orders_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/view/screens/buyer/orders/my_orders.dart';
import 'package:autonect/view/widget/choice_chips_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// The status chips are this screen's ONLY control, and the controller is a
/// Get singleton behind an IndexedStack, so a filter outlives both the screen
/// and the tab. If the chips can vanish in any of the four states, the buyer
/// is locked into whatever they last tapped until they kill the app. Every
/// test below therefore asserts the chips are still on screen.
Order _order(String id, OrderStatus status) => Order(
      id: id,
      offerId: 'off_1',
      requestId: 'req_1',
      buyerId: 'usr_buyer',
      supplierId: 'usr_sup1',
      totalPence: 12999,
      status: status,
      // Local, not UTC: the row formats through toLocal(), so a UTC fixture
      // would print the previous day on a machine far enough west.
      createdAt: DateTime(2026, 9, 2, 9),
      updatedAt: DateTime(2026, 9, 2, 9),
      offer: const OrderOfferRef(id: 'off_1', pricePence: 12999, quantity: 1),
      request: const OrderRequestRef(
          id: 'req_1', partName: 'Front brake discs', regNumber: 'LM19XYZ'),
      events: const [],
    );

Ok<Paged<Order>> _page(List<Order> items, {required int total}) => Ok(
      Paged<Order>(
          items,
          PageMeta(page: 1, limit: 20, pageSize: items.length, total: total,
              totalPages: 1, hasNextPage: false, hasPreviousPage: false)),
    );

/// A first page that never answers — the only honest way to hold the screen in
/// its Loading state.
class _HangingRepository extends FakeOrdersRepository {
  @override
  Future<ApiResult<Paged<Order>>> list(
          {int page = 1, int limit = 20, OrderStatus? status}) =>
      Completer<ApiResult<Paged<Order>>>().future;
}

/// Present in all four states means present as this widget, not merely as the
/// word 'Cancelled' that an order row's badge also paints.
Finder get _chips => find.byType(ChoiceChipsField<OrderStatus?>);

void main() {
  late FakeOrdersRepository repo;

  void register(FakeOrdersRepository r) {
    repo = r;
    // The injected no-ops let this run with no Fluttertoast platform channel
    // and no modal loading dialog.
    Get.put<MyOrdersController>(MyOrdersController(r,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));
  }

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(const GetMaterialApp(home: MyOrdersPage()));
    await t.pumpAndSettle();
  }

  testWidgets('filtering to a status with no orders keeps the chips on screen',
      (t) async {
    register(FakeOrdersRepository()
      ..listQueue.add(_page([_order('ord_1', OrderStatus.placed)], total: 1))
      ..listQueue.add(_page(const [], total: 0)));
    await pump(t);
    expect(find.text('Front brake discs'), findsOneWidget);

    await t.tap(find.text('Cancelled'));
    await t.pumpAndSettle();

    expect(repo.calls.last, 'list:1:20:CANCELLED');
    expect(find.text('Nothing here yet'), findsOneWidget);
    // The bug this test exists for: the chips used to ride in PagedListView's
    // header slot, which only paints in the Data arm, so an empty result took
    // the whole row away and left no route back to 'All'.
    expect(_chips, findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('and the buyer can still get back out to All', (t) async {
    register(FakeOrdersRepository()
      ..listQueue.add(_page(const [], total: 0))
      ..listQueue.add(_page(const [], total: 0))
      ..listQueue.add(_page([_order('ord_1', OrderStatus.placed)], total: 1)));
    await pump(t);
    await t.tap(find.text('Cancelled'));
    await t.pumpAndSettle();

    await t.tap(find.text('All'));
    await t.pumpAndSettle();

    expect(repo.calls.last, 'list:1:20:null');
    expect(find.text('Front brake discs'), findsOneWidget);
  });

  testWidgets('a network failure keeps the chips beside the retry button',
      (t) async {
    register(FakeOrdersRepository()..listResult = const Err(ApiError.network()));
    await pump(t);
    expect(find.text('Try again'), findsOneWidget);
    expect(_chips, findsOneWidget);
  });

  testWidgets('an unanswered first page keeps the chips above the spinner',
      (t) async {
    register(_HangingRepository());
    await t.pumpWidget(const GetMaterialApp(home: MyOrdersPage()));
    await t.pump();
    expect(find.byType(DiscreteCircleLoading), findsOneWidget);
    expect(_chips, findsOneWidget);
  });

  testWidgets('a loaded page renders the row, its price and the chips',
      (t) async {
    register(FakeOrdersRepository()
      ..listQueue.add(_page([_order('ord_1', OrderStatus.delivered)], total: 1)));
    await pump(t);
    expect(find.text('Front brake discs'), findsOneWidget);
    expect(find.text('LM19XYZ'), findsOneWidget);
    expect(find.text('2026-09-02'), findsOneWidget);
    // Once as the chip, once as the row's status badge.
    expect(find.text('Delivered'), findsNWidgets(2));
    expect(_chips, findsOneWidget);
  });
}

import 'package:autonect/controller/buyer/order_detail_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/view/screens/buyer/detail/order_status.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// The two things this screen must never get wrong are both gates: a buyer may
/// cancel ONLY at PLACED, and may review ONLY after DELIVERED. The old screen
/// had the review guard commented out and no cancel control at all, so every
/// tap on it bought a 409 or a 403.
void main() {
  final at = DateTime.utc(2026, 9, 3, 9, 15);

  Order orderWith(OrderStatus status, List<OrderStatus> evented) => Order(
        id: 'o1',
        offerId: 'of1',
        requestId: 'r1',
        buyerId: 'b1',
        supplierId: 's1',
        totalPence: 24000,
        status: status,
        createdAt: at,
        updatedAt: at,
        offer: const OrderOfferRef(id: 'of1', pricePence: 24000, quantity: 1),
        request: const OrderRequestRef(
            id: 'r1', partName: 'Front Brake Pads', regNumber: 'AB12CDE'),
        events: [
          for (var i = 0; i < evented.length; i++)
            OrderEvent(
                id: 'e$i',
                orderId: 'o1',
                status: evented[i],
                at: at.add(Duration(minutes: i))),
        ],
      );

  /// A real controller over the in-memory repository: the gates under test are
  /// the controller's, and stubbing them would test nothing.
  Future<void> pump(WidgetTester t, Order order) async {
    final repo = FakeOrdersRepository()..byIdResult = Ok(order);
    Get.put<OrderDetailController>(OrderDetailController(repo,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));
    await t.pumpWidget(const GetMaterialApp(home: OrderStatusPage(orderId: 'o1')));
    await t.pumpAndSettle();
  }

  MyButton buttonNamed(WidgetTester t, String text) => t.widget<MyButton>(
      find.byWidgetPredicate((w) => w is MyButton && w.buttonText == text));

  tearDown(Get.reset);

  testWidgets('PLACED offers cancel and withholds the review CTA', (t) async {
    await pump(t, orderWith(OrderStatus.placed, [OrderStatus.placed]));
    expect(find.text('Cancel order'), findsOneWidget);
    expect(find.text('Give Review'), findsNothing);
  });

  testWidgets('DELIVERED offers the review CTA and withholds cancel', (t) async {
    await pump(t, orderWith(OrderStatus.delivered, OrderStatus.forwardPath));
    expect(find.text('Give Review'), findsOneWidget);
    // A buyer may never cancel past PLACED; the server answers 403/409 anyway.
    expect(find.text('Cancel order'), findsNothing);
  });

  testWidgets('CANCELLED renders a cancellation row, not a stuck Preparing',
      (t) async {
    await pump(t, orderWith(OrderStatus.cancelled,
        [OrderStatus.placed, OrderStatus.cancelled]));
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    // The old screen's frozen literals left 'Preparing Order' on screen forever.
    expect(find.text('Preparing Order'), findsNothing);
    expect(find.text('Cancel order'), findsNothing);
  });

  testWidgets('an admin jump to DELIVERED renders two skipped rows', (t) async {
    // PLACED -> DELIVERED with no events between is reachable through
    // admin-marketplace.routes.ts, so those rows never happened.
    await pump(t, orderWith(OrderStatus.delivered, [OrderStatus.placed]));
    expect(find.byIcon(Icons.remove_rounded), findsNWidgets(2));
    expect(find.text('Not recorded'), findsNWidgets(2));
    // ...and exactly one tick, for the step that DID happen.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('the cancel dialog will not submit an empty note', (t) async {
    await pump(t, orderWith(OrderStatus.placed, [OrderStatus.placed]));
    await t.tap(find.text('Cancel order'));
    await t.pumpAndSettle();

    // A CANCELLED with no note is a guaranteed 400 the repository refuses to
    // send, so the button must be inert before it is ever pressed.
    expect(buttonNamed(t, 'Confirm cancellation').enabled, isFalse);

    await t.enterText(find.byType(TextField).first, 'Found it locally');
    await t.pumpAndSettle();
    expect(buttonNamed(t, 'Confirm cancellation').enabled, isTrue);
  });
}

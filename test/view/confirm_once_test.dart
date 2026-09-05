import 'package:autonect/controller/buyer/order_detail_controller.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/view/screens/buyer/detail/order_status.dart';
import 'package:autonect/view/screens/buyer/request/request_detail.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// TWO TAPS INSIDE ONE FRAME.
///
/// `tester.tap` does not pump, so two of them in a row are exactly that: both
/// reach the callback the LAST build handed the InkWell, because nothing has
/// rebuilt in between. Neither `enabled` nor `loading` can help — both are read
/// at build time — so a confirm-style button needs a guard that lives in the
/// tap itself.
///
/// The harm is never the same twice: a button that OPENS a dialog opens two of
/// them, one stacked under the other over an order already cancelled; a sheet
/// CTA that signs out or spends credits does it twice.
Order _order(OrderStatus status) => Order.fromJson({
  'id': 'ord_1',
  'offerId': 'off_1',
  'requestId': 'req_1',
  'buyerId': 'usr_buyer',
  'supplierId': 'usr_sup1',
  'totalPence': 12999,
  'status': status.wire,
  'createdAt': '2026-09-02T09:00:00.000Z',
  'updatedAt': '2026-09-02T09:00:00.000Z',
  'offer': {'id': 'off_1', 'pricePence': 12999, 'quantity': 1},
  'request': {
    'id': 'req_1',
    'partName': 'Front brake discs',
    'regNumber': 'LM19XYZ',
  },
  'events': <Object?>[],
});

PartRequest _request() => PartRequest.fromJson({
  'id': 'req_1',
  'buyerId': 'usr_buyer',
  'regNumber': 'LM19XYZ',
  'categoryId': 'cat_brakes',
  'partName': 'Front brake discs',
  'status': 'OPEN',
  'offerCount': 0,
  'createdAt': '2026-09-01T10:15:00.000Z',
  'updatedAt': '2026-09-01T10:15:00.000Z',
  'category': {'id': 'cat_brakes', 'name': 'Brakes'},
  'images': <Object?>[],
});

/// Twice with NO pump between: the double tap this whole file is about.
Future<void> tapTwice(WidgetTester t, Finder f) async {
  await t.tap(f);
  await t.tap(f, warnIfMissed: false);
}

MyButton buttonNamed(WidgetTester t, String text) =>
    t.widget<MyButton>(find.widgetWithText(MyButton, text).last);

void main() {
  tearDown(Get.reset);

  testWidgets('a one-shot MyButton fires once, a plain one still fires twice',
      (t) async {
    var once = 0, plain = 0;
    await t.pumpWidget(MaterialApp(
      home: Column(children: [
        MyButton(buttonText: 'Confirm', oneShot: true, onTap: () => once++),
        MyButton(buttonText: 'Filter', onTap: () => plain++),
      ]),
    ));

    await tapTwice(t, find.text('Confirm'));
    await tapTwice(t, find.text('Filter'));
    await t.pump();

    expect(once, 1);
    // The guard is opt-in for a reason: a button that re-runs a query or
    // re-opens a sheet must go on working.
    expect(plain, 2);
  });

  testWidgets('every sheet CTA is one-shot', (t) async {
    var taps = 0;
    await t.pumpWidget(GetMaterialApp(
      home: MyBSheet(
        btnText: 'Withdraw Offer',
        onTap: () => taps++,
        body: const SizedBox.shrink(),
      ),
    ));

    await tapTwice(t, find.text('Withdraw Offer'));
    await t.pump();

    // One button, eleven sheets: withdraw an offer, spend two credits, sign
    // out, 'Back to Bookings'. None of them may happen twice.
    expect(taps, 1);
  });

  testWidgets('a double-tapped Cancel order opens ONE dialog and cancels once',
      (t) async {
    final repo = FakeOrdersRepository()
      ..byIdResult = Ok(_order(OrderStatus.placed))
      ..changeStatusResult = Ok(_order(OrderStatus.cancelled));
    Get.put<OrderDetailController>(OrderDetailController(repo,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));
    await t.pumpWidget(
        const GetMaterialApp(home: OrderStatusPage(orderId: 'ord_1')));
    await t.pumpAndSettle();

    await tapTwice(t, find.text('Cancel order'));
    await t.pumpAndSettle();

    // Two dialogs, and answering the top one leaves the second sitting over an
    // order the server has already cancelled, still offering to cancel it.
    expect(find.text('Cancel this order?'), findsOneWidget);
    // Both buttons in it pop, so both are one-shot.
    expect(buttonNamed(t, 'Confirm cancellation').oneShot, isTrue);
    expect(buttonNamed(t, 'Keep order').oneShot, isTrue);

    await t.enterText(find.byType(TextField), 'Ordered the wrong side');
    await t.pump();
    await tapTwice(t, find.text('Confirm cancellation'));
    await t.pumpAndSettle();

    expect(repo.patchCalls, 1);
    expect(find.byType(OrderStatusPage), findsOneWidget);
    expect(find.text('Cancel this order?'), findsNothing);
  });

  testWidgets('a double-tapped Close request opens ONE dialog', (t) async {
    Get.put<RequestDetailController>(RequestDetailController(
      FakeRequestsRepository()..byIdResult = Ok(_request()),
      FakeOrdersRepository()..offersResult = const Ok([]),
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    ));
    await t.pumpWidget(const GetMaterialApp(
        home: BuyerRequestDetailPage(requestId: 'req_1')));
    await t.pumpAndSettle();

    await tapTwice(t, find.text('Close request'));
    await t.pumpAndSettle();

    // 'Close request' names the page button AND the dialog's title and confirm
    // button, so a single dialog shows it three times and a second shows five.
    expect(find.text('Close request'), findsNWidgets(3));
    // Both of the dialog's buttons pop with an answer, so both are one-shot —
    // the page button behind them is NOT, because a close that fails must be
    // offerable again.
    expect(buttonNamed(t, 'Close request').oneShot, isTrue);
    expect(buttonNamed(t, 'Keep it open').oneShot, isTrue);
    expect(t.widgetList<MyButton>(find.widgetWithText(MyButton, 'Close request'))
        .first.oneShot, isFalse);
  });
}

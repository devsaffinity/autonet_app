import 'dart:async';

import 'package:autonect/controller/buyer/accept_offer_controller.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/view/screens/buyer/detail/comparison.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// RequestDetailController is a Get SINGLETON, so it survives the screen. The
/// bug this file pins: ComparisonPage only loaded when the singleton's id
/// DIFFERED from the pushed request, which made re-opening the SAME request —
/// the one case a buyer re-opens because its row now says '3 offers' — the one
/// case that could never refetch. There is no other route to a fresh list from
/// this screen: onRetry only paints in StateView's Failed arm, and
/// refreshIfStale no-ops unless an accept just happened.
Offer _offer(String id) => Offer(
  id: id,
  requestId: 'req_1',
  supplierId: 'sup_$id',
  pricePence: 12999,
  quantity: 1,
  status: OfferStatus.pending,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
  supplier: OfferSupplier(id: 'sup_$id', businessName: 'Supplier $id'),
);

PartRequest _request(int offerCount,
        {RequestStatus status = RequestStatus.open}) =>
    PartRequest.fromJson({
  'id': 'req_1', 'buyerId': 'usr_buyer', 'regNumber': 'LM19XYZ',
  'categoryId': 'cat_brakes', 'partName': 'Front brake discs',
  'status': status.wire, 'offerCount': offerCount,
  'createdAt': '2026-09-01T10:15:00.000Z',
  'updatedAt': '2026-09-01T10:15:00.000Z',
  'category': {'id': 'cat_brakes', 'name': 'Brakes'},
  'images': <Object?>[],
});

/// The base fake answers `byId` immediately, which cannot express 'the offers
/// painted first and the server's copy of the request landed afterwards'.
class _GatedRequests extends FakeRequestsRepository {
  Completer<ApiResult<PartRequest>>? gate;

  @override
  Future<ApiResult<PartRequest>> byId(String id) {
    if (gate == null) return super.byId(id);
    calls.add('byId:$id');
    return gate!.future;
  }
}

/// The base fake has one `offersResult`, which cannot express 'a third
/// supplier answered between the two visits' — the whole scenario.
class _QueuedOffers extends FakeOrdersRepository {
  final List<ApiResult<List<Offer>>> offersQueue = [];

  @override
  Future<ApiResult<List<Offer>>> offersForRequest(String requestId) async {
    calls.add('offers:$requestId');
    if (offersQueue.isNotEmpty) return offersQueue.removeAt(0);
    return super.offersForRequest(requestId);
  }
}

void main() {
  late _GatedRequests requests;
  late _QueuedOffers orders;

  setUp(() {
    Get.testMode = true;
    requests = _GatedRequests();
    orders = _QueuedOffers();
    Get.put(RequestDetailController(requests, orders,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));
    Get.put(AcceptOfferController(orders,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));
  });

  tearDown(Get.reset);

  int offerReads() => orders.calls.where((c) => c == 'offers:req_1').length;

  /// A real push and pop. Re-pumping the same widget tree would REUSE the
  /// State and never call initState twice, so it could not tell the fixed
  /// screen from the broken one.
  Widget launcher(PartRequest r) => Scaffold(
        body: Builder(
          builder: (_) => TextButton(
            onPressed: () => Get.to(() => ComparisonPage(request: r)),
            child: const Text('open'),
          ),
        ),
      );

  testWidgets('re-opening the SAME request refetches its offers', (t) async {
    final pushed = _request(2);
    requests.byIdResult = Ok(_request(3));
    orders.offersQueue.add(Ok([_offer('a'), _offer('b')]));
    orders.offersQueue.add(Ok([_offer('a'), _offer('b'), _offer('c')]));

    await t.pumpWidget(GetMaterialApp(home: launcher(pushed)));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('2 offers'), findsOneWidget);

    Get.back();
    await t.pumpAndSettle();

    // Same request id, same singleton — and a third supplier has since offered.
    await t.tap(find.text('open'));
    await t.pumpAndSettle();

    expect(offerReads(), 2);
    // The header used to keep saying '2 offers' while the list row that led
    // here said 3.
    expect(find.text('3 offers'), findsOneWidget);
    expect(find.text('2 offers'), findsNothing);
  });

  testWidgets('pull-to-refresh refetches without leaving the screen', (t) async {
    requests.byIdResult = Ok(_request(2));
    orders.offersQueue.add(Ok([_offer('a')]));
    orders.offersQueue.add(Ok([_offer('a'), _offer('b')]));

    await t.pumpWidget(GetMaterialApp(home: ComparisonPage(request: _request(1))));
    await t.pumpAndSettle();
    expect(find.text('1 offer'), findsOneWidget);

    await t.fling(find.byType(ListView), const Offset(0, 320), 1000);
    await t.pumpAndSettle();

    expect(offerReads(), 2);
    expect(find.text('2 offers'), findsOneWidget);
  });

  testWidgets('the refreshed list never blanks the rows already on screen',
      (t) async {
    requests.byIdResult = Ok(_request(1));
    orders.offersQueue.add(Ok([_offer('a')]));
    orders.offersQueue.add(Ok([_offer('a')]));

    await t.pumpWidget(GetMaterialApp(home: ComparisonPage(request: _request(1))));
    await t.pumpAndSettle();

    await t.fling(find.byType(ListView), const Offset(0, 320), 1000);
    // Mid-gesture, before the refetch settles: a spinner where the list was,
    // under the RefreshIndicator's own spinner, would be two indicators for
    // one wait, which is why _refresh does not go through load().
    await t.pump();
    expect(find.text('Supplier a'), findsOneWidget);
    await t.pumpAndSettle();
    expect(offerReads(), 2);
    expect(find.text('Supplier a'), findsOneWidget);
  });

  /// `liveRequest()` used to be read inside `_body`, which runs inside
  /// StateView.build — outside the Obx closure's tracking zone — so it
  /// registered NO dependency on `c.request`. The cards then judged
  /// acceptability against the request the screen was PUSHED with and never
  /// re-evaluated, leaving a closed request advertising a walkable path.
  testWidgets('a request arriving CLOSED re-judges the cards already drawn',
      (t) async {
    final gate = Completer<ApiResult<PartRequest>>();
    requests.gate = gate;
    orders.offersQueue.add(Ok([_offer('a')]));

    await t.pumpWidget(
        GetMaterialApp(home: ComparisonPage(request: _request(1))));
    await t.pumpAndSettle();

    // The offers have painted while the request read is still in flight.
    expect(find.text('Supplier a'), findsOneWidget);
    expect(find.text('Closed'), findsNothing);
    expect(
        t.widget<MyButton>(find.widgetWithText(MyButton, 'View offer')).enabled,
        isTrue);

    gate.complete(Ok(_request(1, status: RequestStatus.closed)));
    await t.pumpAndSettle();

    expect(find.text('Closed'), findsOneWidget);
    expect(
        t.widget<MyButton>(find.widgetWithText(MyButton, 'View offer')).enabled,
        isFalse);
  });
}

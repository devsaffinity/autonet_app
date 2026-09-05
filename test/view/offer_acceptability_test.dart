import 'package:autonect/controller/buyer/accept_offer_controller.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/controller/buyer/review_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/view/screens/buyer/detail/comparison.dart';
import 'package:autonect/view/screens/buyer/detail/offer_detail.dart';
import 'package:autonect/view/screens/buyer/detail/order_summary.dart';
import 'package:autonect/view/screens/buyer/detail/report.dart';
import 'package:autonect/view/screens/buyer/request/request_detail.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// `GET /v1/requests/{id}/offers` returns every non-WITHDRAWN offer, so these
/// three screens have to tell a dead row from a live one themselves. What each
/// test asserts is the absence of a WALKABLE PATH, not merely a greyer pixel.
Offer _offer(String id, OfferStatus status) => Offer(
  id: id,
  requestId: 'req_1',
  supplierId: 'sup_1',
  pricePence: 12999,
  quantity: 1,
  status: status,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
  supplier: const OfferSupplier(id: 'sup_1', businessName: 'Midlands Motors'),
);

PartRequest _request(RequestStatus status) => PartRequest.fromJson({
  'id': 'req_1', 'buyerId': 'usr_buyer', 'regNumber': 'LM19XYZ',
  'categoryId': 'cat_brakes', 'partName': 'Front brake discs',
  'status': status.wire, 'offerCount': 1,
  'createdAt': '2026-09-01T10:15:00.000Z',
  'updatedAt': '2026-09-01T10:15:00.000Z',
  'category': {'id': 'cat_brakes', 'name': 'Brakes'},
  'images': <Object?>[],
});

void main() {
  late FakeRequestsRepository requests;
  late FakeOrdersRepository orders;

  setUp(() {
    Get.testMode = true;
    requests = FakeRequestsRepository();
    orders = FakeOrdersRepository();
    // The three injected no-ops let this run with no Fluttertoast platform
    // channel and no modal loading dialog.
    Get.put(RequestDetailController(requests, orders,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));
    Get.put(AcceptOfferController(orders,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));
    Get.put(ReviewController(FakeReviewsRepository(),
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));
  });

  tearDown(Get.reset);

  /// [served] is what the SERVER says, [pushed] what the screen was pushed
  /// with — the two disagree the moment an accept lands.
  Future<void> pumpComparison(
    WidgetTester t, {
    required PartRequest pushed,
    required PartRequest served,
    required List<Offer> offers,
  }) async {
    requests.byIdResult = Ok(served);
    orders.offersResult = Ok(offers);
    await t.pumpWidget(GetMaterialApp(home: ComparisonPage(request: pushed)));
    await t.pumpAndSettle();
  }

  MyButton buttonNamed(WidgetTester t, String text) =>
      t.widget<MyButton>(find.widgetWithText(MyButton, text).first);

  testWidgets('a REJECTED offer renders no path to OrderSummaryPage',
      (t) async {
    final open = _request(RequestStatus.open);
    await pumpComparison(t,
        pushed: open, served: open, offers: [_offer('off_1', OfferStatus.rejected)]);

    expect(find.text('Rejected'), findsOneWidget);
    expect(
        find.text(
            'This offer closed when another offer on this request was accepted.'),
        findsOneWidget);
    expect(buttonNamed(t, 'View offer').enabled, isFalse);

    await t.tap(find.text('View offer'));
    await t.pumpAndSettle();
    expect(find.byType(OfferDetailPage), findsNothing);
    expect(find.byType(OrderSummaryPage), findsNothing);
  });

  testWidgets('an offer on a CLOSED request renders no path to OrderSummaryPage',
      (t) async {
    // Pushed while the request was OPEN, closed by the accept the buyer made
    // on another offer — symptom (b), pressing back after accepting.
    await pumpComparison(t,
        pushed: _request(RequestStatus.open),
        served: _request(RequestStatus.closed),
        offers: [_offer('off_1', OfferStatus.pending)]);

    expect(find.text('Closed'), findsOneWidget);
    expect(buttonNamed(t, 'View offer').enabled, isFalse);

    await t.tap(find.text('View offer'));
    await t.pumpAndSettle();
    expect(find.byType(OfferDetailPage), findsNothing);
    expect(find.byType(OrderSummaryPage), findsNothing);
  });

  testWidgets('a CANCELLED request blocks offers the server left PENDING',
      (t) async {
    // closeOrCancel moves only the request, so every offer under it still
    // reads PENDING and only the request status can disqualify them.
    final cancelled = _request(RequestStatus.cancelled);
    await pumpComparison(t,
        pushed: cancelled,
        served: cancelled,
        offers: [_offer('off_1', OfferStatus.pending)]);

    expect(find.text('Cancelled'), findsOneWidget);
    expect(buttonNamed(t, 'View offer').enabled, isFalse);
  });

  testWidgets('a live offer still walks the whole way to Place Order',
      (t) async {
    final open = _request(RequestStatus.open);
    await pumpComparison(t,
        pushed: open, served: open, offers: [_offer('off_1', OfferStatus.pending)]);

    expect(buttonNamed(t, 'View offer').enabled, isTrue);
    await t.tap(find.text('View offer'));
    await t.pumpAndSettle();
    expect(find.byType(OfferDetailPage), findsOneWidget);

    expect(buttonNamed(t, 'Confirm Offer').enabled, isTrue);
    await t.tap(find.text('Confirm Offer'));
    await t.pumpAndSettle();
    expect(find.byType(OrderSummaryPage), findsOneWidget);
    expect(buttonNamed(t, 'Place Order').enabled, isTrue);
  });

  testWidgets("the dead 'Select' button is gone from every card", (t) async {
    final open = _request(RequestStatus.open);
    await pumpComparison(t, pushed: open, served: open, offers: [
      _offer('off_1', OfferStatus.pending),
      _offer('off_2', OfferStatus.pending),
    ]);
    // It wrote a field nothing read; an unwired control is worse than none.
    expect(find.text('Select'), findsNothing);
    expect(find.text('Selected'), findsNothing);
    expect(find.widgetWithText(MyButton, 'View offer'), findsNWidgets(2));
  });

  testWidgets('OfferDetailPage refuses to confirm an ACCEPTED offer',
      (t) async {
    // Reached directly, as report.dart and request_detail.dart both do.
    requests.byIdResult = Ok(_request(RequestStatus.closed));
    orders.offersResult = Ok([_offer('off_1', OfferStatus.accepted)]);
    await t.pumpWidget(GetMaterialApp(
      home: OfferDetailPage(
          offer: _offer('off_1', OfferStatus.accepted),
          request: _request(RequestStatus.closed)),
    ));
    await t.pumpAndSettle();

    expect(find.text('You have already accepted this offer.'), findsOneWidget);
    expect(buttonNamed(t, 'Confirm Offer').enabled, isFalse);
    await t.tap(find.text('Confirm Offer'));
    await t.pumpAndSettle();
    expect(find.byType(OrderSummaryPage), findsNothing);
  });

  /// The supplier withdrew this offer a second before the buyer tapped, so the
  /// server answers the actionable 409 rather than an order.
  Future<void> conflictOn(String offerId) async {
    orders.acceptResult = const Err(ApiError(
        code: ApiErrorCode.conflict,
        statusCode: 409,
        message: 'Offer is no longer acceptable'));
    await Get.find<AcceptOfferController>().accept(offerId: offerId);
  }

  Future<void> pumpSummary(WidgetTester t, Offer offer, PartRequest r) async {
    await t.pumpWidget(
        GetMaterialApp(home: OrderSummaryPage(offer: offer, request: r)));
    await t.pumpAndSettle();
  }

  testWidgets('a refetch after an actionable 409 re-opens Place Order',
      (t) async {
    final detail = Get.find<RequestDetailController>();
    final accept = Get.find<AcceptOfferController>();
    final open = _request(RequestStatus.open);
    final live = _offer('off_2', OfferStatus.pending);
    requests.byIdResult = Ok(open);
    orders.offersResult = Ok([live]);
    await detail.load('req_1');

    await conflictOn('off_1');
    expect(accept.shouldRefetch, isTrue, reason: 'precondition');

    // The buyer takes the copy's advice — 'here are the offers still open' —
    // and goes back to the list, which refetches on the way in.
    requests.byIdResult = Ok(open);
    orders.offersResult = Ok([live]);
    await detail.refreshIfStale(accept);
    expect(accept.conflict.value, isNull,
        reason: 'the refetch releases the latch; the disabled button cannot');

    // A different, still-PENDING offer on a still-OPEN request. Before this
    // fix the latch outlived the screen and shut this button forever.
    await pumpSummary(t, live, open);
    expect(buttonNamed(t, 'Place Order').enabled, isTrue);
  });

  testWidgets("one offer's 409 never disables Place Order on another",
      (t) async {
    // report.dart and request_detail.dart push an offer without going back
    // through a list, so no refetch happens on this route at all.
    await conflictOn('off_1');
    await pumpSummary(t, _offer('off_2', OfferStatus.pending),
        _request(RequestStatus.open));

    expect(buttonNamed(t, 'Place Order').enabled, isTrue);
    expect(
        find.text(
            'That offer is no longer available. Here are the offers still open.'),
        findsNothing);
  });

  testWidgets('a REJECTED offer on the report renders no path onward',
      (t) async {
    await t.pumpWidget(GetMaterialApp(
      home: ComparisonReportPage(
          request: _request(RequestStatus.open),
          offers: [_offer('off_1', OfferStatus.rejected)]),
    ));
    await t.pumpAndSettle();

    expect(find.text('Rejected'), findsOneWidget);
    expect(
        find.text(
            'This offer closed when another offer on this request was accepted.'),
        findsOneWidget);
    // A dead row is neither the lowest nor the fastest thing on offer.
    expect(find.text('Lowest'), findsNothing);
    expect(find.text('Fastest'), findsNothing);
    expect(buttonNamed(t, 'View offer').enabled, isFalse);

    await t.tap(find.text('View offer'));
    await t.pumpAndSettle();
    expect(find.byType(OfferDetailPage), findsNothing);
  });

  /// The header, its two terminal actions and the offers beneath them do not
  /// fit 600 logical pixels, and a row a lazy sliver never laid out cannot be
  /// tapped — which would pass this test for the wrong reason.
  void tallSurface(WidgetTester t) {
    t.view.physicalSize = const Size(1200, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  testWidgets('request_detail states an offer on a CLOSED request and stops',
      (t) async {
    tallSurface(t);
    // closeOrCancel moves only the request: the offer is still PENDING and the
    // row has nothing but the request status to disqualify it.
    requests.byIdResult = Ok(_request(RequestStatus.closed));
    orders.offersResult = Ok([_offer('off_1', OfferStatus.pending)]);
    await t.pumpWidget(
        const GetMaterialApp(home: BuyerRequestDetailPage(requestId: 'req_1')));
    await t.pumpAndSettle();

    // Once on the header, once on the row — the row used to say nothing.
    expect(find.text('Closed'), findsNWidgets(2));
    expect(
        find.text('This request is no longer open, so its offers can no longer '
            'be accepted.'),
        findsOneWidget);

    await t.tap(find.text('Midlands Motors'));
    await t.pumpAndSettle();
    expect(find.byType(OfferDetailPage), findsNothing);
  });

  testWidgets('a live row in request_detail still opens the offer', (t) async {
    tallSurface(t);
    requests.byIdResult = Ok(_request(RequestStatus.open));
    orders.offersResult = Ok([_offer('off_1', OfferStatus.pending)]);
    await t.pumpWidget(
        const GetMaterialApp(home: BuyerRequestDetailPage(requestId: 'req_1')));
    await t.pumpAndSettle();

    await t.tap(find.text('Midlands Motors'));
    await t.pumpAndSettle();
    expect(find.byType(OfferDetailPage), findsOneWidget);
  });

  testWidgets('OrderSummaryPage guards Place Order in depth', (t) async {
    // Nothing should reach here on a dead offer; if something does, the last
    // gate still refuses rather than spending a guaranteed 409.
    await t.pumpWidget(GetMaterialApp(
      home: OrderSummaryPage(
          offer: _offer('off_1', OfferStatus.rejected),
          request: _request(RequestStatus.open)),
    ));
    await t.pumpAndSettle();
    expect(buttonNamed(t, 'Place Order').enabled, isFalse);
    expect(orders.calls, isEmpty);
  });
}

import 'package:autonect/controller/buyer/accept_offer_controller.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/conflict_kind.dart';
import 'package:autonect/domain/offer_actionability.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_buyer_repositories.dart';

Offer _offer(OfferStatus status) => Offer(
  id: 'off_1',
  requestId: 'req_1',
  supplierId: 'sup_1',
  pricePence: 12999,
  quantity: 1,
  status: status,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
  supplier: const OfferSupplier(id: 'sup_1'),
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

Ok<Order> _order() => Ok(Order.fromJson({
  'id': 'ord_1', 'offerId': 'off_1', 'requestId': 'req_1',
  'buyerId': 'usr_buyer', 'supplierId': 'sup_1', 'totalPence': 12999,
  'status': 'PLACED', 'createdAt': '2026-09-02T09:00:00.000Z',
  'updatedAt': '2026-09-02T09:00:00.000Z',
  'offer': {'id': 'off_1', 'pricePence': 12999, 'quantity': 1},
  'request': {'id': 'req_1', 'partName': 'Front brake discs',
      'regNumber': 'LM19XYZ'},
  'events': <Object?>[],
}));

Err<Order> _conflict(String message) =>
    Err(ApiError(code: ApiErrorCode.conflict, statusCode: 409, message: message));

int _countOf(List<String> calls, String prefix) =>
    calls.where((c) => c.startsWith(prefix)).length;

void main() {
  late FakeOrdersRepository orders;
  late FakeRequestsRepository requests;
  late AcceptOfferController accept;
  late RequestDetailController detail;

  setUp(() {
    orders = FakeOrdersRepository();
    requests = FakeRequestsRepository();
    accept = AcceptOfferController(orders,
        toast: (_) {}, showBusy: () {}, hideBusy: () {});
    detail = RequestDetailController(requests, orders,
        toast: (_) {}, showBusy: () {}, hideBusy: () {});
  });

  group('accept', () {
    test('a success marks the mounted list stale', () async {
      orders.acceptResult = _order();
      final r = await accept.accept(offerId: 'off_1');
      expect(r.valueOrNull, isNotNull);
      // Nothing else can say so: the buyer is sent no notification of their
      // OWN accept, and the sibling REJECTs happen in the same transaction.
      expect(accept.requestStale.value, isTrue);
      expect(accept.conflict.value, isNull);
      expect(accept.shouldRefetch, isFalse);
    });

    test('the location passes through untouched — trimming is the repo\'s job',
        () async {
      orders.acceptResult = _order();
      await accept.accept(offerId: 'off_1', deliveryLocation: '  ');
      expect(orders.calls.single, 'accept:off_1:  ');
    });

    test("the 'no longer acceptable' 409 is actionable", () async {
      orders.acceptResult = _conflict('Offer is no longer acceptable');
      await accept.accept(offerId: 'off_1');
      expect(accept.conflict.value, ConflictKind.offerNotAcceptable);
      expect(accept.shouldRefetch, isTrue);
      expect(accept.requestStale.value, isTrue);
      expect(accept.formError.value,
          'That offer is no longer available. Here are the offers still open.');
    });

    test("the 'already has an accepted offer' 409 is actionable", () async {
      orders.acceptResult =
          _conflict('Request already has an accepted offer');
      await accept.accept(offerId: 'off_1');
      expect(accept.conflict.value, ConflictKind.requestAlreadyAccepted);
      expect(accept.shouldRefetch, isTrue);
      expect(accept.formError.value,
          'You have already accepted an offer on this request.');
    });

    test('a non-409 failure leaves the list alone', () async {
      orders.acceptResult = const Err(ApiError.network());
      await accept.accept(offerId: 'off_1');
      expect(accept.requestStale.value, isFalse);
      expect(accept.conflict.value, isNull);
    });
  });

  group('the conflict latch always has a way out', () {
    Future<void> conflictOn(String offerId) async {
      orders.acceptResult = _conflict('Offer is no longer acceptable');
      await accept.accept(offerId: offerId);
      expect(accept.shouldRefetch, isTrue, reason: 'precondition');
    }

    test('a refetch releases it — the ONLY escape the buyer walks into',
        () async {
      requests.byIdResult = Ok(_request(RequestStatus.open));
      orders.offersResult = Ok([_offer(OfferStatus.pending)]);
      await detail.load('req_1');
      await conflictOn('off_1');

      // What every offers screen does on the way back from a detail push. The
      // latch used to be cleared ONLY inside accept(), which is behind the
      // button `shouldRefetch` disables — so nothing could ever clear it.
      requests.byIdResult = Ok(_request(RequestStatus.open));
      orders.offersResult = Ok([_offer(OfferStatus.pending)]);
      await detail.refreshIfStale(accept);

      expect(accept.conflict.value, isNull);
      expect(accept.shouldRefetch, isFalse);
    });

    test('opening a DIFFERENT offer releases it, refetch or no refetch',
        () async {
      await conflictOn('off_1');
      // report.dart and request_detail.dart push an offer without passing back
      // through a list, so they have no refetch to offer.
      accept.beginOffer('off_2');
      expect(accept.shouldRefetch, isFalse);
      expect(accept.formError.value, isNull,
          reason: "off_1's copy must not appear under off_2's field");
    });

    test('re-opening the SAME offer keeps it — that 409 is still true',
        () async {
      await conflictOn('off_1');
      accept.beginOffer('off_1');
      expect(accept.conflict.value, ConflictKind.offerNotAcceptable);
      expect(accept.shouldRefetch, isTrue);
    });

    test('a success releases it before the next offer is ever opened',
        () async {
      await conflictOn('off_1');
      orders.acceptResult = _order();
      await accept.accept(offerId: 'off_2');
      expect(accept.conflict.value, isNull);
      // ...and the offer that owned it is forgotten with it, so re-entering
      // off_1 does not resurrect a latch nothing is holding.
      accept.beginOffer('off_1');
      expect(accept.shouldRefetch, isFalse);
    });
  });

  group('refreshIfStale', () {
    Future<void> loadOpenWithPending() async {
      requests.byIdResult = Ok(_request(RequestStatus.open));
      orders.offersResult = Ok([_offer(OfferStatus.pending)]);
      await detail.load('req_1');
    }

    test('does nothing while the list is not stale', () async {
      await loadOpenWithPending();
      await detail.refreshIfStale(accept);
      expect(_countOf(requests.calls, 'byId:'), 1);
      expect(_countOf(orders.calls, 'offers:'), 1);
    });

    test('a stale flag triggers exactly ONE refetch, then resets', () async {
      await loadOpenWithPending();
      // What the server holds after the accept the buyer just made.
      requests.byIdResult = Ok(_request(RequestStatus.closed));
      orders.offersResult = Ok([_offer(OfferStatus.accepted)]);
      accept.requestStale.value = true;

      await detail.refreshIfStale(accept);
      expect(_countOf(requests.calls, 'byId:'), 2);
      expect(_countOf(orders.calls, 'offers:'), 2);
      expect(accept.requestStale.value, isFalse);

      // Every screen still on the stack calls this on the way back out; only
      // the first may spend a request, or the 300/60s limiter pays for it.
      await detail.refreshIfStale(accept);
      await detail.refreshIfStale(accept);
      expect(_countOf(requests.calls, 'byId:'), 2);
      expect(_countOf(orders.calls, 'offers:'), 2);
    });

    test('the refetch is what flips acceptability for a mounted screen',
        () async {
      await loadOpenWithPending();
      final held = _offer(OfferStatus.pending), heldRequest = detail.liveRequest(
          _request(RequestStatus.open));
      expect(canAcceptOffer(detail.liveOffer(held), heldRequest), isTrue);

      requests.byIdResult = Ok(_request(RequestStatus.closed));
      orders.offersResult = Ok([_offer(OfferStatus.rejected)]);
      accept.requestStale.value = true;
      await detail.refreshIfStale(accept);

      // The screen still holds the PENDING/OPEN pair it was pushed with; the
      // live lookup is what stops it walking into a guaranteed 409.
      expect(detail.liveOffer(held).status, OfferStatus.rejected);
      expect(detail.liveRequest(heldRequest).status, RequestStatus.closed);
      expect(
        canAcceptOffer(detail.liveOffer(held), detail.liveRequest(heldRequest)),
        isFalse,
      );
    });

    /// The 409 that closed Place Order on off_1, then the refetch the buyer's
    /// pop pays for — and it does not land.
    Future<void> conflictThenFailedRefetch() async {
      await loadOpenWithPending();
      orders.acceptResult = _conflict('Offer is no longer acceptable');
      await accept.accept(offerId: 'off_1');
      expect(accept.shouldRefetch, isTrue, reason: 'precondition');

      requests.byIdResult = const Err(ApiError.network());
      orders.offersResult = const Err(ApiError.network());
      await detail.refreshIfStale(accept);
    }

    test('a FAILED refetch does NOT re-arm the offer the server refused',
        () async {
      final held = _offer(OfferStatus.pending),
          heldRequest = _request(RequestStatus.open);
      await conflictThenFailedRefetch();

      // Nothing landed, so liveOffer/liveRequest fall back to the PENDING/OPEN
      // pair the screen was pushed with — which still LOOKS acceptable. Releasing
      // the latch on a refetch that failed is therefore the screen handing Place
      // Order back on an offer the server has already refused.
      expect(
        canAcceptOffer(detail.liveOffer(held), detail.liveRequest(heldRequest)),
        isTrue,
        reason: 'the stale pair is exactly why the latch must survive',
      );
      expect(accept.shouldRefetch, isTrue);
      expect(accept.formError.value, isNotNull, reason: 'and it still says why');
    });

    test('...and the retry is still reachable — the flag went back', () async {
      await conflictThenFailedRefetch();
      expect(accept.requestStale.value, isTrue,
          reason: 'the next screen popping must pay for another attempt');

      requests.byIdResult = Ok(_request(RequestStatus.closed));
      orders.offersResult = Ok([_offer(OfferStatus.rejected)]);
      await detail.refreshIfStale(accept);
      expect(accept.shouldRefetch, isFalse);
      expect(accept.requestStale.value, isFalse);
    });

    test('...and opening any other offer escapes with no network at all',
        () async {
      await conflictThenFailedRefetch();
      accept.beginOffer('off_2');
      expect(accept.shouldRefetch, isFalse);
      expect(accept.formError.value, isNull);
    });

    test('liveOffer falls back when the row is gone from the list', () async {
      await loadOpenWithPending();
      final stranger = Offer(
        id: 'off_gone', requestId: 'req_1', supplierId: 'sup_2',
        pricePence: 1, quantity: 1, status: OfferStatus.pending,
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
        supplier: const OfferSupplier(id: 'sup_2'),
      );
      expect(identical(detail.liveOffer(stranger), stranger), isTrue);
    });
  });
}

import 'dart:async';

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/controller/buyer/buyer_home_controller.dart';
import 'package:autonect/controller/buyer/catalog_controller.dart';
import 'package:autonect/controller/buyer/order_detail_controller.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/controller/buyer/review_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_buyer_repositories.dart';

/// THE LATE ANSWER. `beginEntity` resets what a controller holds SYNCHRONOUSLY
/// at dispatch; every test here is about the other half — the read that was
/// already in flight for entity A and answers a moment after B is on screen.
///
/// Each is the same shape: dispatch A, dispatch B, let B answer, then let A
/// answer LATE, and require that the screen still shows B. The second shape is
/// the sibling bug: two overlapping reads must never produce a Failed state at
/// all, because the one they used to produce — `run`'s dropped re-entry —
/// carried ApiErrorCode.unknown and so rendered with NO 'Try again' on it.
Order _order(String id, {String status = 'PLACED'}) => Order.fromJson({
  'id': id, 'offerId': 'off_1', 'requestId': 'req_1', 'buyerId': 'usr_buyer',
  'supplierId': 'usr_sup1', 'totalPence': 12999, 'status': status,
  'createdAt': '2026-09-02T09:00:00.000Z',
  'updatedAt': '2026-09-02T09:00:00.000Z',
  'offer': {'id': 'off_1', 'pricePence': 12999, 'quantity': 1},
  'request': {'id': 'req_1', 'partName': id, 'regNumber': 'LM19XYZ'},
  'events': <Object?>[],
});

PartRequest _request(String id, {String status = 'OPEN'}) =>
    PartRequest.fromJson({
  'id': id, 'buyerId': 'usr_buyer', 'regNumber': 'LM19XYZ',
  'categoryId': 'cat_brakes', 'partName': id, 'status': status,
  'offerCount': 0, 'createdAt': '2026-09-01T10:15:00.000Z',
  'updatedAt': '2026-09-01T10:15:00.000Z',
  'category': {'id': 'cat_brakes', 'name': 'Brakes'},
  'images': <Object?>[],
});

Ok<Paged<PartRequest>> _page(String id) =>
    Ok(Paged<PartRequest>([_request(id)], _meta(1)));

PageMeta _meta(int total) => PageMeta(page: 1, limit: 20, pageSize: total,
    total: total, totalPages: 1, hasNextPage: false, hasPreviousPage: false);

ReviewsPage _reviews(double average) => ReviewsPage(
  items: const <Review>[], meta: _meta(1),
  summary: ReviewsSummary(average: average, counts: const {5: 1}),
);

/// One completer per call, so a test decides WHEN — and in what order — each
/// read answers. Nothing else can express 'A answers after B'.
class _Gate<T> {
  final List<Completer<ApiResult<T>>> pending = [];

  Future<ApiResult<T>> open() {
    final c = Completer<ApiResult<T>>();
    pending.add(c);
    return c.future;
  }

  void answer(int i, ApiResult<T> r) => pending[i].complete(r);
}

class _GatedOrders extends FakeOrdersRepository {
  final _Gate<Order> byIdGate = _Gate<Order>();

  @override
  Future<ApiResult<Order>> byId(String id) {
    calls.add('byId:$id');
    return byIdGate.open();
  }
}

class _GatedRequests extends FakeRequestsRepository {
  final _Gate<PartRequest> byIdGate = _Gate<PartRequest>();
  final _Gate<Paged<PartRequest>> listGate = _Gate<Paged<PartRequest>>();

  @override
  Future<ApiResult<PartRequest>> byId(String id) {
    calls.add('byId:$id');
    return byIdGate.open();
  }

  @override
  Future<ApiResult<Paged<PartRequest>>> listMine(
      {int page = 1, int limit = 20, RequestStatus? status, String? q}) {
    calls.add('listMine:$page');
    return listGate.open();
  }
}

class _GatedReviews extends FakeReviewsRepository {
  final _Gate<ReviewsPage> gate = _Gate<ReviewsPage>();

  @override
  Future<ApiResult<ReviewsPage>> forTarget(
      {required String targetId, int page = 1, int limit = 20}) {
    calls.add('forTarget:$targetId');
    return gate.open();
  }
}

class _GatedCatalog extends FakeCatalogRepository {
  final _Gate<List<PartCategory>> gate = _Gate<List<PartCategory>>();

  @override
  Future<ApiResult<List<PartCategory>>> categories({
    bool forceRefresh = false,
  }) {
    calls.add('categories:$forceRefresh');
    return gate.open();
  }
}

/// The close write held open, so a second tap lands while the first is out.
class _GatedCloses extends _GatedRequests {
  final _Gate<PartRequest> closeGate = _Gate<PartRequest>();

  @override
  Future<ApiResult<PartRequest>> closeOrCancel(String id, CloseAction action) {
    calls.add('close:$id:${action.wire}');
    return closeGate.open();
  }
}

/// `run`'s drop contract, with no repository in the way: it MUST still drop,
/// because it is the double-submit guard on login, signup, OTP and Place Order.
class _Probe extends ApiController {
  _Probe() : super(toast: _swallow, showBusy: _nothing, hideBusy: _nothing);

  static void _swallow(String _) {}
  static void _nothing() {}

  static const StateSlot _slot = StateSlot('probe');

  final Completer<ApiResult<int>> gate = Completer<ApiResult<int>>();
  int calls = 0;

  /// Every answer that reached the slot, in order.
  final List<String> published = [];

  Future<ApiResult<int>> attempt() => run<int, ApiResult<int>>(null, () {
    calls++;
    return gate.future;
  }, (r) => r);

  /// The same guard, for a write that also PUBLISHES what it gets back.
  Future<bool> claimAndPublish(String label) => runWrite<int, bool>(_slot, () {
    calls++;
    return gate.future;
  }, (r, claim) => claim.publish(() => published.add(label)));
}

/// Lets every already-scheduled microtask run before the next assertion.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('run STILL drops a second write, and the drop is never a dead end',
      () async {
    final p = _Probe();
    final first = p.attempt();
    final dropped = await p.attempt();

    expect(p.calls, 1, reason: 'the double-submit guard must not regress');
    expect(dropped.errorOrNull, same(droppedReentry));
    // The guard is right; the dead panel it used to paint was not. A caller
    // that turns this into Failed now gets a 'Try again' rather than a screen
    // whose only escape is leaving it.
    expect(isRetryable(dropped.errorOrNull!), isTrue);
    p.gate.complete(const Ok(1));
    await first;
  });

  test('a DROPPED write claims nothing, so the one in flight still publishes',
      () async {
    final p = _Probe();
    final first = p.claimAndPublish('first');
    final dropped = await p.claimAndPublish('second');

    expect(p.calls, 1, reason: 'the double-submit guard must not regress');
    expect(dropped, isFalse, reason: 'a dropped write publishes nothing');

    p.gate.complete(const Ok(1));
    // The claim used to be taken BEFORE the drop decision, so the tap that was
    // then thrown away had already bumped the slot — and this answer, which
    // came from the one PATCH the server did receive, was discarded as
    // superseded by a call that never left the device.
    expect(await first, isTrue);
    expect(p.published, ['first']);
  });

  group('OrderDetailController', () {
    late _GatedOrders repo;
    late OrderDetailController c;

    setUp(() {
      repo = _GatedOrders();
      c = OrderDetailController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {});
    });

    test("order A's answer never lands on order B", () async {
      final a = c.load('ord_a');
      final b = c.load('ord_b');
      expect(repo.byIdGate.pending.length, 2,
          reason: "B's read must be ISSUED, not dropped");

      repo.byIdGate.answer(1, Ok(_order('ord_b')));
      await b;
      await _settle();
      repo.byIdGate.answer(0, Ok(_order('ord_a')));
      await a;

      // Before the claim, A's late answer replaced B here — and with it the
      // part name, the status badge, the stepper, and the Cancel/Review gates,
      // while a cancel from that screen still PATCHed B.
      expect(switch (c.order.value) {
        Data<Order>(:final value) => value.id,
        _ => null,
      }, 'ord_b');
    });

    test("A's late FAILURE never paints an error panel over B", () async {
      final seen = <ViewState<Order>>[];
      c.order.listen(seen.add);
      final a = c.load('ord_a');
      final b = c.load('ord_b');

      repo.byIdGate.answer(1, Ok(_order('ord_b')));
      await b;
      await _settle();
      repo.byIdGate.answer(0, const Err(ApiError.network()));
      await a;

      // A superseded answer is discarded WHOLE — its error as much as its rows.
      // Blanking B's order for a network error on a read of A is the same lie
      // told with a different widget, and it takes B's stepper down with it.
      expect(seen, everyElement(isNot(isA<Failed<Order>>())));
      expect(c.order.value, isA<Data<Order>>(),
          reason: 'and nothing is left spinning');
    });

    test('a cancel is not undone by the read it superseded', () async {
      final load = c.load('ord_a');
      repo.changeStatusResult = Ok(_order('ord_a', status: 'CANCELLED'));

      expect(await c.cancel('Ordered the wrong side'), isTrue);
      // The GET was dispatched BEFORE the PATCH, so its body predates the
      // cancel. Applying it would put the order back to PLACED and re-arm the
      // Cancel button on an order the server has already cancelled.
      repo.byIdGate.answer(0, Ok(_order('ord_a')));
      await load;

      expect(c.status, OrderStatus.cancelled);
      expect(c.canCancel, isFalse);
    });
  });

  group('RequestDetailController', () {
    late _GatedRequests requests;
    late FakeOrdersRepository orders;
    late RequestDetailController c;

    setUp(() {
      requests = _GatedRequests();
      orders = FakeOrdersRepository()..offersResult = const Ok([]);
      c = RequestDetailController(requests, orders,
          toast: (_) {}, showBusy: () {}, hideBusy: () {});
    });

    test("request A's header never lands over request B's offers", () async {
      final a = c.load('req_a');
      final b = c.load('req_b');

      requests.byIdGate.answer(1, Ok(_request('req_b')));
      await b;
      await _settle();
      requests.byIdGate.answer(0, Ok(_request('req_a')));
      await a;

      // Each offer row gates its Accept on canAcceptOffer(offer, request), so
      // A's header judging B's offers is a live offer made inert, or a dead one
      // left tappable — not merely the wrong title.
      expect(c.requestOrNull?.id, 'req_b');
      expect(c.requestId, 'req_b');
    });

    test('the two reads never supersede EACH OTHER', () async {
      final pending = c.load('req_a');
      // Offers answered synchronously from the fake, the header is still out.
      await _settle();
      requests.byIdGate.answer(0, Ok(_request('req_a')));
      await pending;

      // One counter for both slots would have discarded the header here, and
      // the screen would have sat on a spinner that nothing could ever fill.
      expect(c.requestOrNull?.id, 'req_a');
      expect(c.offers.value, isA<Empty<List<Offer>>>());
    });
  });

  group('two closes inside one frame', () {
    late _GatedCloses requests;
    late RequestDetailController c;

    /// The screen as it really is when Close is tapped: the header read is out
    /// and [RequestDetailController.request] is on Loading until it answers.
    Future<void> load() async {
      requests = _GatedCloses();
      c = RequestDetailController(
          requests, FakeOrdersRepository()..offersResult = const Ok([]),
          toast: (_) {}, showBusy: () {}, hideBusy: () {});
      unawaited(c.load('req_a'));
      await _settle();
      expect(c.request.value, isA<Loading<PartRequest>>(), reason: 'setup');
    }

    test('ONE patch, and the closed request reaches the header', () async {
      await load();
      final first = c.close(CloseAction.close);
      final second = c.close(CloseAction.close);

      expect(requests.closeGate.pending.length, 1,
          reason: 'the second PATCH must still be dropped');
      expect(await second, isFalse);

      requests.closeGate.answer(0, Ok(_request('req_a', status: 'CLOSED')));
      expect(await first, isTrue);
      expect(c.requestOrNull?.status?.wire, 'CLOSED');
    });

    test('a close that publishes NOTHING is not a permanent spinner', () async {
      await load();
      final first = c.close(CloseAction.close);
      final second = c.close(CloseAction.close);
      expect(await second, isFalse);

      // Every failure branch of close() writes formError and nothing else, so
      // the slot this write took from the header read is left unfilled.
      requests.closeGate.answer(0, const Err(ApiError.network()));
      expect(await first, isFalse);

      // Released, that header read is current again and still lands. Held, it
      // was discarded on arrival and the screen kept a spinner that nothing
      // remaining could ever replace.
      requests.byIdGate.answer(0, Ok(_request('req_a')));
      await _settle();
      expect(c.request.value, isA<Data<PartRequest>>());
    });
  });

  group('ReviewController', () {
    late _GatedReviews repo;
    late ReviewController c;

    setUp(() {
      repo = _GatedReviews();
      c = ReviewController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {});
    });

    test("supplier B's tab ends on B's reviews, never A's", () async {
      final seen = <ViewState<ReviewsPage>>[];
      c.supplierReviews.listen(seen.add);
      final a = c.loadReviews('sup_a');
      final b = c.loadReviews('sup_b');

      // Through run() this was BOTH failures at once: B's read was dropped as a
      // re-entry — so `forTarget` was called once — and the drop painted a
      // non-retryable 'Please wait' panel, after which A's answer arrived under
      // B's name.
      expect(repo.calls, ['forTarget:sup_a', 'forTarget:sup_b']);
      expect(seen, everyElement(isNot(isA<Failed<ReviewsPage>>())));

      repo.gate.answer(1, Ok(_reviews(3.0)));
      await b;
      await _settle();
      repo.gate.answer(0, Ok(_reviews(4.5)));
      await a;

      expect(switch (c.supplierReviews.value) {
        Data<ReviewsPage>(:final value) => value.summary.average,
        _ => null,
      }, 3.0);
      expect(seen, everyElement(isNot(isA<Failed<ReviewsPage>>())));
    });
  });

  test('buyer home: a pull-to-refresh mid-load is never a dead panel',
      () async {
    final repo = _GatedRequests();
    final c = BuyerHomeController(repo,
        toast: (_) {}, showBusy: () {}, hideBusy: () {});
    final seen = <ViewState<List<PartRequest>>>[];
    c.activeRequests.listen(seen.add);

    final first = c.load();
    final refresh = c.load();
    expect(repo.listGate.pending.length, 2);

    // The REFRESH answers first and the initial load answers late, which is the
    // ordering that puts yesterday's rows under a list the buyer just pulled.
    repo.listGate.answer(1, _page('req_b'));
    await refresh;
    await _settle();
    repo.listGate.answer(0, _page('req_a'));
    await first;

    expect(seen, everyElement(isNot(isA<Failed<List<PartRequest>>>())));
    expect(switch (c.activeRequests.value) {
      Data<List<PartRequest>>(:final value) => value.single.id,
      _ => null,
    }, 'req_b');
  });

  test('catalog: Try again mid-load is never a dead panel', () async {
    final repo = _GatedCatalog();
    final c = CatalogController(repo,
        toast: (_) {}, showBusy: () {}, hideBusy: () {});
    final seen = <ViewState<List<PartCategory>>>[];
    c.categories.listen(seen.add);

    final first = c.load();
    final retry = c.load(forceRefresh: true);

    // This controller is permanent, so the dropped retry's non-retryable panel
    // outlived the sheet that showed it: nothing left on screen could refetch.
    expect(repo.calls, ['categories:false', 'categories:true']);
    repo.gate.answer(1, const Ok([PartCategory(id: 'c2', name: 'Clutch')]));
    await retry;
    await _settle();
    repo.gate.answer(0, const Ok([PartCategory(id: 'c1', name: 'Brakes')]));
    await first;

    expect(seen, everyElement(isNot(isA<Failed<List<PartCategory>>>())));
    expect(c.all.single.id, 'c2');
  });
}

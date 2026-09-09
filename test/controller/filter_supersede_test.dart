import 'dart:async';

import 'package:autonect/controller/buyer/my_orders_controller.dart';
import 'package:autonect/controller/buyer/my_requests_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_buyer_repositories.dart';

/// Double-tapping across a chip row is an ordinary gesture, and until the
/// generation counter landed it was unrecoverable: ApiController.run DROPPED
/// the second tap as a re-entry, the drop became a NON-retryable 'Please wait
/// for the current action to finish.', and the first response then painted
/// filter X's rows underneath filter Y's highlighted chip. The invariant these
/// tests pin is that the rendered rows always belong to the selected filter.
Order _order(String id, OrderStatus status) => Order(
  id: id,
  offerId: 'off_1',
  requestId: 'req_1',
  buyerId: 'usr_buyer',
  supplierId: 'usr_sup1',
  totalPence: 12999,
  status: status,
  createdAt: DateTime(2026, 9, 2, 9),
  updatedAt: DateTime(2026, 9, 2, 9),
  offer: const OrderOfferRef(id: 'off_1', pricePence: 12999, quantity: 1),
  request: const OrderRequestRef(
      id: 'req_1', partName: 'Front brake discs', regNumber: 'LM19XYZ'),
  events: const [],
);

PartRequest _req(String id) => PartRequest.fromJson({
  'id': id, 'buyerId': 'usr_buyer', 'regNumber': 'LM19XYZ',
  'categoryId': 'cat_brakes', 'partName': 'Front brake discs',
  'status': 'OPEN', 'offerCount': 0,
  'createdAt': '2026-09-01T10:15:00.000Z',
  'updatedAt': '2026-09-01T10:15:00.000Z',
  'category': {'id': 'cat_brakes', 'name': 'Brakes'},
  'images': <Object?>[],
});

PageMeta _meta(int n) => PageMeta(page: 1, limit: 20, pageSize: n, total: n,
    totalPages: 1, hasNextPage: false, hasPreviousPage: false);

/// A cursor-bearing meta: these tests assert on `_page`/`hasMore` after a
/// discard, which a page-1-only helper cannot express.
PageMeta _metaAt({required int page, required int total, required bool hasNext,
        int size = 2}) =>
    PageMeta(page: page, limit: 20, pageSize: size, total: total,
        totalPages: hasNext ? page + 1 : page,
        hasNextPage: hasNext, hasPreviousPage: page > 1);

Ok<Paged<Order>> _ordersPage(List<String> ids,
        {required int page, required int total, required bool hasNext}) =>
    Ok(Paged<Order>([for (final id in ids) _order(id, OrderStatus.placed)],
        _metaAt(page: page, total: total, hasNext: hasNext, size: ids.length)));

/// Hands back a Completer per call so a test decides WHEN each page-1 read
/// answers. Nothing else can express 'a second tap while the first is still in
/// flight', which is the entire bug.
class _GatedOrders extends FakeOrdersRepository {
  final List<Completer<ApiResult<Paged<Order>>>> pending = [];

  @override
  Future<ApiResult<Paged<Order>>> list(
      {int page = 1, int limit = 20, OrderStatus? status}) {
    calls.add('list:$page:$limit:${status?.wire}');
    final c = Completer<ApiResult<Paged<Order>>>();
    pending.add(c);
    return c.future;
  }
}

class _GatedRequests extends FakeRequestsRepository {
  final List<Completer<ApiResult<Paged<PartRequest>>>> pending = [];

  @override
  Future<ApiResult<Paged<PartRequest>>> listMine(
      {int page = 1, int limit = 20, RequestStatus? status, String? q}) {
    calls.add('listMine:$page:$limit:${status?.wire}');
    final c = Completer<ApiResult<Paged<PartRequest>>>();
    pending.add(c);
    return c.future;
  }
}

List<String> _ids(ViewState<List<Order>> s) => switch (s) {
  Data<List<Order>>(:final value) => [for (final o in value) o.id],
  _ => const [],
};

/// Lets every already-scheduled microtask — the queued re-issue included —
/// run before the next assertion.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _GatedOrders repo;
  late MyOrdersController c;
  late List<ViewState<List<Order>>> seen;

  setUp(() {
    repo = _GatedOrders();
    c = MyOrdersController(repo, toast: (_) {}, showBusy: () {}, hideBusy: () {});
    seen = [];
    c.state.listen(seen.add);
  });

  test('the LAST chip tapped is the one whose rows render', () async {
    final first = c.setFilter(OrderStatus.placed);
    // Synchronously inside the first read: run() holds busy, and it is exactly
    // here that the old code returned the dropped-re-entry error.
    final second = c.setFilter(OrderStatus.cancelled);
    expect(repo.pending.length, 1, reason: 'the second tap must not dispatch yet');
    expect(c.state.value, isA<Loading<List<Order>>>());

    repo.pending[0].complete(
        Ok(Paged<Order>([_order('ord_placed', OrderStatus.placed)], _meta(1))));
    await first;
    await _settle();

    // PLACED's rows are the superseded answer; painting them under the
    // CANCELLED chip is the lie this whole fix exists to prevent.
    expect(_ids(c.state.value), isEmpty);
    expect(repo.calls, ['list:1:20:PLACED', 'list:1:20:CANCELLED']);

    repo.pending[1].complete(Ok(
        Paged<Order>([_order('ord_cancelled', OrderStatus.cancelled)], _meta(1))));
    await second;

    expect(_ids(c.state.value), ['ord_cancelled']);
    expect(c.filter.value, OrderStatus.cancelled);
  });

  test('a superseded response NEVER overwrites the newer state', () async {
    final first = c.setFilter(OrderStatus.placed);
    final second = c.setFilter(OrderStatus.cancelled);

    repo.pending[0].complete(
        Ok(Paged<Order>([_order('ord_placed', OrderStatus.placed)], _meta(1))));
    await first;
    await _settle();

    // Asserted HERE, before the newer read is allowed to answer: every state
    // this list has ever held, and PLACED's row is in none of them.
    expect([for (final s in seen) _ids(s)],
        everyElement(isNot(contains('ord_placed'))));

    repo.pending[1].complete(Ok(
        Paged<Order>([_order('ord_cancelled', OrderStatus.cancelled)], _meta(1))));
    await second;
    expect(_ids(c.state.value), ['ord_cancelled']);
  });

  test('a filter change shows no dead error state', () async {
    final first = c.setFilter(OrderStatus.placed);
    final second = c.setFilter(OrderStatus.cancelled);

    // 'Please wait for the current action to finish.' carried
    // ApiErrorCode.unknown, which failure_copy renders WITHOUT a Try again —
    // a dead end the buyer could only leave by tapping another chip. It landed
    // on the second tap itself, so this assertion belongs right here.
    expect(seen, everyElement(isNot(isA<Failed<List<Order>>>())));

    repo.pending[0].complete(Ok(Paged<Order>(const [], _meta(0))));
    await first;
    await _settle();
    repo.pending[1].complete(Ok(Paged<Order>(const [], _meta(0))));
    await second;

    expect(seen, everyElement(isNot(isA<Failed<List<Order>>>())));
    expect(c.state.value, isA<Empty<List<Order>>>());
  });

  test('the rows on screen never outlive the chip that fetched them', () async {
    final first = c.setFilter(OrderStatus.placed);
    repo.pending[0]
        .complete(Ok(Paged<Order>([_order('a', OrderStatus.placed)], _meta(1))));
    await first;
    expect(_ids(c.state.value), ['a']);

    // The chip moves: PLACED's rows must go NOW, not when CANCELLED answers.
    final second = c.setFilter(OrderStatus.cancelled);
    expect(_ids(c.state.value), isEmpty);
    expect(c.state.value, isA<Loading<List<Order>>>());

    repo.pending[1]
        .complete(Ok(Paged<Order>([_order('b', OrderStatus.cancelled)], _meta(1))));
    await second;
    expect(_ids(c.state.value), ['b']);
  });

  test('MyRequestsController supersedes the same way', () async {
    final repo = _GatedRequests();
    final r = MyRequestsController(repo,
        toast: (_) {}, showBusy: () {}, hideBusy: () {});

    final first = r.setFilter(RequestStatus.open);
    final second = r.setFilter(RequestStatus.closed);
    expect(repo.pending.length, 1);

    repo.pending[0].complete(
        Ok(Paged<PartRequest>([_req('req_open')], _meta(1))));
    await first;
    await _settle();
    // The CLOSED read the dropped tap never issued.
    expect(repo.pending.length, 2);

    repo.pending[1].complete(
        Ok(Paged<PartRequest>([_req('req_closed')], _meta(1))));
    await second;

    expect(r.state.value, isA<Data<List<PartRequest>>>());
    expect(switch (r.state.value) {
      Data<List<PartRequest>>(:final value) => value.single.id,
      _ => null,
    }, 'req_closed');
    expect(repo.calls, ['listMine:1:20:OPEN', 'listMine:1:20:CLOSED']);
  });

  /// Page 2 is read asynchronously exactly like page 1, so it can answer after
  /// the chip has moved. Before the generation guard reached loadMore, that
  /// answer was applied verbatim: the previous filter's rows were APPENDED
  /// under the newly highlighted chip and `_page`/`_meta` became the old
  /// filter's, a cursor no further scrolling could repair.
  group('a page-2 read superseded in flight', () {
    /// The abandoned ALL-page-2 read, still unanswered.
    late Future<void> stale;

    /// ALL page 1 on screen, ALL page 2 dispatched, then the buyer taps
    /// CANCELLED and CANCELLED's page 1 lands first.
    Future<void> arrange() async {
      final first = c.setFilter(null);
      repo.pending[0]
          .complete(_ordersPage(['a', 'b'], page: 1, total: 4, hasNext: true));
      await first;
      expect(_ids(c.state.value), ['a', 'b']);

      stale = c.loadMore();
      expect(repo.calls.last, 'list:2:20:null');
      expect(c.loadingMore.value, isTrue);

      final second = c.setFilter(OrderStatus.cancelled);
      repo.pending[2].complete(Ok(Paged<Order>(
          [_order('z', OrderStatus.cancelled)],
          _metaAt(page: 1, total: 3, hasNext: true, size: 1))));
      await second;
      expect(_ids(c.state.value), ['z']);
    }

    test('its rows are NOT appended and its cursor is NOT adopted', () async {
      await arrange();

      // hasNext:false would switch the footer off if this meta were adopted.
      repo.pending[1]
          .complete(_ordersPage(['c', 'd'], page: 2, total: 4, hasNext: false));
      await stale;

      expect(_ids(c.state.value), ['z'], reason: 'the CANCELLED chip is lit');
      expect(c.hasMore, isTrue, reason: "_meta must still be CANCELLED's");
      expect(c.loadMoreError.value, isNull);
    });

    test('the footer spinner is released at the bump, not on its answer',
        () async {
      // The abandoned read may never answer at all, and nothing else would
      // then clear the latch — an eternal footer spinner with no way out.
      await arrange();
      expect(c.loadingMore.value, isFalse);
    });

    test('the discard leaves loadingMore false and the list still paging',
        () async {
      await arrange();
      repo.pending[1]
          .complete(_ordersPage(['c', 'd'], page: 2, total: 4, hasNext: false));
      await stale;

      expect(c.loadingMore.value, isFalse);
      unawaited(c.loadMore());
      // page 2, not 3: `_page` describes the ONE rendered CANCELLED page.
      expect(repo.calls.last, 'list:2:20:CANCELLED');
      expect(c.loadingMore.value, isTrue);
    });

    test('a stale FAILURE never becomes the new list\'s footer error', () async {
      await arrange();
      repo.pending[1].complete(const Err<Paged<Order>>(ApiError(
          code: ApiErrorCode.internal, statusCode: 500, message: 'Server error')));
      await stale;

      expect(c.loadMoreError.value, isNull);
      expect(c.loadingMore.value, isFalse);
    });
  });

  test('pull-to-refresh supersedes an in-flight page 2 the same way', () async {
    // Same root cause with no filter change: refreshFirst resets the cursor to
    // page 1, so a page-2 answer merging in behind it corrupts the cursor just
    // as a chip change would.
    final first = c.setFilter(null);
    repo.pending[0]
        .complete(_ordersPage(['a', 'b'], page: 1, total: 6, hasNext: true));
    await first;

    final more = c.loadMore();
    final refreshed = c.refreshFirst();
    repo.pending[2]
        .complete(_ordersPage(['a'], page: 1, total: 2, hasNext: true));
    await refreshed;
    repo.pending[1]
        .complete(_ordersPage(['c', 'd'], page: 2, total: 6, hasNext: true));
    await more;

    expect(_ids(c.state.value), ['a']);
    expect(c.loadingMore.value, isFalse);
    unawaited(c.loadMore());
    expect(repo.calls.last, 'list:2:20:null');
  });

  test('an uninterrupted loadMore appends and ADVANCES the cursor', () async {
    final first = c.setFilter(null);
    repo.pending[0]
        .complete(_ordersPage(['a', 'b'], page: 1, total: 6, hasNext: true));
    await first;

    final more = c.loadMore();
    expect(c.loadingMore.value, isTrue);
    repo.pending[1]
        .complete(_ordersPage(['c', 'd'], page: 2, total: 6, hasNext: true));
    await more;

    expect(_ids(c.state.value), ['a', 'b', 'c', 'd']);
    expect(c.loadingMore.value, isFalse);
    unawaited(c.loadMore());
    expect(repo.calls.last, 'list:3:20:null');
  });

  test('loadMore does not dispatch while page 1 is still in flight', () async {
    // The old `hasMore` was the PREVIOUS filter's, so a scroll landing in this
    // window could fetch page 2 of a list whose page 1 had not arrived.
    final first = c.setFilter(null);
    repo.pending[0]
        .complete(_ordersPage(['a', 'b'], page: 1, total: 6, hasNext: true));
    await first;

    final second = c.setFilter(OrderStatus.cancelled);
    unawaited(c.loadMore());
    expect(repo.calls, ['list:1:20:null', 'list:1:20:CANCELLED']);

    repo.pending[1]
        .complete(_ordersPage(['z'], page: 1, total: 1, hasNext: false));
    await second;
    expect(_ids(c.state.value), ['z']);
  });
}

import 'package:autonect/controller/buyer/my_requests_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_buyer_repositories.dart';

/// PagedController is abstract, so it is exercised through the real
/// MyRequestsController — that also pins `fetchPage` and `idOf`, which are the
/// two things a concrete subclass can get wrong.
PartRequest _req(String id) => PartRequest.fromJson({
  'id': id,
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

Ok<Paged<PartRequest>> _page(
  List<String> ids, {
  required int total,
  required bool hasNext,
  int page = 1,
}) => Ok(
  Paged<PartRequest>(
    [for (final id in ids) _req(id)],
    PageMeta(
      page: page,
      limit: 20,
      pageSize: ids.length,
      total: total,
      totalPages: hasNext ? page + 1 : page,
      hasNextPage: hasNext,
      hasPreviousPage: page > 1,
    ),
  ),
);

const _boom = Err<Paged<PartRequest>>(
  ApiError(code: ApiErrorCode.internal, statusCode: 500, message: 'Server error'),
);

List<String> _ids(ViewState<List<PartRequest>> s) => switch (s) {
  Data<List<PartRequest>>(:final value) => [for (final r in value) r.id],
  _ => const [],
};

void main() {
  late FakeRequestsRepository repo;
  late MyRequestsController c;

  setUp(() {
    repo = FakeRequestsRepository();
    // The three injected no-ops are what let this file run with no
    // GetMaterialApp and no Fluttertoast platform channel.
    c = MyRequestsController(
      repo,
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    );
  });

  test('page 1 with total 0 becomes Empty, never Data([])', () async {
    repo.listQueue.add(_page(const [], total: 0, hasNext: false));
    await c.refreshFirst();
    expect(c.state.value, isA<Empty<List<PartRequest>>>());
    expect(c.hasMore, isFalse);
  });

  test('hasNextPage true lets loadMore APPEND to the loaded page', () async {
    repo.listQueue.add(_page(const ['a', 'b'], total: 4, hasNext: true));
    repo.listQueue.add(
      _page(const ['c', 'd'], total: 4, hasNext: false, page: 2),
    );
    await c.refreshFirst();
    expect(c.hasMore, isTrue);
    await c.loadMore();
    expect(_ids(c.state.value), ['a', 'b', 'c', 'd']);
    expect(c.hasMore, isFalse);
    expect(repo.calls, ['listMine:1:20:null', 'listMine:2:20:null']);
  });

  test('loadMore is a no-op while one is already in flight', () async {
    repo.listQueue.add(_page(const ['a'], total: 3, hasNext: true));
    repo.listQueue.add(_page(const ['b'], total: 3, hasNext: true, page: 2));
    await c.refreshFirst();
    // Not awaited: the second call must see loadingMore already true.
    final first = c.loadMore();
    await c.loadMore();
    await first;
    expect(_ids(c.state.value), ['a', 'b']);
    expect(repo.calls.where((x) => x.startsWith('listMine:2')).length, 1);
  });

  test('loadMore is a no-op once hasMore is false', () async {
    repo.listQueue.add(_page(const ['a'], total: 1, hasNext: false));
    await c.refreshFirst();
    await c.loadMore();
    expect(repo.calls, ['listMine:1:20:null']);
  });

  test('a loadMore FAILURE keeps the items and surfaces loadMoreError', () async {
    repo.listQueue.add(_page(const ['a', 'b'], total: 4, hasNext: true));
    repo.listQueue.add(_boom);
    await c.refreshFirst();
    await c.loadMore();
    // Blanking a good list because page 2 failed costs the user everything
    // they had already scrolled past.
    expect(_ids(c.state.value), ['a', 'b']);
    expect(c.state.value, isA<Data<List<PartRequest>>>());
    expect(c.loadMoreError.value?.code, ApiErrorCode.internal);
    expect(c.loadingMore.value, isFalse);
  });

  test('refreshFirst REPLACES the list and clears loadMoreError', () async {
    repo.listQueue.add(_page(const ['a', 'b'], total: 4, hasNext: true));
    repo.listQueue.add(_boom);
    await c.refreshFirst();
    await c.loadMore();
    expect(c.loadMoreError.value, isNotNull);

    repo.listQueue.add(_page(const ['z'], total: 1, hasNext: false));
    await c.refreshFirst();
    expect(_ids(c.state.value), ['z']);
    expect(c.loadMoreError.value, isNull);
  });

  test('an id repeated across two pages appears once', () async {
    // createdAt-desc ordering plus a row inserted between the two reads shifts
    // every later row down one, so page 2 legitimately re-sends page 1's tail.
    repo.listQueue.add(_page(const ['a', 'b'], total: 5, hasNext: true));
    repo.listQueue.add(
      _page(const ['b', 'c'], total: 5, hasNext: false, page: 2),
    );
    await c.refreshFirst();
    await c.loadMore();
    expect(_ids(c.state.value), ['a', 'b', 'c']);
  });

  test('a page-1 failure becomes Failed and setFilter re-reads page 1', () async {
    repo.listQueue.add(_boom);
    await c.refreshFirst();
    expect(c.state.value, isA<Failed<List<PartRequest>>>());

    repo.listQueue.add(_page(const ['a'], total: 1, hasNext: false));
    await c.setFilter(RequestStatus.open);
    expect(_ids(c.state.value), ['a']);
    expect(repo.calls.last, 'listMine:1:20:OPEN');
  });
}

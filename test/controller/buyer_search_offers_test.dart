import 'package:autonect/controller/buyer/buyer_home_controller.dart';
import 'package:autonect/controller/buyer/buyer_offers_controller.dart';
import 'package:autonect/controller/buyer/my_requests_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_buyer_repositories.dart';

/// The two things home gained with `q` on `GET /v1/requests` and the new
/// `GET /v1/buyer/offers`: a search that actually reaches the server, and an
/// offers feed that is offers rather than a count derived from requests.
///
/// The search is DEBOUNCED, so 'did the query reach the repository' is only
/// half the question — 'did it reach it once rather than once per keystroke' is
/// the half that decides whether a buyer typing a part name trips the
/// 300 req/60s global limiter.

/// Longer than the controllers' 350ms debounce, so a test that waits this long
/// has definitely seen the timer fire.
const Duration _pastDebounce = Duration(milliseconds: 400);

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

Offer _offer(String id) => Offer.fromJson({
  'id': id,
  'requestId': 'req_1',
  'supplierId': 'sup_1',
  'pricePence': 18500,
  'condition': 'NEW',
  'quantity': 1,
  'createdAt': '2026-09-02T09:00:00.000Z',
  'updatedAt': '2026-09-02T09:00:00.000Z',
  'supplier': {
    'id': 'sup_1',
    'name': 'A Person',
    'supplierProfile': {
      'businessName': 'Halewood Motor Factors',
      'ratingAvg': 4.6,
      'ratingCount': 128,
    },
  },
  'request': {
    'id': 'req_1',
    'partName': 'Front brake discs',
    'regNumber': 'LM19XYZ',
    'status': 'OPEN',
    'vehicle': {'make': 'FORD', 'model': 'Focus'},
    'category': {'id': 'cat_brakes', 'name': 'Brakes'},
  },
});

PageMeta _meta(int n) => PageMeta(
  page: 1,
  limit: 20,
  pageSize: n,
  total: n,
  totalPages: n == 0 ? 0 : 1,
  hasNextPage: false,
  hasPreviousPage: false,
);

MyRequestsController _requests(FakeRequestsRepository repo) =>
    MyRequestsController(repo, toast: (_) {}, showBusy: () {}, hideBusy: () {});

BuyerHomeController _home(FakeRequestsRepository repo) =>
    BuyerHomeController(repo, toast: (_) {}, showBusy: () {}, hideBusy: () {});

BuyerOffersController _offersOf(FakeOrdersRepository repo) =>
    BuyerOffersController(repo, toast: (_) {}, showBusy: () {}, hideBusy: () {});

void main() {
  group('MyRequestsController search', () {
    test('a keystroke burst issues ONE read, not one per character', () async {
      final repo = FakeRequestsRepository()
        ..listResult = Ok(Paged<PartRequest>([_req('r1')], _meta(1)));
      final c = _requests(repo);

      for (final s in ['b', 'br', 'bra', 'brak', 'brake']) {
        c.setQuery(s);
      }
      // Nothing yet: the debounce has not elapsed.
      expect(repo.calls, isEmpty);

      await Future<void>.delayed(_pastDebounce);
      expect(repo.calls.length, 1);
      expect(repo.calls.single, contains(':q=brake'));
    });

    test('the query is sent trimmed, and a blank one is not sent at all',
        () async {
      final repo = FakeRequestsRepository()
        ..listResult = Ok(Paged<PartRequest>([_req('r1')], _meta(1)));
      final c = _requests(repo);

      c.setQuery('  alternator  ');
      await Future<void>.delayed(_pastDebounce);
      expect(repo.calls.single, contains(':q=alternator'));

      // Clearing the box is a real action and must re-read UNFILTERED rather
      // than send an empty q: `?q=` and an absent q are different requests, and
      // only one of them is 'no filter'.
      c.setQuery('');
      await Future<void>.delayed(_pastDebounce);
      expect(repo.calls.length, 2);
      expect(repo.calls.last, isNot(contains(':q=')));
    });

    test('re-typing the same query does not re-issue the read', () async {
      final repo = FakeRequestsRepository()
        ..listResult = Ok(Paged<PartRequest>([_req('r1')], _meta(1)));
      final c = _requests(repo);

      c.setQuery('brake');
      await Future<void>.delayed(_pastDebounce);
      expect(repo.calls.length, 1);

      // Deleting a character and retyping it lands on the same string.
      c.setQuery('brake');
      await Future<void>.delayed(_pastDebounce);
      expect(repo.calls.length, 1);
    });

    test('a search blanks the previous rows rather than leaving them under a '
        'box that no longer describes them', () async {
      final repo = FakeRequestsRepository()
        ..listResult = Ok(Paged<PartRequest>([_req('r1')], _meta(1)));
      final c = _requests(repo);
      await c.refreshFirst();
      expect(c.state.value, isA<Data<List<PartRequest>>>());

      repo.listResult = Ok(Paged<PartRequest>(const [], _meta(0)));
      c.setQuery('nothing matches this');
      await Future<void>.delayed(_pastDebounce);

      expect(c.state.value, isA<Empty<List<PartRequest>>>());
    });
  });

  group('BuyerHomeController search', () {
    test('empty copy distinguishes "no requests" from "no matches"', () async {
      final repo = FakeRequestsRepository()
        ..listResult = Ok(Paged<PartRequest>(const [], _meta(0)));
      final c = _home(repo);

      await c.load();
      expect((c.activeRequests.value as Empty<List<PartRequest>>).title,
          'No open requests');

      c.setQuery('gearbox');
      await Future<void>.delayed(_pastDebounce);
      // Otherwise a buyer reads 'you have no open requests' while a filter they
      // cannot see is what emptied the list.
      expect((c.activeRequests.value as Empty<List<PartRequest>>).title,
          'No matches');
    });

    test('the query travels with every later load, refreshes included',
        () async {
      final repo = FakeRequestsRepository()
        ..listResult = Ok(Paged<PartRequest>([_req('r1')], _meta(1)));
      final c = _home(repo);

      c.setQuery('alternator');
      await Future<void>.delayed(_pastDebounce);
      await c.load();

      expect(repo.calls.length, 2);
      expect(repo.calls.every((x) => x.contains(':q=alternator')), isTrue);
    });
  });

  group('BuyerOffersController', () {
    test('reads the buyer-scoped route, not the supplier one', () async {
      final repo = FakeOrdersRepository()
        ..buyerOffersResult = Ok(Paged<Offer>([_offer('o1')], _meta(1)));
      final c = _offersOf(repo);

      await c.load();
      // GET /v1/offers is role-gated to SUPPLIER — a buyer calling it 403s.
      expect(repo.calls.single, startsWith('buyerOffers:'));
      expect((c.offers.value as Data<List<Offer>>).value.single.id, 'o1');
    });

    test('a zero total is Empty with copy, not an empty Data list', () async {
      final repo = FakeOrdersRepository()
        ..buyerOffersResult = Ok(Paged<Offer>(const [], _meta(0)));
      final c = _offersOf(repo);

      await c.load();
      expect((c.offers.value as Empty<List<Offer>>).title, 'No offers yet');
    });

    test('a failure is Failed, so the section offers its own retry', () async {
      final repo = FakeOrdersRepository()
        ..buyerOffersResult = Err<Paged<Offer>>(const ApiError.network());
      final c = _offersOf(repo);

      await c.load();
      expect(c.offers.value, isA<Failed<List<Offer>>>());
    });

    test('the joined request is what makes a cross-request feed readable',
        () async {
      final repo = FakeOrdersRepository()
        ..buyerOffersResult = Ok(Paged<Offer>([_offer('o1')], _meta(1)));
      final c = _offersOf(repo);

      await c.load();
      final offer = (c.offers.value as Data<List<Offer>>).value.single;
      expect(offer.request?.partName, 'Front brake discs');
      expect(offer.request?.make, 'FORD');
      expect(offer.request?.categoryName, 'Brakes');
      expect(offer.supplier.ratingAvg, 4.6);
      expect(offer.supplier.ratingCount, 128);
    });
  });
}

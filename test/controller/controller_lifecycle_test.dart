import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/controller/buyer/review_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_buyer_repositories.dart';

/// THE PER-ENTITY RESET RULE — [ApiController.beginEntity].
///
/// Every controller under test here is a session-long `Get` singleton: ONE
/// instance serves every request, order, offer and supplier the buyer opens. So
/// each of these tests is the same shape — point the controller at entity A,
/// make it hold something that is only true of A, point it at B, and check that
/// B does not inherit it. The mirror test always follows: re-entering A must
/// KEEP it, because clearing state that is still true is how a fix for one of
/// these turns into a screen that presents stale data as fresh.
PartRequest _request(String id, RequestStatus status) => PartRequest.fromJson({
  'id': id, 'buyerId': 'usr_buyer', 'regNumber': 'LM19XYZ',
  'categoryId': 'cat_brakes', 'partName': 'Front brake discs',
  'status': status.wire, 'offerCount': 0,
  'createdAt': '2026-09-01T10:15:00.000Z',
  'updatedAt': '2026-09-01T10:15:00.000Z',
  'category': {'id': 'cat_brakes', 'name': 'Brakes'},
  'images': <Object?>[],
});

Err<PartRequest> _conflict(String message) =>
    Err(ApiError(code: ApiErrorCode.conflict, statusCode: 409, message: message));

/// `meta.total` must be non-zero: a zero-total page is [Empty], not [Data], and
/// the leak this proves is one supplier's numbers rendering under another's.
ReviewsPage _reviews(double average) => ReviewsPage(
  items: const <Review>[],
  meta: const PageMeta(page: 1, limit: 20, pageSize: 20, total: 1,
      totalPages: 1, hasNextPage: false, hasPreviousPage: false),
  summary: ReviewsSummary(average: average, counts: const {5: 1}),
);

/// The rule's own contract, with no repository in the way.
class _Probe extends ApiController {
  _Probe() : super(toast: _swallow, showBusy: _nothing, hideBusy: _nothing);

  static void _swallow(String _) {}
  static void _nothing() {}

  int resets = 0;

  @override
  void resetForEntity() => resets++;

  bool begin(String id) => beginEntity(id);
}

void main() {
  group('ApiController.beginEntity', () {
    test('resets on a switch and NEVER on a re-entry', () {
      final p = _Probe()..formError.value = 'close failed';
      expect(p.begin('a'), isTrue);
      expect(p.resets, 1);
      expect(p.formError.value, isNull);

      p.formError.value = 'close failed again';
      expect(p.begin('a'), isFalse);
      expect(p.resets, 1);
      expect(p.formError.value, 'close failed again',
          reason: 'a re-entry must not hide a failure the buyer has not fixed');

      expect(p.begin('b'), isTrue);
      expect(p.resets, 2);
      expect(p.formError.value, isNull);
    });
  });

  group('RequestDetailController', () {
    late FakeRequestsRepository requests;
    late FakeOrdersRepository orders;
    late RequestDetailController c;

    setUp(() {
      requests = FakeRequestsRepository();
      orders = FakeOrdersRepository();
      orders.offersResult = const Ok(<Offer>[]);
      c = RequestDetailController(requests, orders,
          toast: (_) {}, showBusy: () {}, hideBusy: () {});
    });

    /// A failed CLOSE is the dangerous error: the only two things that clear it
    /// are CLOSE and CANCEL themselves, and both are offered only while a
    /// request is OPEN.
    Future<void> failCloseOn(String id) async {
      requests.byIdResult = Ok(_request(id, RequestStatus.open));
      await c.load(id);
      requests.closeResult = _conflict('Request is not open');
      await c.close(CloseAction.close);
      expect(c.formError.value, isNotNull, reason: 'precondition');
    }

    test("request A's failed close never prints over request B", () async {
      await failCloseOn('req_a');
      requests.byIdResult = Ok(_request('req_b', RequestStatus.open));
      await c.load('req_b');
      expect(c.formError.value, isNull);
    });

    test('...and a request that is CLOSED could never clear it', () async {
      await failCloseOn('req_a');
      // B renders no Close/Cancel buttons at all, so before the fix nothing on
      // this screen — nothing in the app — could remove A's red line.
      requests.byIdResult = Ok(_request('req_b', RequestStatus.closed));
      await c.load('req_b');
      expect(c.formError.value, isNull);
      expect(c.requestOrNull?.isOpen, isFalse);
    });

    test('re-opening the SAME request keeps it — it is still true', () async {
      await failCloseOn('req_a');
      await c.load('req_a');
      expect(c.formError.value, isNotNull);
    });
  });

  group('ReviewController', () {
    late FakeReviewsRepository repo;
    late ReviewController c;

    setUp(() {
      repo = FakeReviewsRepository();
      c = ReviewController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {});
    });

    test("supplier A's average never opens under supplier B's tab", () async {
      repo.forTargetResult = Ok(_reviews(4.5));
      await c.loadReviews('sup_a');
      expect(c.supplierReviews.value, isA<Data<ReviewsPage>>(),
          reason: 'precondition');

      // Asserted BEFORE the await: the offer-detail Reviews tab is rebuilt the
      // moment loadReviews is called, and the whole bug is what it renders
      // while the new supplier's read is still in flight.
      final pending = c.loadReviews('sup_b');
      expect(c.supplierReviews.value, isA<Loading<ReviewsPage>>());
      await pending;
    });

    test('the SAME supplier refreshes under its own rows', () async {
      repo.forTargetResult = Ok(_reviews(4.5));
      await c.loadReviews('sup_a');
      final pending = c.loadReviews('sup_a');
      // No skeleton over rows that are still correct.
      expect(c.supplierReviews.value, isA<Data<ReviewsPage>>());
      await pending;
    });
  });
}

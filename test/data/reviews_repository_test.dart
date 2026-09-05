import 'dart:convert';

import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/repositories/reviews_api_repository.dart';
import 'package:autonect/domain/conflict_kind.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_transport.dart';
import '../fixtures/buyer_bodies.dart';

void main() {
  late FakeTransport t;
  late ReviewsApiRepository repo;

  const createdBody =
      '{"success":true,"data":{"id":"rev_9","targetId":"usr_sup1",'
      '"authorId":"usr_buyer","orderId":"ord_1","rating":5,"text":null,'
      '"status":"PUBLISHED","createdAt":"2026-09-04T09:00:00.000Z"}}';

  setUp(() {
    t = FakeTransport();
    final tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
    repo = ReviewsApiRepository(
      ApiClient(transport: t, baseUrl: 'http://test.local', tokens: tokens),
      tokens,
    );
  });

  Map<String, dynamic> bodyOf(String method, String path) =>
      jsonDecode(t.lastOf(method, path)!.body!) as Map<String, dynamic>;

  group('create', () {
    test('omits text when blank — "" fails the server min(1)', () async {
      t.on('POST', '/v1/reviews', body: createdBody);
      final r = await repo.create(orderId: 'ord_1', rating: 5, text: '  ');
      expect(bodyOf('POST', '/v1/reviews'), {'orderId': 'ord_1', 'rating': 5});
      expect(r.valueOrNull!.id, 'rev_9');
    });

    test('trims and sends real text', () async {
      t.on('POST', '/v1/reviews', body: createdBody);
      await repo.create(orderId: 'ord_1', rating: 4, text: '  Great  ');
      expect(bodyOf('POST', '/v1/reviews'), {
        'orderId': 'ord_1',
        'rating': 4,
        'text': 'Great',
      });
    });

    // Both are 409 CONFLICT and identical to a status-code check. Pinning the
    // prose here is what makes a backend copy change fail a test instead of
    // silently degrading the review screen's copy.
    test('the two 409s are told apart only by message', () async {
      t.on(
        'POST',
        '/v1/reviews',
        status: 409,
        body: errorBody('CONFLICT', 'Order already reviewed'),
      );
      t.on(
        'POST',
        '/v1/reviews',
        status: 409,
        body: errorBody('CONFLICT', 'You can review only after delivery'),
      );
      final first = await repo.create(orderId: 'ord_1', rating: 5);
      final second = await repo.create(orderId: 'ord_1', rating: 5);

      expect(first.errorOrNull!.code, ApiErrorCode.conflict);
      expect(second.errorOrNull!.code, ApiErrorCode.conflict);
      expect(first.errorOrNull!.message, 'Order already reviewed');
      expect(second.errorOrNull!.message, 'You can review only after delivery');
      expect(
        classifyConflict(first.errorOrNull!.message),
        ConflictKind.alreadyReviewed,
      );
      expect(
        classifyConflict(second.errorOrNull!.message),
        ConflictKind.notDeliveredYet,
      );
    });
  });

  group('forTarget', () {
    test('is PUBLIC — no authorization header goes out', () async {
      t.on('GET', '/v1/reviews', body: kReviewsListBody);
      await repo.forTarget(targetId: 'usr_sup1');
      final call = t.lastOf('GET', '/v1/reviews')!;
      expect(call.headers.containsKey('authorization'), isFalse);
      expect(call.query, {'targetId': 'usr_sup1', 'page': '1', 'limit': '20'});
    });

    test('carries meta.average and meta.counts through the decode', () async {
      t.on('GET', '/v1/reviews', body: kReviewsListBody);
      final page = (await repo.forTarget(targetId: 'usr_sup1')).valueOrNull!;
      expect(page.items.length, 2);
      expect(page.summary.average, 4.5);
      expect(page.summary.counts[5], 1);
      expect(page.summary.counts[4], 1);
      expect(page.summary.counts[1], 0);
      expect(page.meta.total, 2);
      // The nullable traps: an anonymous author and a supplier reply.
      expect(page.items.first.author!.name, isNull);
      expect(page.items.last.reply!.text, 'Thanks for the order');
    });
  });
}

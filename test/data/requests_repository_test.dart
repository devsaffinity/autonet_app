import 'dart:convert';

import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/requests_api_repository.dart';
import 'package:autonect/domain/pending_image.dart';
import 'package:autonect/domain/request_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_transport.dart';
import '../fixtures/buyer_bodies.dart';

void main() {
  late FakeTransport t;
  late RequestsApiRepository repo;

  setUp(() {
    t = FakeTransport();
    final tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
    repo = RequestsApiRepository(
      ApiClient(transport: t, baseUrl: 'http://test.local', tokens: tokens),
      tokens,
    );
  });

  Map<String, dynamic> bodyOf(String method, String path) =>
      jsonDecode(t.lastOf(method, path)!.body!) as Map<String, dynamic>;

  RequestDraft validDraft() => RequestDraft(
    regNumber: 'lm19 xyz',
    categoryId: 'cat_brakes',
    region: Region.london,
    partName: 'Front brake discs',
    condition: PartCondition.either,
    urgency: RequestUrgency.standard,
  );

  group('listMine', () {
    test('OMITS the status key entirely when no filter is chosen', () async {
      t.on('GET', '/v1/requests', body: kListRequestsBody);
      final r = await repo.listMine();
      expect(r.isOk, isTrue);
      final query = t.lastOf('GET', '/v1/requests')!.query!;
      // `?status=` / `?status=all` are 400s: the filter is a bare optional
      // enum, unlike page/limit which tolerate blanks. Absent means no filter.
      expect(query.containsKey('status'), isFalse);
      expect(query['page'], '1');
      expect(query['limit'], '20');
    });

    test(
      'sends the wire string for a chosen status, stringifying paging',
      () async {
        t.on('GET', '/v1/requests', body: kListRequestsBody);
        await repo.listMine(page: 3, limit: 50, status: RequestStatus.open);
        expect(t.lastOf('GET', '/v1/requests')!.query, {
          'page': '3',
          'limit': '50',
          'status': 'OPEN',
        });
      },
    );

    test('clamps a limit above the server maximum instead of 400ing', () async {
      t.on('GET', '/v1/requests', body: kListRequestsBody);
      await repo.listMine(limit: 500);
      expect(t.lastOf('GET', '/v1/requests')!.query!['limit'], '100');
    });

    test('decodes items and the top-level meta', () async {
      t.on('GET', '/v1/requests', body: kListRequestsBody);
      final page = (await repo.listMine()).valueOrNull!;
      expect(page.items.length, 2);
      expect(page.items.first.offerCount, 3);
      expect(page.items.last.vehicle, isNull);
      expect(page.hasMore, isFalse);
    });
  });

  group('create', () {
    test('succeeds on HTTP 200 — the route does not answer 201', () async {
      t.on('POST', '/v1/requests', status: 200, body: kCreateRequestBody);
      final r = await repo.create(validDraft());
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.id, 'req_1');
    });

    test('omits blank optionals and always sends imageKeys', () async {
      t.on('POST', '/v1/requests', body: kCreateRequestBody);
      final draft = validDraft()
        ..partNumber = '   '
        ..description = '';
      await repo.create(draft);
      final body = bodyOf('POST', '/v1/requests');
      expect(body.containsKey('partNumber'), isFalse);
      expect(body.containsKey('description'), isFalse);
      // `[]` is explicitly valid via `.default([])`; the key is never dropped.
      expect(body['imageKeys'], isEmpty);
      expect(body['regNumber'], 'LM19XYZ');
      expect(body['region'], 'LONDON');
    });

    test('sends only the keys of images that actually uploaded', () async {
      t.on('POST', '/v1/requests', body: kCreateRequestBody);
      final draft = validDraft()
        ..images.addAll([
          PendingImage(
            localId: 'a',
            path: 'a.jpg',
            sizeBytes: 10,
            contentType: 'image/jpeg',
            status: ImageUploadStatus.uploaded,
            s3Key: 'requests/u/aaa.jpg',
          ),
          PendingImage(
            localId: 'b',
            path: 'b.jpg',
            sizeBytes: 10,
            contentType: 'image/jpeg',
            status: ImageUploadStatus.failed,
          ),
        ]);
      await repo.create(draft);
      expect(bodyOf('POST', '/v1/requests')['imageKeys'], [
        'requests/u/aaa.jpg',
      ]);
    });

    test(
      'a 403 on a foreign imageKey surfaces as forbidden, not a throw',
      () async {
        t.on(
          'POST',
          '/v1/requests',
          status: 403,
          body: errorBody('FORBIDDEN', 'imageKey does not belong to you'),
        );
        final r = await repo.create(validDraft());
        expect(r.errorOrNull!.code, ApiErrorCode.forbidden);
        expect(r.errorOrNull!.message, 'imageKey does not belong to you');
      },
    );
  });

  test('createImageUploadTicket posts the exact content type', () async {
    t.on('POST', '/v1/requests/image-url', body: kImageUrlTicketBody);
    final r = await repo.createImageUploadTicket('image/jpeg');
    expect(bodyOf('POST', '/v1/requests/image-url'), {
      'contentType': 'image/jpeg',
    });
    expect(r.valueOrNull!.key, 'requests/usr_buyer/ccc.jpg');
    expect(r.valueOrNull!.expiresInSec, 300);
  });

  test('byId reads a single request', () async {
    t.on('GET', '/v1/requests/req_1', body: kCreateRequestBody);
    final r = await repo.byId('req_1');
    expect(r.valueOrNull!.category.name, 'Brakes');
  });

  group('closeOrCancel', () {
    test('sends the ACTION verb, never the status it produces', () async {
      t.on('PATCH', '/v1/requests/req_1', body: kCreateRequestBody);
      await repo.closeOrCancel('req_1', CloseAction.cancel);
      expect(bodyOf('PATCH', '/v1/requests/req_1'), {'action': 'CANCEL'});
    });

    test('an unknown or foreign id is a 409, never a 404', () async {
      t.on(
        'PATCH',
        '/v1/requests/req_9',
        status: 409,
        body: errorBody('CONFLICT', 'Request is not open (or not yours)'),
      );
      final r = await repo.closeOrCancel('req_9', CloseAction.close);
      expect(r.errorOrNull!.code, ApiErrorCode.conflict);
      expect(r.errorOrNull!.statusCode, 409);
    });
  });
}

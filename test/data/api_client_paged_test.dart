import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_transport.dart';

class _Item {
  const _Item(this.id);
  final String id;
  static _Item fromJson(Map<String, dynamic> j) => _Item(j['id'] as String);
}

/// sendEnvelope carries the whole refresh machinery, so the single-flight
/// invariant has to hold on the paged path exactly as it does on send(). This
/// is the regression test for the send -> sendEnvelope refactor: if the
/// refactor ever duplicates the park or the generation anchor, three concurrent
/// 401s fire more than one refresh and the server revokes the token family.
void main() {
  late FakeTransport t;
  late InMemoryTokenStore tokens;
  late ApiClient client;

  const unauthorized = '{"success":false,"error":'
      '{"code":"UNAUTHORIZED","message":"Access token expired"}}';
  const pageBody = '{"success":true,"data":[{"id":"a"}],"meta":{"page":1,'
      '"limit":20,"pageSize":20,"total":30,"totalPages":2,"hasNextPage":true,'
      '"hasPreviousPage":false}}';

  setUp(() {
    t = FakeTransport();
    tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
    client = ApiClient(
      transport: t,
      baseUrl: 'http://test.local',
      tokens: tokens,
    );
  });

  Future<ApiResult<Paged<_Item>>> list(String path) => client.sendEnvelope(
    method: 'GET',
    path: path,
    decode: Paged.decoder(_Item.fromJson),
  );

  Future<void> pump() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('sendEnvelope surfaces items AND the top-level meta', () async {
    t.on('GET', '/v1/requests', body: pageBody);
    final p = (await list('/v1/requests')).valueOrNull!;
    expect(p.items.single.id, 'a');
    expect(p.meta.totalPages, 2);
    expect(p.hasMore, isTrue);
  });

  test('three concurrent 401s produce EXACTLY ONE refresh', () async {
    // Gates, not immediate answers: without them the three calls would
    // serialise and a broken single-flight would still pass.
    final g1 = t.withDelay('GET', '/v1/requests', status: 401, body: unauthorized);
    final g2 = t.withDelay('GET', '/v1/orders', status: 401, body: unauthorized);
    final g3 = t.withDelay('GET', '/v1/reviews', status: 401, body: unauthorized);
    t.on('POST', '/v1/auth/refresh', body: tokensBody('A2', 'R2'));
    t.on('GET', '/v1/requests', body: pageBody);
    t.on('GET', '/v1/orders', body: pageBody);
    t.on('GET', '/v1/reviews', body: pageBody);

    final f1 = list('/v1/requests');
    final f2 = list('/v1/orders');
    final f3 = list('/v1/reviews');
    await pump();
    // All three are now genuinely in flight on the same token generation.
    g1.complete();
    g2.complete();
    g3.complete();
    final results = await Future.wait([f1, f2, f3]);

    expect(t.countOf('POST', '/v1/auth/refresh'), 1);
    for (final r in results) {
      expect(r.valueOrNull?.items.single.id, 'a');
    }
    expect(tokens.accessToken, 'A2');
  });

  test('the retry after a refresh carries the NEW bearer', () async {
    t.on('GET', '/v1/requests', status: 401, body: unauthorized);
    t.on('POST', '/v1/auth/refresh', body: tokensBody('A2', 'R2'));
    t.on('GET', '/v1/requests', body: pageBody);
    expect((await list('/v1/requests')).isOk, isTrue);
    final retries = t.calls.where(
      (c) => c.method == 'GET' && c.headers['authorization'] == 'Bearer A2',
    );
    expect(retries.length, 1);
  });

  test('send() still delegates through sendEnvelope unchanged', () async {
    t.on('GET', '/v1/ping', body: '{"success":true,"data":{"message":"pong"}}');
    final r = await client.send<String>(
      method: 'GET',
      path: '/v1/ping',
      decode: (d) => (d as Map)['message'] as String,
    );
    expect(r.valueOrNull, 'pong');
  });
}

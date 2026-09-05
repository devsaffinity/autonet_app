import 'dart:convert';

import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/http_transport.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/repositories/catalog_api_repository.dart';
import 'package:autonect/data/repositories/vehicles_api_repository.dart';
import 'package:autonect/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_transport.dart';
import '../fixtures/buyer_bodies.dart';

void main() {
  late FakeTransport t;
  late InMemoryTokenStore tokens;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStore.init();
    t = FakeTransport();
    tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
  });

  ApiClient client() =>
      ApiClient(transport: t, baseUrl: 'http://test.local', tokens: tokens);

  CatalogApiRepository catalog() => CatalogApiRepository(client(), tokens);

  group('categories', () {
    test('is public — it goes out with no authorization header', () async {
      t.on('GET', '/v1/categories', body: kCategoriesBody);
      final r = await catalog().categories();
      expect(r.valueOrNull!.length, 3);
      expect(r.valueOrNull![1].parentId, 'cat_brakes');
      expect(
        t.lastOf('GET', '/v1/categories')!.headers.containsKey('authorization'),
        isFalse,
        reason: 'a 401 here would burn a refresh rotation for public data',
      );
    });

    test(
      'a network failure with a warm cache serves the cached list',
      () async {
        t.on('GET', '/v1/categories', body: kCategoriesBody);
        await catalog().categories();
        expect(SessionStore.categoriesJson, isNotNull);

        // A FRESH repository, so the answer can only have come off disk.
        t = FakeTransport();
        t.on(
          'GET',
          '/v1/categories',
          throws: const TransportFailure('offline'),
        );
        final r = await catalog().categories();
        expect(
          r.isOk,
          isTrue,
          reason:
              'categoryId is required by POST /v1/requests, so an '
              'unreachable list would be a hard stop on the whole wizard',
        );
        expect(r.valueOrNull!.map((c) => c.id), contains('cat_brakes'));
      },
    );

    test('a cold cache plus a failure is an honest Err', () async {
      t.on('GET', '/v1/categories', throws: const TransportTimeout());
      final r = await catalog().categories();
      expect(r.isOk, isFalse);
      expect(r.errorOrNull!.code, ApiErrorCode.timeout);
    });

    test('a 4xx is never masked by the cache', () async {
      t.on('GET', '/v1/categories', body: kCategoriesBody);
      final repo = catalog();
      await repo.categories();
      t.on(
        'GET',
        '/v1/categories',
        status: 400,
        body: errorBody('VALIDATION_ERROR'),
      );
      final r = await repo.categories(forceRefresh: true);
      expect(r.errorOrNull!.code, ApiErrorCode.validationError);
    });

    test('the second read is memoised, and forceRefresh bypasses it', () async {
      t.on('GET', '/v1/categories', body: kCategoriesBody);
      final repo = catalog();
      await repo.categories();
      await repo.categories();
      expect(t.countOf('GET', '/v1/categories'), 1);
      await repo.categories(forceRefresh: true);
      expect(t.countOf('GET', '/v1/categories'), 2);
    });

    test(
      'a corrupt cached list degrades to Err, never to a thrown decode',
      () async {
        SessionStore.categoriesJson = 'not json';
        t.on(
          'GET',
          '/v1/categories',
          throws: const TransportFailure('offline'),
        );
        final r = await catalog().categories();
        expect(r.isOk, isFalse);
      },
    );
  });

  group('lookup', () {
    VehiclesApiRepository vehicles() => VehiclesApiRepository(client(), tokens);

    test('normalises the registration before sending it', () async {
      t.on(
        'POST',
        '/v1/vehicles/lookup',
        body: kVehicleLookupManualRequiredBody,
      );
      await vehicles().lookup('  yb68 abc ');
      final body =
          jsonDecode(t.lastOf('POST', '/v1/vehicles/lookup')!.body!) as Map;
      expect(body, {'regNumber': 'YB68ABC'});
    });

    test('a MANUAL_REQUIRED body parses with a null model', () async {
      t.on(
        'POST',
        '/v1/vehicles/lookup',
        body: kVehicleLookupManualRequiredBody,
      );
      final r = await vehicles().lookup('YB68ABC');
      final lookup = r.valueOrNull!;
      expect(lookup.vehicle.model, isNull);
      expect(lookup.vehicle.make, 'FORD');
      expect(lookup.needsManualModel, isTrue);
      // The lookup projection drops these two columns entirely.
      expect(lookup.vehicle.source, isNull);
      expect(lookup.vehicle.fetchedAt, isNull);
    });

    test('an unknown registration maps to notFound, not a throw', () async {
      t.on(
        'POST',
        '/v1/vehicles/lookup',
        status: 404,
        body: errorBody('NOT_FOUND', 'Vehicle not found'),
      );
      final r = await vehicles().lookup('AA00AAA');
      expect(r.errorOrNull!.code, ApiErrorCode.notFound);
      expect(r.errorOrNull!.statusCode, 404);
    });
  });
}

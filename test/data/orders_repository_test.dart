import 'dart:convert';

import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/repositories/orders_api_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_transport.dart';
import '../fixtures/buyer_bodies.dart';

void main() {
  late FakeTransport t;
  late OrdersApiRepository repo;

  setUp(() {
    t = FakeTransport();
    final tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
    repo = OrdersApiRepository(
      ApiClient(transport: t, baseUrl: 'http://test.local', tokens: tokens),
      tokens,
    );
  });

  Map<String, dynamic> bodyOf(String method, String path) =>
      jsonDecode(t.lastOf(method, path)!.body!) as Map<String, dynamic>;

  test('offersForRequest decodes a bare, unpaginated array', () async {
    t.on('GET', '/v1/requests/req_1/offers', body: kOffersArrayBody);
    final r = await repo.offersForRequest('req_1');
    final offers = r.valueOrNull!;
    expect(offers.length, 2);
    expect(offers.first.pricePence, 12999);
    expect(offers.first.supplier.businessName, 'Northside Motors');
    // The all-nulls supplier is a shape the server emits today.
    expect(offers.last.supplier.name, isNull);
    expect(offers.last.supplier.businessName, isNull);
  });

  group('acceptOffer', () {
    test('sends {} when no delivery location is given', () async {
      t.on('POST', '/v1/offers/off_1/accept', body: kAcceptOrderBody);
      final r = await repo.acceptOffer(offerId: 'off_1');
      expect(bodyOf('POST', '/v1/offers/off_1/accept'), isEmpty);
      expect(r.valueOrNull!.id, 'ord_1');
    });

    test(
      'sends {} for a blank location — "" fails the server min(1)',
      () async {
        t.on('POST', '/v1/offers/off_1/accept', body: kAcceptOrderBody);
        await repo.acceptOffer(offerId: 'off_1', deliveryLocation: '   ');
        expect(bodyOf('POST', '/v1/offers/off_1/accept'), isEmpty);
      },
    );

    test('trims and sends a real location', () async {
      t.on('POST', '/v1/offers/off_1/accept', body: kAcceptOrderBody);
      await repo.acceptOffer(
        offerId: 'off_1',
        deliveryLocation: '  12 Bruce Grove  ',
      );
      expect(bodyOf('POST', '/v1/offers/off_1/accept'), {
        'deliveryLocation': '12 Bruce Grove',
      });
    });

    test('a taken offer surfaces as conflict', () async {
      t.on(
        'POST',
        '/v1/offers/off_1/accept',
        status: 409,
        body: errorBody('CONFLICT', 'Offer is no longer acceptable'),
      );
      final r = await repo.acceptOffer(offerId: 'off_1');
      expect(r.errorOrNull!.code, ApiErrorCode.conflict);
    });
  });

  group('list', () {
    test('omits the status key when unfiltered', () async {
      t.on('GET', '/v1/orders', body: '{"success":true,"data":[]}');
      await repo.list();
      expect(
        t.lastOf('GET', '/v1/orders')!.query!.containsKey('status'),
        isFalse,
      );
    });

    test('accepts PLACED, which the PATCH enum does not', () async {
      t.on('GET', '/v1/orders', body: '{"success":true,"data":[]}');
      await repo.list(page: 2, limit: 10, status: OrderStatus.placed);
      expect(t.lastOf('GET', '/v1/orders')!.query, {
        'page': '2',
        'limit': '10',
        'status': 'PLACED',
      });
    });

    test('a missing meta stops paging rather than looping forever', () async {
      t.on('GET', '/v1/orders', body: '{"success":true,"data":[]}');
      final page = (await repo.list()).valueOrNull!;
      expect(page.isEmpty, isTrue);
      expect(page.hasMore, isFalse);
    });
  });

  test('byId decodes the ascending event timeline', () async {
    t.on('GET', '/v1/orders/ord_1', body: kOrderDetailBody);
    final order = (await repo.byId('ord_1')).valueOrNull!;
    expect(order.status, OrderStatus.outForDelivery);
    expect(order.events.map((e) => e.status).toList(), [
      OrderStatus.placed,
      OrderStatus.preparing,
      OrderStatus.outForDelivery,
    ]);
    expect(order.events.first.byUserId, isNull);
  });

  group('changeStatus guards', () {
    test('PLACED throws before anything reaches the wire', () {
      expect(
        () => repo.changeStatus(orderId: 'ord_1', status: OrderStatus.placed),
        throwsArgumentError,
      );
      expect(t.calls, isEmpty);
    });

    test('CANCELLED with a blank note throws before the wire', () {
      expect(
        () => repo.changeStatus(
          orderId: 'ord_1',
          status: OrderStatus.cancelled,
          note: '   ',
        ),
        throwsArgumentError,
      );
      expect(
        () =>
            repo.changeStatus(orderId: 'ord_1', status: OrderStatus.cancelled),
        throwsArgumentError,
      );
      expect(t.calls, isEmpty);
    });

    test('CANCELLED with a note sends both fields', () async {
      t.on('PATCH', '/v1/orders/ord_1/status', body: kOrderDetailBody);
      await repo.changeStatus(
        orderId: 'ord_1',
        status: OrderStatus.cancelled,
        note: '  Changed my mind  ',
      );
      expect(bodyOf('PATCH', '/v1/orders/ord_1/status'), {
        'status': 'CANCELLED',
        'note': 'Changed my mind',
      });
    });

    test('a buyer sending a forward status is a 403, not a 400', () async {
      // The DTO accepts PREPARING; it is RBAC inside the service that refuses a
      // buyer, so the client must not pre-empt this one with a local guard.
      t.on(
        'PATCH',
        '/v1/orders/ord_1/status',
        status: 403,
        body: errorBody('FORBIDDEN', 'Only the supplier can advance an order'),
      );
      final r = await repo.changeStatus(
        orderId: 'ord_1',
        status: OrderStatus.preparing,
      );
      expect(r.errorOrNull!.code, ApiErrorCode.forbidden);
      expect(r.errorOrNull!.statusCode, 403);
    });

    test(
      'the PATCH response is the full order, so no follow-up GET is made',
      () async {
        t.on('PATCH', '/v1/orders/ord_1/status', body: kOrderDetailBody);
        final r = await repo.changeStatus(
          orderId: 'ord_1',
          status: OrderStatus.cancelled,
          note: 'Changed my mind',
        );
        expect(r.valueOrNull!.events.length, 3);
        expect(t.countOf('GET', '/v1/orders/ord_1'), 0);
      },
    );
  });
}

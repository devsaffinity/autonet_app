import 'dart:convert';

import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/supplier_api_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_transport.dart';

const String kSupplierFeedBody = '''
{
  "success": true,
  "data": [
    {
      "id": "req_1",
      "partName": "Transmission",
      "region": "LONDON",
      "condition": "NEW",
      "urgency": "URGENT",
      "offerCount": 3,
      "createdAt": "2026-07-20T10:00:00.000Z",
      "category": { "id": "cat_1", "name": "Transmission" },
      "vehicle": { "make": "Toyota", "year": 2020 }
    }
  ],
  "meta": { "total": 1, "page": 1, "limit": 20, "totalPages": 1, "hasNextPage": false, "hasPrevPage": false }
}
''';

const String kSupplierLeadDetailBody = '''
{
  "success": true,
  "data": {
    "id": "req_1",
    "buyerId": "user_buyer_1",
    "regNumber": "LM20 XKR",
    "partName": "Transmission",
    "partNumber": "TR-9921",
    "condition": "NEW",
    "urgency": "URGENT",
    "description": "Gearbox slipping in second.",
    "region": "LONDON",
    "offerCount": 3,
    "createdAt": "2026-07-20T10:00:00.000Z",
    "updatedAt": "2026-07-20T10:00:00.000Z",
    "category": { "id": "cat_1", "name": "Transmission" },
    "vehicle": { "id": "veh_1", "regNumber": "LM20 XKR", "make": "Toyota", "model": "Yaris", "year": 2020 },
    "images": ["https://s3.local/img1.png"],
    "buyer": { "id": "user_buyer_1", "name": "Sarah Johnson", "memberSince": "2026-01-01T00:00:00.000Z" }
  }
}
''';

const String kSupplierDashboardBody = '''
{
  "success": true,
  "data": {
    "incomingRequests": 12,
    "activeNegotiations": 4,
    "creditBalance": 48,
    "subscribed": true,
    "todaysEarningsPence": 35000
  }
}
''';

const String kSupplierOffersBody = '''
{
  "success": true,
  "data": [
    {
      "id": "off_1",
      "requestId": "req_1",
      "supplierId": "supp_1",
      "pricePence": 32000,
      "quantity": 1,
      "condition": "NEW",
      "warrantyMonths": 12,
      "deliveryOption": "STANDARD",
      "deliveryTimeDays": 2,
      "stockStatus": "IN_STOCK",
      "notes": "Original OEM part",
      "status": "PENDING",
      "createdAt": "2026-07-20T12:00:00.000Z",
      "updatedAt": "2026-07-20T12:00:00.000Z",
      "request": {
        "id": "req_1",
        "partName": "Transmission",
        "status": "OPEN",
        "region": "LONDON",
        "offerCount": 3
      }
    }
  ],
  "meta": { "total": 1, "page": 1, "limit": 20, "totalPages": 1, "hasNextPage": false, "hasPrevPage": false }
}
''';

const String kSupplierSingleOfferBody = '''
{
  "success": true,
  "data": {
    "id": "off_1",
    "requestId": "req_1",
    "supplierId": "supp_1",
    "pricePence": 32000,
    "quantity": 1,
    "condition": "NEW",
    "warrantyMonths": 12,
    "deliveryOption": "STANDARD",
    "deliveryTimeDays": 2,
    "stockStatus": "IN_STOCK",
    "notes": "Original OEM part",
    "status": "PENDING",
    "createdAt": "2026-07-20T12:00:00.000Z",
    "updatedAt": "2026-07-20T12:00:00.000Z"
  }
}
''';

void main() {
  late FakeTransport t;
  late SupplierApiRepository repo;

  setUp(() {
    t = FakeTransport();
    final tokens = InMemoryTokenStore(access: 'A1', refresh: 'R1');
    repo = SupplierApiRepository(
      ApiClient(transport: t, baseUrl: 'http://test.local', tokens: tokens),
      tokens,
    );
  });

  Map<String, dynamic> bodyOf(String method, String path) =>
      jsonDecode(t.lastOf(method, path)!.body!) as Map<String, dynamic>;

  group('Supplier feed', () {
    test('feed decodes teaser items correctly with filters', () async {
      t.on('GET', '/v1/supplier/requests', body: kSupplierFeedBody);
      final r = await repo.feed(
        partName: 'Transmission',
        region: Region.london,
      );
      final paged = r.valueOrNull!;
      expect(paged.items.length, 1);
      final lead = paged.items.first;
      expect(lead.id, 'req_1');
      expect(lead.partName, 'Transmission');
      expect(lead.region, Region.london);
      expect(lead.condition, PartCondition.newPart);
      expect(lead.urgency, RequestUrgency.urgent);
      expect(lead.offerCount, 3);
      expect(lead.category?.name, 'Transmission');
      expect(lead.vehicleMake, 'Toyota');
      expect(lead.vehicleYear, 2020);

      final query = t.lastOf('GET', '/v1/supplier/requests')!.query!;
      expect(query['partName'], 'Transmission');
      expect(query['region'], 'LONDON');
    });

    test('leadDetail decodes full unlocked request with buyer and images', () async {
      t.on('GET', '/v1/supplier/requests/req_1', body: kSupplierLeadDetailBody);
      final r = await repo.leadDetail('req_1');
      final detail = r.valueOrNull!;
      expect(detail.id, 'req_1');
      expect(detail.buyerId, 'user_buyer_1');
      expect(detail.regNumber, 'LM20 XKR');
      expect(detail.buyer.name, 'Sarah Johnson');
      expect(detail.images, ['https://s3.local/img1.png']);
      expect(detail.vehicle?.model, 'Yaris');
    });

    test('dashboard decodes metrics and subscription status', () async {
      t.on('GET', '/v1/supplier/dashboard', body: kSupplierDashboardBody);
      final r = await repo.dashboard();
      final d = r.valueOrNull!;
      expect(d.incomingRequests, 12);
      expect(d.activeNegotiations, 4);
      expect(d.creditBalance, 48);
      expect(d.subscribed, isTrue);
      expect(d.todaysEarningsPence, 35000);
    });
  });

  group('Supplier offers', () {
    test('createOffer sends payload and decodes response', () async {
      t.on('POST', '/v1/requests/req_1/offers', body: kSupplierSingleOfferBody);
      final r = await repo.createOffer(
        requestId: 'req_1',
        pricePence: 32000,
        condition: PartCondition.newPart,
        deliveryOption: DeliveryOption.standard,
        stockStatus: StockStatus.inStock,
        quantity: 1,
        warrantyMonths: 12,
        deliveryTimeDays: 2,
        notes: 'Original OEM part',
      );
      expect(r.isOk, isTrue);
      final body = bodyOf('POST', '/v1/requests/req_1/offers');
      expect(body['pricePence'], 32000);
      expect(body['condition'], 'NEW');
      expect(body['deliveryOption'], 'STANDARD');
      expect(body['stockStatus'], 'IN_STOCK');
      expect(body['warrantyMonths'], 12);
      expect(body['notes'], 'Original OEM part');
    });

    test('listOffers sends status filter and decodes list', () async {
      t.on('GET', '/v1/supplier/offers', body: kSupplierOffersBody);
      final r = await repo.listOffers(status: OfferStatus.pending);
      final paged = r.valueOrNull!;
      expect(paged.items.length, 1);
      final offer = paged.items.first;
      expect(offer.id, 'off_1');
      expect(offer.pricePence, 32000);
      expect(offer.status, OfferStatus.pending);
      expect(offer.request?.partName, 'Transmission');

      final query = t.lastOf('GET', '/v1/supplier/offers')!.query!;
      expect(query['status'], 'PENDING');
    });

    test('editOffer sends PATCH with updated fields', () async {
      t.on('PATCH', '/v1/offers/off_1', body: kSupplierSingleOfferBody);
      final r = await repo.editOffer(
        offerId: 'off_1',
        pricePence: 29900,
        notes: 'Discounted price',
      );
      expect(r.isOk, isTrue);
      final body = bodyOf('PATCH', '/v1/offers/off_1');
      expect(body['pricePence'], 29900);
      expect(body['notes'], 'Discounted price');
    });

    test('withdrawOffer posts to withdraw endpoint', () async {
      t.on('POST', '/v1/offers/off_1/withdraw', body: kSupplierSingleOfferBody);
      final r = await repo.withdrawOffer('off_1');
      expect(r.isOk, isTrue);
      expect(t.countOf('POST', '/v1/offers/off_1/withdraw'), 1);
    });
  });
}

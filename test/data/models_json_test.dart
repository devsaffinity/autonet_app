import 'dart:convert';

import 'package:autonect/data/core/api_envelope.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/electrician_service.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/models/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/buyer_bodies.dart';

Map<String, dynamic> dataOf(String body) =>
    ((jsonDecode(body) as Map)['data'] as Map).cast<String, dynamic>();

List<Map<String, dynamic>> listOf(String body) =>
    ((jsonDecode(body) as Map)['data'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

void main() {
  group('PartRequest', () {
    test('create response decodes every field', () {
      final r = PartRequest.fromJson(dataOf(kCreateRequestBody));
      expect(r.id, 'req_1');
      // The server normalises the reg (normalizeReg), so the model must not:
      // what came back is exactly what the buyer should see.
      expect(r.regNumber, 'LM19XYZ');
      expect(r.regNumber, r.regNumber.toUpperCase().replaceAll(' ', ''));
      expect(r.status, RequestStatus.open);
      expect(r.offerCount, 0);
      expect(r.region, Region.london);
      expect(r.condition, PartCondition.either);
      expect(r.urgency, RequestUrgency.standard);
      expect(r.category.name, 'Brakes');
      expect(r.images, isA<List<RequestImage>>());
      expect(r.images.map((i) => i.s3Key), [
        'requests/usr_buyer/aaa.jpg',
        'requests/usr_buyer/bbb.jpg',
      ]);
      expect(r.vehicle?.make, 'BMW');
      expect(r.vehicle?.source, VehicleSource.dvla);
      expect(r.createdAt.toUtc().year, 2026);
    });

    test('list decodes through Paged, nulls and all', () {
      final page = decodeEnvelopeWithMeta(
        200,
        kListRequestsBody,
        Paged.decoder(PartRequest.fromJson),
      ).valueOrNull!;
      expect(page.items.length, 2);
      expect(page.meta.total, 2);
      expect(page.hasMore, isFalse);
      final second = page.items[1];
      expect(second.vehicle, isNull);
      expect(second.vehicleId, isNull);
      expect(second.partNumber, isNull);
      expect(second.description, isNull);
      expect(second.images, isEmpty);
      expect(second.status, RequestStatus.cancelled);
      expect(second.isOpen, isFalse);
    });

    test('a missing required string is a FormatException, not an empty value', () {
      final j = dataOf(kCreateRequestBody)..remove('id');
      expect(() => PartRequest.fromJson(j), throwsFormatException);
    });
  });

  group('Offer', () {
    test('array decodes, businessName is read out of supplierProfile', () {
      final offers = listOf(kOffersArrayBody).map(Offer.fromJson).toList();
      expect(offers.length, 2);
      expect(offers.first.pricePence, 12999);
      expect(offers.first.stockStatus, StockStatus.inStock);
      expect(offers.first.status, OfferStatus.pending);
      expect(offers.first.supplier.businessName, 'Northside Motors');
    });

    test('a supplier with no name and no profile stays null, not empty', () {
      final second = Offer.fromJson(listOf(kOffersArrayBody)[1]);
      expect(second.supplier.name, isNull);
      expect(second.supplier.businessName, isNull);
      expect(second.warrantyMonths, isNull);
      expect(second.deliveryTimeDays, isNull);
      expect(second.notes, isNull);
      expect(second.condition, PartCondition.used);
      expect(second.deliveryOption, DeliveryOption.localPickup);
    });

    test("the joined request's buyer photos decode, keys and urls both", () {
      final r = OfferRequestRef.fromJson(const {
        'id': 'req_1',
        'partName': 'Front brake discs',
        'regNumber': 'LM19XYZ',
        'images': [
          {'s3Key': 'requests/req_1/a.jpg', 'url': 'https://signed/a'},
        ],
      });

      expect(r.images.single.s3Key, 'requests/req_1/a.jpg');
      // The KEY is what a cache must key on — the url is a short presign that
      // changes on every read — so both survive the decode.
      expect(r.images.single.url, 'https://signed/a');
      expect(r.images.single.isRenderable, isTrue);
    });

    test('an offer feed with no images key decodes to empty, never null', () {
      // buyer-offers.service.ts does not select request images yet, so THIS is
      // the shape in production today. The card falls back to its placeholder
      // on an empty list; a null here would throw on the first home paint.
      final r = OfferRequestRef.fromJson(const {
        'id': 'req_1',
        'partName': 'Front brake discs',
        'regNumber': 'LM19XYZ',
      });

      expect(r.images, isEmpty);
    });

    test('a key with no url is not renderable — an old server sends bare keys',
        () {
      final r = OfferRequestRef.fromJson(const {
        'id': 'req_1',
        'partName': 'Front brake discs',
        'regNumber': 'LM19XYZ',
        'images': [
          {'s3Key': 'requests/req_1/a.jpg'},
        ],
      });

      // The bucket is private, so an unsigned key is unfetchable. Rendering it
      // would be a broken image where the placeholder is a clean one.
      expect(r.images.single.isRenderable, isFalse);
    });
  });

  group('Order', () {
    test('accept response: totals, refs and an actorless event', () {
      final o = Order.fromJson(dataOf(kAcceptOrderBody));
      expect(o.totalPence, 12999);
      expect(o.status, OrderStatus.placed);
      expect(o.deliveryMethod, DeliveryOption.standard);
      expect(o.offer.pricePence, 12999);
      expect(o.offer.quantity, 2);
      expect(o.request.regNumber, 'LM19XYZ');
      expect(o.events.single.byUserId, isNull);
      expect(o.events.single.status, OrderStatus.placed);
    });

    test('the embedded offer projection carries no stockStatus or notes', () {
      final embedded = dataOf(kAcceptOrderBody)['offer'] as Map;
      expect(embedded.containsKey('stockStatus'), isFalse);
      expect(embedded.containsKey('notes'), isFalse);
      expect(embedded.containsKey('status'), isFalse);
    });

    test('events keep the server ASC order', () {
      final o = Order.fromJson(dataOf(kOrderDetailBody));
      expect(o.events.map((e) => e.status), [
        OrderStatus.placed,
        OrderStatus.preparing,
        OrderStatus.outForDelivery,
      ]);
      expect(o.events[0].at.isBefore(o.events[1].at), isTrue);
      expect(o.events[1].at.isBefore(o.events[2].at), isTrue);
      expect(o.events[1].note, 'Picking stock');
    });
  });

  group('Reviews', () {
    test('the page decodes items, pagination and summary from one envelope', () {
      final page = decodeEnvelopeWithMeta(
        200,
        kReviewsListBody,
        ReviewsPage.decoder,
      ).valueOrNull!;
      expect(page.items.length, 2);
      expect(page.meta.total, 2);
      expect(page.summary.average, 4.5);
      // The wire keys are the JSON strings "1".."5".
      expect(page.summary.counts[5], 1);
      expect(page.summary.counts[4], 1);
      expect(page.summary.counts[1], 0);
      expect(page.summary.counts.length, 5);
      expect(page.items.first.author?.name, isNull);
      expect(page.items.first.reply, isNull);
      expect(page.items[1].text, isNull);
      expect(page.items[1].reply?.text, 'Thanks for the order');
    });

    test('absent meta is a zero summary, not a crash', () {
      final s = ReviewsSummary.fromMeta(null);
      expect(s.average, 0);
      expect(s.counts.values, everyElement(0));
      expect(s.counts.length, 5);
    });
  });

  test('VehicleLookup with no model asks for a manual one', () {
    final v = VehicleLookup.fromJson(dataOf(kVehicleLookupManualRequiredBody));
    expect(v.modelSource, ModelSource.manualRequired);
    expect(v.needsManualModel, isTrue);
    expect(v.vehicle.model, isNull);
    expect(v.vehicle.year, 2018);
    // The lookup projection drops both of these.
    expect(v.vehicle.source, isNull);
    expect(v.vehicle.fetchedAt, isNull);
  });

  test('categories are flat; nesting is only parentId', () {
    final cats = listOf(kCategoriesBody).map(PartCategory.fromJson).toList();
    expect(cats.length, 3);
    expect(cats.first.parentId, isNull);
    expect(cats[1].parentId, 'cat_brakes');
  });

  test('UploadTicket is the bare key/url/ttl triple', () {
    final t = UploadTicket.fromJson(dataOf(kImageUrlTicketBody));
    expect(t.key, 'requests/usr_buyer/ccc.jpg');
    expect(t.url, startsWith('https://'));
    expect(t.expiresInSec, 300);
  });

  group('ServiceProvider & ElectricianService', () {
    test('decodes customServices array with full details', () {
      final p = ServiceProvider.fromJson(const {
        'id': 'usr_elec_1',
        'fullName': 'Auto Electrical Ltd',
        'brands': ['BMW', 'Audi'],
        'services': ['DIAGNOSTIC', 'ECU_CODING'],
        'customServices': [
          {
            'id': 'srv_1',
            'electricianId': 'usr_elec_1',
            'name': 'ECU Remapping',
            'price': '£360',
            'pricingType': 'Fixed Price',
            'serviceType': 'ECU_CODING',
            'description': 'Stage 1 remap and dyno run',
          },
          {
            'id': 'srv_2',
            'electricianId': 'usr_elec_1',
            'name': 'Diagnostic Sweep',
            'price': '£89',
            'pricingType': 'Per Session',
            'description': 'Full OBD scan and fault clearing',
          },
        ],
      });

      expect(p.id, 'usr_elec_1');
      expect(p.fullName, 'Auto Electrical Ltd');
      expect(p.customServices.length, 2);

      final s1 = p.customServices[0];
      expect(s1.name, 'ECU Remapping');
      expect(s1.price, '£360');
      expect(s1.pricingType, 'Fixed Price');
      expect(s1.serviceType, BookingServiceType.ecuCoding);
      expect(s1.resolvedServiceType, BookingServiceType.ecuCoding);

      final s2 = p.customServices[1];
      expect(s2.name, 'Diagnostic Sweep');
      expect(s2.price, '£89');
      expect(s2.pricingType, 'Per Session');
      expect(s2.serviceType, isNull);
      // Inferred from 'Diagnostic' in name
      expect(s2.resolvedServiceType, BookingServiceType.diagnostic);
    });

    test('defaults customServices to empty list when absent', () {
      final p = ServiceProvider.fromJson(const {
        'id': 'usr_elec_2',
        'fullName': 'Plain Provider',
      });
      expect(p.customServices, isEmpty);
    });
  });
}

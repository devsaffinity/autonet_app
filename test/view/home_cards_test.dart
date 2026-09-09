import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/view/screens/buyer/home/widgets/active_request_card.dart';
import 'package:autonect/view/screens/buyer/home/widgets/buyer_offer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The home cards render four fields that are each absent in normal, non-error
/// operation — DVLA gives no model far more often than it gives one, and
/// `partNumber` is optional on the wire — so "what does this look like when the
/// data is missing" is the whole test surface here.

PartRequest _request({
  String? make,
  String? model,
  String? partNumber,
  String partName = 'Alternator',
  PartCondition? condition = PartCondition.newPart,
  int offerCount = 0,
  int imageCount = 0,
  DateTime? createdAt,
}) => PartRequest.fromJson({
  'id': 'req-1',
  'buyerId': 'buyer-1',
  'regNumber': 'AB12CDE',
  'categoryId': 'cat-1',
  'partName': partName,
  'partNumber': partNumber,
  'condition': condition?.wire,
  'offerCount': offerCount,
  'createdAt': (createdAt ?? DateTime(2026, 8, 12)).toIso8601String(),
  'updatedAt': (createdAt ?? DateTime(2026, 8, 12)).toIso8601String(),
  'category': {'id': 'cat-1', 'name': 'Engine'},
  if (make != null || model != null)
    'vehicle': {
      'id': 'v1',
      'regNumber': 'AB12CDE',
      'make': make,
      'model': model,
    },
  'images': [
    for (var i = 0; i < imageCount; i++) {'id': 'img$i', 's3Key': 'k$i'},
  ],
});

/// The `GET /v1/buyer/offers` row shape. Every joined field is optional on
/// that projection except the price, the date and the registration, so each
/// argument here defaults to ABSENT — that is the case the card has to survive.
Offer _offer({
  String? make,
  String? model,
  String partName = 'Alternator',
  int pricePence = 18500,
  String? businessName,
  String? supplierName,
  num? ratingAvg,
  int? ratingCount,
  String? categoryName = 'Engine',
  DateTime? createdAt,
  bool withRequest = true,
}) => Offer.fromJson({
  'id': 'offer-1',
  'requestId': 'req-1',
  'supplierId': 'sup-1',
  'pricePence': pricePence,
  'condition': 'NEW',
  'quantity': 1,
  'createdAt': (createdAt ?? DateTime(2026, 8, 12)).toIso8601String(),
  'updatedAt': (createdAt ?? DateTime(2026, 8, 12)).toIso8601String(),
  'supplier': {
    'id': 'sup-1',
    'name': supplierName,
    'supplierProfile': {
      'businessName': businessName,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
    },
  },
  if (withRequest)
    'request': {
      'id': 'req-1',
      'partName': partName,
      'regNumber': 'AB12CDE',
      'status': 'OPEN',
      if (make != null || model != null)
        'vehicle': {'make': make, 'model': model},
      if (categoryName != null) 'category': {'id': 'cat-1', 'name': categoryName},
    },
});

Widget _host(Widget child, {double width = 360, TextScaler? scaler}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: scaler ?? TextScaler.noScaling,
        ),
        child: Scaffold(
          body: SizedBox(
            width: width,
            height: kActiveRequestCardHeight,
            child: child,
          ),
        ),
      ),
    );

void main() {
  group('vehicleNameOf', () {
    test('both parts present', () {
      expect(vehicleNameOf(_request(make: 'FORD', model: 'Focus')),
          'FORD Focus');
    });

    test('make only - the common DVLA case', () {
      expect(vehicleNameOf(_request(make: 'FORD')), 'FORD');
    });

    test('model only', () {
      expect(vehicleNameOf(_request(model: 'Focus')), 'Focus');
    });

    test('neither - degrades to the registration, never "null null"', () {
      expect(vehicleNameOf(_request()), 'AB12CDE');
    });
  });

  group('formatDayMonthYear', () {
    test('zero-pads and orders day/month/year', () {
      expect(formatDayMonthYear(DateTime(2026, 8, 12)), '12/08/2026');
      expect(formatDayMonthYear(DateTime(2026, 12, 1)), '01/12/2026');
    });
  });

  group('ActiveRequestCard', () {
    testWidgets('a null part number hides its row entirely', (tester) async {
      await tester.pumpWidget(_host(ActiveRequestCard(request: _request())));

      // Not a dash beside a label - the field is absent, not empty.
      expect(find.text('Part No'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a present part number shows value and label', (tester) async {
      await tester.pumpWidget(
        _host(ActiveRequestCard(request: _request(partNumber: '13AD56U'))),
      );

      expect(find.text('13AD56U'), findsOneWidget);
      expect(find.text('Part No'), findsOneWidget);
    });

    testWidgets('one offer is singular', (tester) async {
      await tester.pumpWidget(
        _host(ActiveRequestCard(request: _request(offerCount: 1))),
      );

      expect(find.text('1 offer'), findsOneWidget);
      expect(find.text('1 offers'), findsNothing);
    });

    testWidgets('many offers are plural', (tester) async {
      await tester.pumpWidget(
        _host(ActiveRequestCard(request: _request(offerCount: 3))),
      );

      expect(find.text('3 offers'), findsOneWidget);
    });

    testWidgets('one photo is singular', (tester) async {
      await tester.pumpWidget(
        _host(ActiveRequestCard(request: _request(imageCount: 1))),
      );

      expect(find.text('1 photo'), findsOneWidget);
    });

    testWidgets('condition falls back to Any when the field predates it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(ActiveRequestCard(request: _request(condition: null))),
      );

      expect(find.text('Any'), findsOneWidget);
      expect(find.text('Condition'), findsOneWidget);
    });

    testWidgets('no overflow at 320dp', (tester) async {
      await tester.pumpWidget(
        _host(
          ActiveRequestCard(
            request: _request(
              make: 'MERCEDES-BENZ',
              model: 'C-Class AMG Line Premium',
              partNumber: '13AD56U-LONG-PART-NUMBER',
            ),
          ),
          width: 320,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 200% system font', (tester) async {
      // The image band is Expanded precisely so it surrenders height here
      // instead of the card overflowing its fixed carousel slot.
      await tester.pumpWidget(
        _host(
          ActiveRequestCard(
            request: _request(make: 'FORD', partNumber: '13AD56U'),
          ),
          width: 320,
          scaler: const TextScaler.linear(2.0),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('BuyerOfferCard', () {
    testWidgets('shows the part, the car and the price', (tester) async {
      await tester.pumpWidget(
        _host(BuyerOfferCard(offer: _offer(make: 'TOYOTA', partName: 'Alternator'))),
      );

      expect(find.text('Alternator'), findsOneWidget);
      // Upper-cased in the card, not in the fixture.
      expect(find.text('TOYOTA'), findsOneWidget);
      expect(find.text('£185.00'), findsOneWidget);
    });

    testWidgets('falls back to the registration when DVLA gave no make', (
      tester,
    ) async {
      await tester.pumpWidget(_host(BuyerOfferCard(offer: _offer())));

      expect(find.text('AB12CDE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the offer date in UK order', (tester) async {
      await tester.pumpWidget(
        _host(BuyerOfferCard(offer: _offer(createdAt: DateTime(2026, 8, 12)))),
      );

      expect(find.text('12/08/2026'), findsOneWidget);
    });

    testWidgets('prefers the trading name over the account name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(BuyerOfferCard(offer: _offer(
          businessName: 'Halewood Motor Factors',
          supplierName: 'A Person',
        ))),
      );

      expect(find.text('Halewood Motor Factors'), findsOneWidget);
      expect(find.text('A Person'), findsNothing);
    });

    testWidgets('an unrated supplier shows no rating, not a zero', (
      tester,
    ) async {
      // Both fields null means "this route did not select a rating" - only
      // /v1/buyer/offers does - so a 0.0 here would be an invented claim.
      await tester.pumpWidget(_host(BuyerOfferCard(offer: _offer())));

      expect(find.textContaining('0.0'), findsNothing);
    });

    testWidgets('a rating with no reviews behind it is not shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(BuyerOfferCard(offer: _offer(ratingAvg: 0, ratingCount: 0))),
      );

      expect(find.textContaining('(0)'), findsNothing);
    });

    testWidgets('a real rating shows the average and the count', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(BuyerOfferCard(offer: _offer(ratingAvg: 4.6, ratingCount: 128))),
      );

      expect(find.text('4.6 (128)'), findsOneWidget);
    });

    testWidgets('survives a row with no request joined in', (tester) async {
      // Offer.request is null on GET /v1/requests/:id/offers, which shares this
      // model - the card must degrade rather than throw.
      await tester.pumpWidget(_host(BuyerOfferCard(offer: _offer(withRequest: false))));

      expect(tester.takeException(), isNull);
      expect(find.text('£185.00'), findsOneWidget);
    });

    testWidgets('no overflow at 320dp with 200% font', (tester) async {
      // The metadata pairs are a Wrap, not a Row, for exactly this case.
      await tester.pumpWidget(
        _host(
          BuyerOfferCard(offer: _offer(
            make: 'MERCEDES-BENZ',
            model: 'C-Class',
            partName: 'Transmission',
            businessName: 'Halewood Motor Factors',
          )),
          width: 320,
          scaler: const TextScaler.linear(2.0),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:autonect/data/models/offer.dart';
import 'package:autonect/domain/offer_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

Offer offer(String id, int pricePence, {int? deliveryTimeDays}) => Offer(
  id: id,
  requestId: 'req_1',
  supplierId: 'sup_1',
  pricePence: pricePence,
  quantity: 1,
  deliveryTimeDays: deliveryTimeDays,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
  supplier: const OfferSupplier(id: 'sup_1'),
);

void main() {
  group('lowestPriceOfferIndex', () {
    test('empty list yields null', () {
      expect(lowestPriceOfferIndex(const []), isNull);
    });

    test('picks the cheapest', () {
      final offers = [offer('a', 5000), offer('b', 3200), offer('c', 9900)];
      expect(lowestPriceOfferIndex(offers), 1);
    });

    test('a tie yields exactly ONE index — the first', () {
      final offers = [offer('a', 3200), offer('b', 3200), offer('c', 3200)];
      expect(lowestPriceOfferIndex(offers), 0);
    });
  });

  group('fastestOfferIndex', () {
    test('empty list yields null', () {
      expect(fastestOfferIndex(const []), isNull);
    });

    test('picks the fewest delivery days', () {
      final offers = [
        offer('a', 100, deliveryTimeDays: 5),
        offer('b', 100, deliveryTimeDays: 2),
      ];
      expect(fastestOfferIndex(offers), 1);
    });

    test('a tie yields exactly ONE index — the first', () {
      final offers = [
        offer('a', 100, deliveryTimeDays: 2),
        offer('b', 100, deliveryTimeDays: 2),
      ];
      expect(fastestOfferIndex(offers), 0);
    });

    test('a null deliveryTimeDays never wins — unstated is not instant', () {
      final offers = [offer('a', 100), offer('b', 100, deliveryTimeDays: 9)];
      expect(fastestOfferIndex(offers), 1);
    });

    test('all delivery times unstated yields null, not index 0', () {
      final offers = [offer('a', 100), offer('b', 100)];
      expect(fastestOfferIndex(offers), isNull);
    });
  });
}

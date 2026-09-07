import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/domain/growth_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The plan cards state prices. Getting one wrong is not a layout bug — it is
/// the app telling a supplier the wrong cost of doing business.

BillingPlan _plan({
  String lookupKey = 'credits-10',
  int pricePence = 1000,
  String interval = 'ONE_TIME',
  int? credits = 10,
}) => BillingPlan.fromJson({
  'id': 'p-$lookupKey',
  'lookupKey': lookupKey,
  'name': lookupKey,
  'pricePence': pricePence,
  'interval': interval,
  'credits': credits,
});

final _subscription = _plan(
  lookupKey: 'supplier-monthly',
  pricePence: 29900,
  interval: 'MONTH',
  credits: null,
);
final _credits = _plan();
final _live = [_credits, _subscription];

void main() {
  group('matching a server plan to a model', () {
    test('matches on SHAPE, not on lookupKey', () {
      // Renaming a plan in the seed must not silently empty a card.
      final renamed = _plan(
        lookupKey: 'supplier-pro-2027',
        pricePence: 29900,
        interval: 'MONTH',
        credits: null,
      );
      expect(
        GrowthModel.subscription.planFrom([renamed])?.pricePence,
        29900,
      );
    });

    test('the credit pack is matched by granting credits', () {
      expect(GrowthModel.credits.planFrom(_live)?.lookupKey, 'credits-10');
    });

    test('commission never matches a plan, whatever the server sends', () {
      // There is no commission machinery at all; the card is static copy.
      expect(GrowthModel.commission.planFrom(_live), isNull);
    });

    test('an empty plan list does not throw', () {
      for (final m in GrowthModel.values) {
        expect(m.planFrom(const []), isNull);
      }
    });
  });

  group('prices', () {
    test('subscription reads its price and interval from the server', () {
      expect(GrowthModel.subscription.priceLabelFrom(_live), '£299.00');
      expect(GrowthModel.subscription.priceSuffixFrom(_live), '/mo');
    });

    test('the credit pack is labelled per LEAD, as the design does', () {
      expect(GrowthModel.credits.priceSuffixFrom(_live), '/lead');
    });

    test('the per-lead note divides the pack — it is NOT the pack price', () {
      // credits-10 is £10.00 for TEN credits, so a lead costs £1.00. Printing
      // the pack price against '/lead' would overstate it tenfold.
      expect(
        GrowthModel.credits.priceNoteFrom(_live),
        '£1.00 per lead · pack of 10',
      );
    });

    test('a differently sized pack divides correctly', () {
      final pack = _plan(pricePence: 4500, credits: 50);
      expect(
        GrowthModel.credits.priceNoteFrom([pack]),
        '£0.90 per lead · pack of 50',
      );
    });

    test('a subscription has no per-lead note', () {
      expect(GrowthModel.subscription.priceNoteFrom(_live), isNull);
    });

    test('commission is static and needs no server data', () {
      expect(GrowthModel.commission.priceLabelFrom(const []), '5%');
      expect(GrowthModel.commission.priceSuffixFrom(const []), '/transaction');
      expect(GrowthModel.commission.priceNoteFrom(const []), isNull);
    });

    test('a missing plan shows a dash, never a made-up figure or £0.00', () {
      // If the server stops returning the subscription, the card must not
      // claim it is free.
      expect(GrowthModel.subscription.priceLabelFrom(const []), '—');
      expect(GrowthModel.credits.priceLabelFrom(const []), '—');
    });
  });

  group('presentation', () {
    test('exactly one model is recommended', () {
      final flagged = GrowthModel.values.where((m) => m.recommended);
      expect(flagged, hasLength(1));
      expect(flagged.single, GrowthModel.credits);
    });

    test('every model has copy and at least two features', () {
      for (final m in GrowthModel.values) {
        expect(m.title, isNotEmpty);
        expect(m.description, isNotEmpty);
        expect(m.features.length, greaterThanOrEqualTo(2));
      }
    });
  });
}

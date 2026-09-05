import 'package:autonect/domain/conflict_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = <String, ConflictKind>{
    'Request is not open (or not yours)': ConflictKind.requestNotOpen,
    'Offer is no longer acceptable': ConflictKind.offerNotAcceptable,
    'Request already has an accepted offer':
        ConflictKind.requestAlreadyAccepted,
    'Order cannot be cancelled at PREPARING': ConflictKind.notCancellable,
    'Order changed concurrently — retry': ConflictKind.staleRead,
    'Resource already exists': ConflictKind.alreadyExists,
    'You have already reviewed this order': ConflictKind.alreadyReviewed,
    'You can review only after delivery': ConflictKind.notDeliveredYet,
  };

  group('classifyConflict', () {
    cases.forEach((message, kind) {
      test('"$message" -> $kind', () {
        expect(classifyConflict(message), kind);
      });
    });

    test('matches the interpolated transition message by substring', () {
      expect(
        classifyConflict('Illegal transition PREPARING → DELIVERED'),
        ConflictKind.illegalTransition,
      );
      expect(
        classifyConflict('Illegal transition PLACED → DELIVERED'),
        ConflictKind.illegalTransition,
      );
    });

    test('matches the interpolated cancel message for every status', () {
      expect(
        classifyConflict('Order cannot be cancelled at OUT_FOR_DELIVERY'),
        ConflictKind.notCancellable,
      );
    });

    test('an unrecognised message falls back to other', () {
      expect(classifyConflict('Something else entirely'), ConflictKind.other);
      expect(classifyConflict(''), ConflictKind.other);
    });
  });
}

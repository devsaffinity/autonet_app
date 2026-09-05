import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/domain/order_transitions.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a role's UI would let the user send: the supplier's forward step plus
/// whichever cancels that role is allowed.
bool allowed(OrderStatus from, OrderStatus to, {required bool supplier}) {
  if (to == OrderStatus.cancelled) {
    return supplier
        ? OrderTransitions.canSupplierCancel(from)
        : OrderTransitions.canBuyerCancel(from);
  }
  return supplier && OrderTransitions.supplierNext(from) == to;
}

void main() {
  const legalSupplier = <String>{
    'PLACED>PREPARING',
    'PREPARING>OUT_FOR_DELIVERY',
    'OUT_FOR_DELIVERY>DELIVERED',
    'PLACED>CANCELLED',
    'PREPARING>CANCELLED',
  };
  const legalBuyer = <String>{'PLACED>CANCELLED'};

  group('the full 5x5 transition table', () {
    for (final from in OrderStatus.values) {
      for (final to in OrderStatus.values) {
        final key = '${from.wire}>${to.wire}';
        test('$key supplier=${legalSupplier.contains(key)}', () {
          expect(
            allowed(from, to, supplier: true),
            legalSupplier.contains(key),
          );
        });
        test('$key buyer=${legalBuyer.contains(key)}', () {
          expect(allowed(from, to, supplier: false), legalBuyer.contains(key));
        });
      }
    }
  });

  group('OrderTransitions', () {
    test('DELIVERED and CANCELLED are absent as keys, so they are terminal', () {
      expect(OrderTransitions.supplierForward.containsKey(OrderStatus.delivered),
          isFalse);
      expect(OrderTransitions.supplierForward.containsKey(OrderStatus.cancelled),
          isFalse);
      expect(OrderTransitions.supplierNext(OrderStatus.delivered), isNull);
      expect(OrderTransitions.supplierNext(OrderStatus.cancelled), isNull);
    });

    test('canBuyerCancel is true ONLY at PLACED', () {
      for (final s in OrderStatus.values) {
        expect(
          OrderTransitions.canBuyerCancel(s),
          s == OrderStatus.placed,
          reason: s.wire,
        );
      }
    });

    test('a null status enables nothing', () {
      expect(OrderTransitions.canBuyerCancel(null), isFalse);
      expect(OrderTransitions.canSupplierCancel(null), isFalse);
      expect(OrderTransitions.supplierNext(null), isNull);
    });
  });
}

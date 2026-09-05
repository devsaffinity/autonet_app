import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// One table per enum: the wire strings in declaration order, checked in both
/// directions, plus the three inputs that must degrade to null rather than
/// throw — an unknown member, a null and an empty string.
void expectWires<T>(
  String name,
  List<T> values,
  List<String> wires,
  T? Function(String?) fromWire,
  String Function(T) wireOf,
) {
  test('$name round-trips every wire value and degrades on the rest', () {
    expect(values.map(wireOf).toList(), wires);
    for (var i = 0; i < wires.length; i++) {
      expect(fromWire(wires[i]), values[i], reason: '$name.${wires[i]}');
    }
    expect(fromWire('NOT_A_REAL_MEMBER'), isNull);
    expect(fromWire(null), isNull);
    expect(fromWire(''), isNull);
  });
}

void main() {
  expectWires('Region', Region.values, const [
    'LONDON',
    'SOUTH_EAST',
    'SOUTH_WEST',
    'EAST_OF_ENGLAND',
    'EAST_MIDLANDS',
    'WEST_MIDLANDS',
    'NORTH_EAST',
    'NORTH_WEST',
    'YORKSHIRE',
    'SCOTLAND',
    'WALES',
    'NORTHERN_IRELAND',
  ], Region.fromWire, (e) => e.wire);

  expectWires('PartCondition', PartCondition.values,
      const ['NEW', 'USED', 'EITHER'], PartCondition.fromWire, (e) => e.wire);

  expectWires('RequestUrgency', RequestUrgency.values,
      const ['URGENT', 'STANDARD', 'LOW'], RequestUrgency.fromWire, (e) => e.wire);

  expectWires('RequestStatus', RequestStatus.values,
      const ['OPEN', 'CLOSED', 'CANCELLED'], RequestStatus.fromWire, (e) => e.wire);

  expectWires('CloseAction', CloseAction.values, const ['CLOSE', 'CANCEL'],
      CloseAction.fromWire, (e) => e.wire);

  expectWires('ModelSource', ModelSource.values,
      const ['PROVIDER', 'MANUAL_REQUIRED', 'MANUAL'], ModelSource.fromWire, (e) => e.wire);

  expectWires('VehicleSource', VehicleSource.values,
      const ['DVLA', 'MANUAL', 'THIRD_PARTY'], VehicleSource.fromWire, (e) => e.wire);

  expectWires('OrderStatus', OrderStatus.values,
      const ['PLACED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'],
      OrderStatus.fromWire, (e) => e.wire);

  expectWires('OfferStatus', OfferStatus.values,
      const ['PENDING', 'ACCEPTED', 'REJECTED', 'WITHDRAWN'], OfferStatus.fromWire,
      (e) => e.wire);

  expectWires('DeliveryOption', DeliveryOption.values,
      const ['STANDARD', 'EXPRESS', 'LOCAL_PICKUP'], DeliveryOption.fromWire, (e) => e.wire);

  expectWires('StockStatus', StockStatus.values,
      const ['IN_STOCK', 'LOW_STOCK', 'ON_ORDER'], StockStatus.fromWire, (e) => e.wire);

  test('CloseAction sends the verb, never the resulting status', () {
    // PATCH /v1/requests/{id} takes CLOSE|CANCEL. Sending the status strings
    // 'CLOSED'/'CANCELLED' is a 400 — this assertion is why the two enums are
    // separate types.
    expect(CloseAction.close.wire, 'CLOSE');
    expect(CloseAction.cancel.wire, 'CANCEL');
    expect(CloseAction.values.map((e) => e.wire), isNot(contains('CLOSED')));
    expect(CloseAction.values.map((e) => e.wire), isNot(contains('CANCELLED')));
  });

  test('the stepper path is the four forward statuses, cancelled excluded', () {
    expect(OrderStatus.forwardPath, const [
      OrderStatus.placed,
      OrderStatus.preparing,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ]);
    expect(OrderStatus.forwardPath, isNot(contains(OrderStatus.cancelled)));
  });

  test('upload constraints mirror the backend UPLOAD constants', () {
    expect(kImageMimeTypes, const ['image/jpeg', 'image/png', 'image/webp']);
    expect(kMaxRequestImages, 5);
    expect(kMaxImageBytes, 5242880);
  });

  test('labels are the buyer-facing copy, never the wire string', () {
    expect(Region.eastOfEngland.label, 'East of England');
    expect(Region.northernIreland.label, 'Northern Ireland');
    expect(PartCondition.values.map((e) => e.label), ['New', 'Used', 'Either']);
    expect(RequestUrgency.standard.label, 'Standard');
    expect(RequestStatus.values.map((e) => e.label), ['Open', 'Closed', 'Cancelled']);
    expect(OrderStatus.values.map((e) => e.label), [
      'Order Placed',
      'Preparing Order',
      'Out for Delivery',
      'Delivered',
      'Cancelled',
    ]);
    expect(DeliveryOption.values.map((e) => e.label),
        ['Standard delivery', 'Express', 'Local pickup']);
    expect(StockStatus.values.map((e) => e.label), ['In stock', 'Low stock', 'On order']);
    for (final r in Region.values) {
      expect(r.label, isNotEmpty);
      expect(r.label, isNot(equals(r.wire)));
    }
  });
}

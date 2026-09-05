import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/request_enums.dart';

/// One row of an order's history (`OrderStatusEvent`), returned ascending by
/// `at` (ORDER_INCLUDE at orders.service.ts:25).
///
/// [byUserId] is nullable and may be an admin the buyer cannot resolve to a
/// person, so never render it as a name.
class OrderEvent {
  const OrderEvent({
    required this.id,
    required this.orderId,
    required this.at,
    this.status,
    this.note,
    this.byUserId,
  });

  final String id, orderId;
  final OrderStatus? status;
  final String? note, byUserId;
  final DateTime at;

  factory OrderEvent.fromJson(Map<String, dynamic> j) => OrderEvent(
    id: jsonString(j, 'id'),
    orderId: jsonString(j, 'orderId'),
    status: OrderStatus.fromWire(j['status'] as String?),
    note: j['note'] as String?,
    byUserId: j['byUserId'] as String?,
    at: DateTime.parse(jsonString(j, 'at')),
  );
}

/// The offer projection embedded in an order (orders.service.ts:14-23).
/// A SEPARATE type from `Offer`, because this projection deliberately omits
/// `stockStatus`, `notes` and the offer's own `status`; reusing a
/// nullable-riddled `Offer` here would hide those omissions.
class OrderOfferRef {
  const OrderOfferRef({
    required this.id,
    required this.pricePence,
    required this.quantity,
    this.condition,
    this.warrantyMonths,
    this.deliveryOption,
    this.deliveryTimeDays,
  });

  final String id;
  final int pricePence, quantity;
  final PartCondition? condition;
  final int? warrantyMonths, deliveryTimeDays;
  final DeliveryOption? deliveryOption;

  factory OrderOfferRef.fromJson(Map<String, dynamic> j) => OrderOfferRef(
    id: jsonString(j, 'id'),
    pricePence: (j['pricePence'] as num?)?.toInt() ?? 0,
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
    condition: PartCondition.fromWire(j['condition'] as String?),
    warrantyMonths: (j['warrantyMonths'] as num?)?.toInt(),
    deliveryOption: DeliveryOption.fromWire(j['deliveryOption'] as String?),
    deliveryTimeDays: (j['deliveryTimeDays'] as num?)?.toInt(),
  );
}

/// The `{id, partName, regNumber}` request projection on an order.
class OrderRequestRef {
  const OrderRequestRef({
    required this.id,
    required this.partName,
    required this.regNumber,
  });

  final String id, partName, regNumber;

  factory OrderRequestRef.fromJson(Map<String, dynamic> j) => OrderRequestRef(
    id: jsonString(j, 'id'),
    partName: jsonString(j, 'partName'),
    regNumber: jsonString(j, 'regNumber'),
  );
}

/// `POST /v1/offers/{id}/accept`, `GET /v1/orders`, `GET /v1/orders/{id}` and
/// `PATCH /v1/orders/{id}/status` all return this shape.
///
/// [totalPence] is copied verbatim from the accepted offer's `pricePence`;
/// there is no delivery-fee column anywhere in the schema to add to it. There
/// is also no supplier name — ORDER_INCLUDE carries no supplier relation, so do
/// not invent a field for one.
class Order {
  const Order({
    required this.id,
    required this.offerId,
    required this.requestId,
    required this.buyerId,
    required this.supplierId,
    required this.totalPence,
    required this.createdAt,
    required this.updatedAt,
    required this.offer,
    required this.request,
    required this.events,
    this.deliveryMethod,
    this.deliveryLocation,
    this.etaDays,
    this.status,
    this.cancelReason,
    this.cancelledById,
  });

  final String id, offerId, requestId, buyerId, supplierId;
  final int totalPence;
  final DeliveryOption? deliveryMethod;
  final String? deliveryLocation, cancelReason, cancelledById;
  final int? etaDays;
  final OrderStatus? status;
  final DateTime createdAt, updatedAt;
  final OrderOfferRef offer;
  final OrderRequestRef request;
  final List<OrderEvent> events;

  factory Order.fromJson(Map<String, dynamic> j) {
    final events = j['events'];
    return Order(
      id: jsonString(j, 'id'),
      offerId: jsonString(j, 'offerId'),
      requestId: jsonString(j, 'requestId'),
      buyerId: jsonString(j, 'buyerId'),
      supplierId: jsonString(j, 'supplierId'),
      totalPence: (j['totalPence'] as num?)?.toInt() ?? 0,
      deliveryMethod: DeliveryOption.fromWire(j['deliveryMethod'] as String?),
      deliveryLocation: j['deliveryLocation'] as String?,
      etaDays: (j['etaDays'] as num?)?.toInt(),
      status: OrderStatus.fromWire(j['status'] as String?),
      cancelReason: j['cancelReason'] as String?,
      cancelledById: j['cancelledById'] as String?,
      createdAt: DateTime.parse(jsonString(j, 'createdAt')),
      updatedAt: DateTime.parse(jsonString(j, 'updatedAt')),
      offer: OrderOfferRef.fromJson((j['offer'] as Map).cast<String, dynamic>()),
      request: OrderRequestRef.fromJson(
        (j['request'] as Map).cast<String, dynamic>(),
      ),
      events: events is List
          ? events
                .map((e) => OrderEvent.fromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false)
          : const <OrderEvent>[],
    );
  }
}

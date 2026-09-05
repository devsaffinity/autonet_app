import 'package:autonect/data/models/request_enums.dart' show enumFromWire;

/// Wire enums for the offer → order half of the funnel. `enumFromWire` is
/// imported rather than re-declared so both enum files share one
/// unknown-value policy.
enum OrderStatus {
  placed('PLACED', 'Order Placed'),
  preparing('PREPARING', 'Preparing Order'),
  outForDelivery('OUT_FOR_DELIVERY', 'Out for Delivery'),
  delivered('DELIVERED', 'Delivered'),
  cancelled('CANCELLED', 'Cancelled');

  const OrderStatus(this.wire, this.label);
  final String wire;
  final String label;

  /// The four stepper rows, in the order the backend advances through them.
  /// CANCELLED is deliberately absent: it is a terminal branch off the path,
  /// not a step on it.
  static const List<OrderStatus> forwardPath = [
    placed,
    preparing,
    outForDelivery,
    delivered,
  ];

  /// There is no `unknown` member on purpose — it would make every switch
  /// quietly satisfiable. An unrecognised wire value surfaces as a null field
  /// on the model instead.
  static OrderStatus? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

enum OfferStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED'),
  withdrawn('WITHDRAWN');

  const OfferStatus(this.wire);
  final String wire;

  static OfferStatus? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

enum DeliveryOption {
  standard('STANDARD', 'Standard delivery'),
  express('EXPRESS', 'Express'),
  localPickup('LOCAL_PICKUP', 'Local pickup');

  const DeliveryOption(this.wire, this.label);
  final String wire;
  final String label;

  static DeliveryOption? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

enum StockStatus {
  inStock('IN_STOCK', 'In stock'),
  lowStock('LOW_STOCK', 'Low stock'),
  onOrder('ON_ORDER', 'On order');

  const StockStatus(this.wire, this.label);
  final String wire;
  final String label;

  static StockStatus? fromWire(String? v) => enumFromWire(values, v, (e) => e.wire);
}

import 'package:autonect/data/models/order_enums.dart';

/// Which order-status buttons a given role may press, mirroring the guards in
/// autonect-backend orders.service.ts:135-152.
///
/// USED ONLY to decide which button is ENABLED — never to decide which state
/// can exist. An admin can force any status (admin-marketplace.routes.ts), so
/// treating this table as a description of reachable states would make the app
/// throw on a perfectly legal server response.
abstract final class OrderTransitions {
  /// The supplier's one-step-forward map.
  ///
  /// DELIVERED and CANCELLED are absent AS KEYS, and that absence is what makes
  /// them terminal — there is no 'isTerminal' flag to forget to update.
  static const Map<OrderStatus, OrderStatus> supplierForward = {
    OrderStatus.placed: OrderStatus.preparing,
    OrderStatus.preparing: OrderStatus.outForDelivery,
    OrderStatus.outForDelivery: OrderStatus.delivered,
  };

  /// The buyer may only ever send CANCELLED, and only from PLACED
  /// (orders.service.ts:139-143). Once a supplier is preparing, cancelling is a
  /// conversation, not a button.
  static bool canBuyerCancel(OrderStatus? s) => s == OrderStatus.placed;

  static bool canSupplierCancel(OrderStatus? s) =>
      s == OrderStatus.placed || s == OrderStatus.preparing;

  /// null when [s] is null, terminal, or a status with no forward step.
  static OrderStatus? supplierNext(OrderStatus? s) =>
      s == null ? null : supplierForward[s];
}

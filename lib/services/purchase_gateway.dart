import 'package:autonect/data/models/billing_checkout.dart';

/// How a store purchase ended. Sealed so a caller that forgets one does not
/// compile.
sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

/// The store took the payment. The PURCHASE is not proven by this — the
/// server reads it back from RevenueCat before anything is granted.
final class PurchaseCompleted extends PurchaseOutcome {
  const PurchaseCompleted();
}

/// The customer backed out of the store sheet. Nothing was charged.
final class PurchaseCancelled extends PurchaseOutcome {
  const PurchaseCancelled();
}

/// The store refused: declined card, parental controls, already owned.
final class PurchaseFailed extends PurchaseOutcome {
  const PurchaseFailed([this.message]);

  /// The store's own wording where it gave one.
  final String? message;
}

/// The product is not on sale on this device — missing from the store
/// listing, not released to this track, or the wrong country. Distinct from a
/// failure because it is OUR configuration that is wrong, not the payment.
final class PurchaseUnavailable extends PurchaseOutcome {
  const PurchaseUnavailable([this.message]);

  final String? message;
}

/// Google Play / App Store purchases, behind an interface so every controller
/// and screen test runs without a store or a platform channel.
/// `revenuecat_purchase_gateway.dart` is the only file that imports the SDK.
abstract class PurchaseGateway {
  /// False where store billing cannot run (web, desktop): purchases are
  /// refused with an explanation instead of failing inside the plugin.
  bool get isSupported;

  /// Points the SDK at our RevenueCat project and identifies the customer as
  /// THIS user, so entitlements follow the account rather than the device.
  /// Idempotent; never throws — false on failure.
  Future<bool> configure(BillingConfig config, {required String appUserId});

  /// Opens the store's purchase sheet for [storeProductId]. Never throws.
  Future<PurchaseOutcome> buy(String storeProductId);

  /// Re-attaches purchases already made with this store account — a reinstall,
  /// a new phone, or a support case. Apple requires it to exist.
  Future<PurchaseOutcome> restore();
}

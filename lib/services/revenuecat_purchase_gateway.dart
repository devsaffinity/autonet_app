import 'package:autonect/data/models/billing_checkout.dart';
import 'package:autonect/services/purchase_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// The ONLY file that imports the RevenueCat SDK.
///
/// Everything else talks to [PurchaseGateway], so the purchase flow is
/// testable without a store account, and swapping provider again would touch
/// this file and nothing else.
class RevenueCatPurchaseGateway implements PurchaseGateway {
  String? _configuredFor;

  @override
  bool get isSupported =>
      // defaultTargetPlatform reports "android" inside Chrome on a phone, so
      // kIsWeb is what actually rules the web out.
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> configure(BillingConfig config, {required String appUserId}) async {
    if (!isSupported) return false;
    final key = defaultTargetPlatform == TargetPlatform.iOS ? config.iosApiKey : config.androidApiKey;
    if (key == null || key.isEmpty) return false;
    // Already pointed at this customer: re-configuring would drop the cache
    // for nothing.
    if (_configuredFor == appUserId) return true;
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.warn : LogLevel.error);
      if (_configuredFor == null) {
        // The App User ID is OUR user id, so entitlements belong to the
        // account and survive a reinstall or a new device.
        await Purchases.configure(PurchasesConfiguration(key)..appUserID = appUserId);
      } else {
        // A different user signed in on the same device.
        await Purchases.logIn(appUserId);
      }
      _configuredFor = appUserId;
      return true;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat configure failed: ${e.message}');
      return false;
    }
  }

  @override
  Future<PurchaseOutcome> buy(String storeProductId) async {
    if (!isSupported || _configuredFor == null) {
      return const PurchaseUnavailable();
    }
    try {
      final package = await _findPackage(storeProductId);
      if (package == null) {
        return const PurchaseUnavailable('That plan is not on sale in your store account yet.');
      }
      // purchase(PurchaseParams) — purchasePackage is deprecated in v10.
      await Purchases.purchase(PurchaseParams.package(package));
      return const PurchaseCompleted();
    } on PlatformException catch (e) {
      return _mapError(e);
    }
  }

  @override
  Future<PurchaseOutcome> restore() async {
    if (!isSupported || _configuredFor == null) return const PurchaseUnavailable();
    try {
      await Purchases.restorePurchases();
      return const PurchaseCompleted();
    } on PlatformException catch (e) {
      return _mapError(e);
    }
  }

  /// The package selling [storeProductId], from any offering.
  ///
  /// Play reports a subscription's product as `productId:basePlanId`, so the
  /// comparison is on the part before the colon — the same rule the server
  /// uses when matching a purchase back to a plan.
  Future<Package?> _findPackage(String storeProductId) async {
    final offerings = await Purchases.getOfferings();
    final seen = <Package>[
      ...?offerings.current?.availablePackages,
      for (final offering in offerings.all.values) ...offering.availablePackages,
    ];
    for (final package in seen) {
      final id = package.storeProduct.identifier;
      if (id == storeProductId || id.split(':').first == storeProductId) return package;
    }
    return null;
  }

  PurchaseOutcome _mapError(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    return switch (code) {
      PurchasesErrorCode.purchaseCancelledError => const PurchaseCancelled(),
      PurchasesErrorCode.productAlreadyPurchasedError =>
        // Owned but not reflected here — restoring is the honest next step.
        const PurchaseFailed('You already own this. Use Restore purchases to bring it back.'),
      PurchasesErrorCode.paymentPendingError =>
        const PurchaseCompleted(), // Slow payment methods settle later; the server confirms.
      PurchasesErrorCode.purchaseNotAllowedError =>
        const PurchaseFailed('Purchases are not allowed on this device or account.'),
      PurchasesErrorCode.productNotAvailableForPurchaseError => const PurchaseUnavailable(),
      PurchasesErrorCode.networkError => const PurchaseFailed('No connection to the store. Please try again.'),
      PurchasesErrorCode.storeProblemError => const PurchaseFailed('The store had a problem. Please try again shortly.'),
      _ => PurchaseFailed(e.message),
    };
  }
}

/// `GET /v1/billing/config` — what the app needs before it can open a store
/// purchase. Only public SDK keys travel; nothing here can move money.
class BillingConfig {
  const BillingConfig({
    this.androidApiKey,
    this.iosApiKey,
    this.entitlement = 'pro',
    this.offering = 'default',
  });

  /// RevenueCat public SDK keys, one per store. Null where that store is not
  /// set up yet, which is why the app checks before offering a purchase.
  final String? androidApiKey;
  final String? iosApiKey;

  /// The entitlement a subscription unlocks, as named in RevenueCat.
  final String entitlement;

  /// Which offering to read packages from.
  final String offering;

  bool get hasAnyKey => (androidApiKey?.isNotEmpty ?? false) || (iosApiKey?.isNotEmpty ?? false);

  factory BillingConfig.fromJson(Map<String, dynamic> j) {
    final android = j['androidApiKey'] as String?;
    final ios = j['iosApiKey'] as String?;
    if ((android == null || android.isEmpty) && (ios == null || ios.isEmpty)) {
      throw const FormatException('billing config without a store key');
    }
    return BillingConfig(
      androidApiKey: android,
      iosApiKey: ios,
      entitlement: j['entitlement'] as String? ?? 'pro',
      offering: j['offering'] as String? ?? 'default',
    );
  }
}

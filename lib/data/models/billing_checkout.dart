/// `GET /v1/billing/config` — what the payment sheet needs before it can open.
/// The publishable key comes from the server so test and live never mix.
class BillingConfig {
  const BillingConfig({
    required this.publishableKey,
    this.merchantDisplayName = 'Autonect',
    this.merchantCountryCode = 'GB',
    this.currency = 'gbp',
  });

  final String publishableKey;
  final String merchantDisplayName;
  final String merchantCountryCode;
  final String currency;

  /// Google Pay runs in test mode exactly when the key is a test key.
  bool get isTestMode => publishableKey.startsWith('pk_test_');

  factory BillingConfig.fromJson(Map<String, dynamic> j) {
    final key = j['publishableKey'];
    if (key is! String || key.isEmpty) {
      throw const FormatException('billing config without a publishable key');
    }
    return BillingConfig(
      publishableKey: key,
      merchantDisplayName: j['merchantDisplayName'] as String? ?? 'Autonect',
      merchantCountryCode: j['merchantCountryCode'] as String? ?? 'GB',
      currency: j['currency'] as String? ?? 'gbp',
    );
  }
}

/// One opening of the payment sheet, from `POST /v1/billing/credits/intent`,
/// `/subscriptions` or `/subscriptions/retry-payment`.
///
/// It carries nothing that decides an outcome: whether the purchase worked is
/// read back from the server afterwards (`POST /v1/billing/sync`).
class PaymentSheetSession {
  const PaymentSheetSession({
    required this.isSubscription,
    required this.requiresPayment,
    required this.customerId,
    required this.customerSessionClientSecret,
    required this.planLookupKey,
    required this.planName,
    required this.amountPence,
    this.clientSecret,
    this.paymentIntentId,
    this.subscriptionId,
    this.ephemeralKeySecret,
  });

  final bool isSubscription;

  /// False when nothing is owed now (an upgrade charged to the card on file).
  final bool requiresPayment;
  final String? clientSecret;
  final String? paymentIntentId;

  /// OUR subscription id — what /sync takes.
  final String? subscriptionId;
  final String customerId;
  final String customerSessionClientSecret;
  final String? ephemeralKeySecret;
  final String planLookupKey;
  final String planName;
  final int amountPence;

  factory PaymentSheetSession.fromJson(Map<String, dynamic> j) {
    final plan = j['plan'] is Map ? j['plan'] as Map : const {};
    final requiresPayment = j['requiresPayment'] == true;
    final clientSecret = j['clientSecret'] as String?;
    if (requiresPayment && (clientSecret == null || clientSecret.isEmpty)) {
      throw const FormatException('payment session without a client secret');
    }
    return PaymentSheetSession(
      isSubscription: j['mode'] == 'subscription',
      requiresPayment: requiresPayment,
      clientSecret: clientSecret,
      paymentIntentId: j['paymentIntentId'] as String?,
      subscriptionId: j['subscriptionId'] as String?,
      customerId: j['customerId'] as String? ?? '',
      customerSessionClientSecret: j['customerSessionClientSecret'] as String? ?? '',
      ephemeralKeySecret: j['ephemeralKeySecret'] as String?,
      planLookupKey: plan['lookupKey'] as String? ?? '',
      planName: plan['name'] as String? ?? '',
      amountPence: (j['amountPence'] as num?)?.toInt() ?? 0,
    );
  }
}

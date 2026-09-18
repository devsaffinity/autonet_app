import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/data/models/billing_checkout.dart';
import 'package:autonect/services/payment_sheet_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Where Stripe returns after a bank's 3-D Secure page — the `autonect`
/// scheme registered in Info.plist.
const String kStripeReturnUrl = 'autonect://stripe-redirect';

/// THE only file that imports flutter_stripe.
class StripePaymentSheetGateway implements PaymentSheetGateway {
  String? _configuredKey;

  @override
  bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> configure(BillingConfig config) async {
    if (_configuredKey == config.publishableKey) return true;
    try {
      Stripe.publishableKey = config.publishableKey;
      Stripe.urlScheme = 'autonect';
      await Stripe.instance.applySettings();
      _configuredKey = config.publishableKey;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PaymentSheetOutcome> present(PaymentSheetSession session, BillingConfig config) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: config.merchantDisplayName,
          paymentIntentClientSecret: session.clientSecret,
          customerId: session.customerId,
          customerSessionClientSecret: session.customerSessionClientSecret,
          returnURL: kStripeReturnUrl,
          // A credit pack must land in seconds, not after a bank transfer.
          allowsDelayedPaymentMethods: false,
          style: ThemeMode.light,
          googlePay: PaymentSheetGooglePay(
            merchantCountryCode: config.merchantCountryCode,
            currencyCode: config.currency.toUpperCase(),
            testEnv: config.isTestMode,
          ),
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: kSecondaryColor),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return const PaymentCompleted();
    } on StripeException catch (e) {
      return mapStripeError(e.error.code, e.error.localizedMessage ?? e.error.message);
    } catch (_) {
      return const PaymentFailed();
    }
  }

  @visibleForTesting
  static PaymentSheetOutcome mapStripeError(FailureCode code, String? message) => switch (code) {
    FailureCode.Canceled => const PaymentCancelled(),
    FailureCode.Timeout => const PaymentFailed('The payment took too long. Please try again.'),
    FailureCode.Failed || FailureCode.Unknown => PaymentFailed(message),
  };
}

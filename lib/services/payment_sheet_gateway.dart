import 'package:autonect/data/models/billing_checkout.dart';

/// How a payment sheet ended. Sealed so a caller that forgets one does not compile.
sealed class PaymentSheetOutcome {
  const PaymentSheetOutcome();
}

/// The customer confirmed and Stripe accepted the payment details. The
/// PURCHASE is not proven by this — it is read back from the server.
final class PaymentCompleted extends PaymentSheetOutcome {
  const PaymentCompleted();
}

/// The customer closed the sheet. Nothing was charged.
final class PaymentCancelled extends PaymentSheetOutcome {
  const PaymentCancelled();
}

final class PaymentFailed extends PaymentSheetOutcome {
  const PaymentFailed([this.message]);

  /// Stripe's own, customer-facing wording when it gave one.
  final String? message;
}

/// Stripe's payment sheet, behind an interface so every controller and screen
/// test runs without a platform channel. `stripe_payment_sheet_gateway.dart`
/// is the only file that imports flutter_stripe.
abstract class PaymentSheetGateway {
  /// False where the sheet cannot run (web, desktop): purchases are refused
  /// with an explanation instead of failing inside the plugin.
  bool get isSupported;

  /// Sets the publishable key. Idempotent; never throws — false on failure.
  Future<bool> configure(BillingConfig config);

  /// Opens the sheet for [session] and reports how it ended. Never throws.
  Future<PaymentSheetOutcome> present(PaymentSheetSession session, BillingConfig config);
}

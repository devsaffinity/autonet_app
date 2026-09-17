import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_plan.dart';

/// Repository for role-based billing, subscriptions, credit purchases, and wallet.
abstract class BillingRepository {
  /// Fetches active plans available for the caller's role.
  Future<ApiResult<List<BillingPlan>>> plans();

  /// Initiates Stripe Checkout for a subscription plan (e.g. 'electrician-pro-monthly').
  /// Returns a checkout session map containing the hosted checkout `url`.
  Future<ApiResult<Map<String, dynamic>>> subscribe(String lookupKey);

  /// Initiates Stripe Checkout for a one-time credit pack (e.g. 'electrician-lead-1').
  /// Returns a checkout session map containing the hosted checkout `url`.
  Future<ApiResult<Map<String, dynamic>>> purchaseCredits(String lookupKey);

  /// Schedules cancellation of the active subscription at the period end.
  Future<ApiResult<Map<String, dynamic>>> cancelSubscription();

  /// Reads current credit balance, subscription state, and recent ledger transactions.
  Future<ApiResult<Map<String, dynamic>>> wallet();
}

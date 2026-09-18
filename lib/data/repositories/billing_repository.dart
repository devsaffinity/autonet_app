import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_checkout.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/models/billing_status.dart';

/// Provider billing — both roles — over `/v1/billing`.
///
/// Purchases open Stripe's payment sheet INSIDE the app: the server creates
/// the PaymentIntent or subscription ([createCreditsIntent],
/// [createSubscription], [retryPayment]), the sheet collects the card, and the
/// outcome is read back from the server ([sync], [status]) — never taken from
/// the sheet's own word.
abstract class BillingRepository {
  /// Active plans for the caller's role — used where only prices are needed
  /// (the registration wizard); the plan screen reads [status] instead.
  Future<ApiResult<List<BillingPlan>>> plans();

  /// Publishable key and merchant details for the payment sheet.
  Future<ApiResult<BillingConfig>> config();

  /// Level, subscription, display state, allowed actions, and every plan with
  /// its verdict.
  Future<ApiResult<BillingStatus>> status();

  /// After the sheet closes: the server asks Stripe what happened and applies it.
  Future<ApiResult<BillingStatus>> sync({String? paymentIntentId, String? subscriptionId});

  Future<ApiResult<PaymentSheetSession>> createCreditsIntent(String lookupKey);

  /// New subscription or an upgrade — the server decides which.
  Future<ApiResult<PaymentSheetSession>> createSubscription(String lookupKey);

  /// A sheet for a failed renewal; paying it saves the new card.
  Future<ApiResult<PaymentSheetSession>> retryPayment();

  /// Cancel at period end — access continues until the date shown.
  Future<ApiResult<BillingStatus>> cancelSubscription();

  /// Undo a scheduled cancellation.
  Future<ApiResult<BillingStatus>> resumeSubscription();

  /// Credit balance, subscription and recent ledger (the credits history screen).
  Future<ApiResult<Map<String, dynamic>>> wallet();
}

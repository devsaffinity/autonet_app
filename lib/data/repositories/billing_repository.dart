import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_checkout.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/models/billing_status.dart';

/// Provider billing — both roles — over `/v1/billing`.
///
/// Purchases are made by the STORE (Google Play / App Store) through
/// RevenueCat. The server is what confirms them: the app calls [sync] once
/// the store sheet closes, and the server reads the customer back from
/// RevenueCat before granting anything. Nothing here takes the app's word.
abstract class BillingRepository {
  /// Active plans for the caller's role — used where only prices are needed
  /// (the registration wizard); the plans screen reads [status] instead.
  Future<ApiResult<List<BillingPlan>>> plans();

  /// Public store SDK keys and the entitlement to look for.
  Future<ApiResult<BillingConfig>> config();

  /// Level, subscription, display state, allowed actions, and every plan with
  /// its verdict and store product id.
  Future<ApiResult<BillingStatus>> status();

  /// After the store sheet closes, or after restoring: the server re-reads
  /// RevenueCat and applies whatever the customer actually owns.
  Future<ApiResult<BillingStatus>> sync();

  /// Credit balance, subscription and recent ledger (the credits screen).
  Future<ApiResult<Map<String, dynamic>>> wallet();
}

import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_plan.dart';

/// `GET /v1/billing/plans`.
///
/// Read-only, deliberately. Purchasing goes through Stripe Checkout, which
/// answers with a hosted URL — and the app has no url_launcher, no webview and
/// no registered URL scheme, so there is nothing here that could open it.
/// Adding a `subscribe` method would put a button in the UI that cannot work.
abstract class BillingRepository {
  Future<ApiResult<List<BillingPlan>>> plans();
}

import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/repositories/billing_repository.dart';

class BillingApiRepository implements BillingRepository {
  BillingApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  @override
  Future<ApiResult<List<BillingPlan>>> plans() => _c.send(
        method: 'GET',
        path: '/v1/billing/plans',
        decode: (d) => [
          for (final p in d as List)
            BillingPlan.fromJson((p as Map).cast<String, dynamic>()),
        ],
      );

  @override
  Future<ApiResult<Map<String, dynamic>>> subscribe(String lookupKey) => _c.send(
        method: 'POST',
        path: '/v1/billing/subscribe',
        body: {'lookupKey': lookupKey},
        decode: (d) => (d as Map).cast<String, dynamic>(),
      );

  @override
  Future<ApiResult<Map<String, dynamic>>> purchaseCredits(String lookupKey) =>
      _c.send(
        method: 'POST',
        path: '/v1/billing/credits/purchase',
        body: {'lookupKey': lookupKey},
        decode: (d) => (d as Map).cast<String, dynamic>(),
      );

  @override
  Future<ApiResult<Map<String, dynamic>>> cancelSubscription() => _c.send(
        method: 'POST',
        path: '/v1/billing/subscription/cancel',
        decode: (d) => (d as Map).cast<String, dynamic>(),
      );

  @override
  Future<ApiResult<Map<String, dynamic>>> wallet() => _c.send(
        method: 'GET',
        path: '/v1/billing/wallet',
        decode: (d) => (d as Map).cast<String, dynamic>(),
      );
}

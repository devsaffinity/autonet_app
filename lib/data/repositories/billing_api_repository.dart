import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/billing_checkout.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/data/repositories/billing_repository.dart';

class BillingApiRepository implements BillingRepository {
  BillingApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  static Map<String, dynamic> _map(Object? d) => (d as Map).cast<String, dynamic>();
  static BillingStatus _status(Object? d) => BillingStatus.fromJson(_map(d));

  @override
  Future<ApiResult<List<BillingPlan>>> plans() => _c.send(
    method: 'GET',
    path: '/v1/billing/plans',
    decode: (d) => [for (final p in d as List) BillingPlan.fromJson(_map(p))],
  );

  @override
  Future<ApiResult<BillingConfig>> config() => _c.send(
    method: 'GET',
    path: '/v1/billing/config',
    decode: (d) => BillingConfig.fromJson(_map(d)),
  );

  @override
  Future<ApiResult<BillingStatus>> status() =>
      _c.send(method: 'GET', path: '/v1/billing/status', decode: _status);

  /// No body: what the app thinks it bought does not matter, the server asks
  /// RevenueCat. Answers with the status that results.
  @override
  Future<ApiResult<BillingStatus>> sync() =>
      _c.send(method: 'POST', path: '/v1/billing/sync', body: const <String, dynamic>{}, decode: _status);

  @override
  Future<ApiResult<Map<String, dynamic>>> wallet() =>
      _c.send(method: 'GET', path: '/v1/billing/wallet', decode: _map);
}

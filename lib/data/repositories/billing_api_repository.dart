import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/repositories/billing_repository.dart';

class BillingApiRepository implements BillingRepository {
  /// [tokens] is accepted but not retained, so main.dart constructs every
  /// repository identically.
  BillingApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  /// The server filters by the caller's role, so a supplier never sees the
  /// electrician plans.
  @override
  Future<ApiResult<List<BillingPlan>>> plans() => _c.send(
    method: 'GET',
    path: '/v1/billing/plans',
    decode: (d) => [
      for (final p in d as List)
        BillingPlan.fromJson((p as Map).cast<String, dynamic>()),
    ],
  );
}

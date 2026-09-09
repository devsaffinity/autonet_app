import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/providers_repository.dart';

class ProvidersApiRepository implements ProvidersRepository {
  /// [tokens] is accepted but not retained — see CatalogApiRepository for why
  /// every buyer repository takes the same pair.
  ProvidersApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  /// PAGINATION.MAX_LIMIT is 100 and the server 400s above it rather than
  /// clamping.
  static const int _maxLimit = 100;

  @override
  Future<ApiResult<Paged<ServiceProvider>>> list({
    int page = 1,
    int limit = 20,
    Region? region,
    String? brand,
    String? q,
  }) => _c.sendEnvelope(
    method: 'GET',
    path: '/v1/providers',
    query: {
      'page': '${page < 1 ? 1 : page}',
      'limit': '${limit.clamp(1, _maxLimit)}',
      // Unlike /v1/requests, every filter here is wrapped in blankToUndefined
      // server-side, so a blank value is tolerated. They are still omitted:
      // an absent key is unambiguous, and this way the two list repositories
      // read the same.
      if (region != null) 'region': region.wire,
      if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    },
    decode: Paged.decoder(ServiceProvider.fromJson),
  );

  @override
  Future<ApiResult<ServiceProvider>> byId(String id) => _c.send(
    method: 'GET',
    path: '/v1/providers/$id',
    decode: (d) => ServiceProvider.fromJson((d as Map).cast<String, dynamic>()),
  );
}

import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/service_provider.dart';

/// `GET /v1/providers` — the approved electrician directory behind the home
/// screen's Service Providers section.
abstract class ProvidersRepository {
  /// Approved providers only; that is the server's set, not a filter a caller
  /// can widen.
  ///
  /// [brand] is matched against the `brands` array EXACTLY, casing included —
  /// Postgres array containment is case-sensitive. Pass a value the API itself
  /// returned rather than something a user typed.
  Future<ApiResult<Paged<ServiceProvider>>> list({
    int page = 1,
    int limit = 20,
    Region? region,
    String? brand,
    String? q,
  });

  /// One provider. 404s for an unknown id AND for one awaiting KYC — the two
  /// are deliberately indistinguishable, so copy must not say 'not found'
  /// in a way that implies the account does not exist.
  Future<ApiResult<ServiceProvider>> byId(String id);
}

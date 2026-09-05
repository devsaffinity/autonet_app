import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/part_category.dart';

/// `GET /v1/categories` — the flat category list the wizard's required
/// `categoryId` is chosen from.
abstract class CatalogRepository {
  /// The list is public reference data the server itself caches for 24h, so the
  /// impl is free to serve a warm copy. Pass [forceRefresh] to bypass that copy
  /// (a pull-to-refresh); it never bypasses the on-disk failure fallback.
  Future<ApiResult<List<PartCategory>>> categories({bool forceRefresh = false});
}

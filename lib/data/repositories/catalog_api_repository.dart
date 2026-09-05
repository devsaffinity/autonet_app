import 'dart:convert';

import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/repositories/catalog_repository.dart';
import 'package:autonect/services/session_store.dart';

/// The ONE repository that answers Ok from a cache after a failed request.
///
/// WHY that is correct here and nowhere else: `categoryId` is required by
/// `POST /v1/requests`, so an unreachable category list is a hard stop on the
/// whole wizard — while the data itself is public reference data the server
/// already serves from a 24-hour cache. Handing back yesterday's list is
/// exactly what the backend would have done; failing the wizard is not.
class CatalogApiRepository implements CatalogRepository {
  /// [tokens] is accepted but not retained: `GET /v1/categories` has no
  /// requireAuth and this repository holds no per-user state. The parameter
  /// exists so main.dart constructs every buyer repository identically.
  CatalogApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  /// Session-lifetime memo. The picker sheet can be opened many times per
  /// wizard and the list changes about never.
  List<PartCategory>? _memo;

  @override
  Future<ApiResult<List<PartCategory>>> categories({
    bool forceRefresh = false,
  }) async {
    final memo = _memo;
    if (!forceRefresh && memo != null) return Ok(memo);

    // Captured inside the decoder so the raw wire list can be persisted without
    // PartCategory needing a toJson it has no other reason to own.
    Object? raw;
    final r = await _c.send(
      method: 'GET',
      path: '/v1/categories',
      authenticated: false,
      decode: (d) {
        raw = d;
        return _decodeList(d);
      },
    );
    switch (r) {
      case Ok(:final value):
        _memo = value;
        SessionStore.categoriesJson = jsonEncode(raw);
        return r;
      case Err(:final error):
        if (!_isTransient(error)) return r;
        final cached = memo ?? _cached();
        return cached == null ? r : Ok(cached);
    }
  }

  /// Only failures a warm list can honestly stand in for. A 4xx means the
  /// request itself was wrong and must surface.
  static bool _isTransient(ApiError e) =>
      e.code == ApiErrorCode.network ||
      e.code == ApiErrorCode.timeout ||
      e.code == ApiErrorCode.internal;

  static List<PartCategory> _decodeList(Object? d) => (d as List)
      .map((e) => PartCategory.fromJson((e as Map).cast<String, dynamic>()))
      .toList(growable: false);

  /// Null on a cold cache, and also on a corrupt one — a half-written list must
  /// degrade to "no cache", never to a thrown decode deep inside a screen.
  List<PartCategory>? _cached() {
    final raw = SessionStore.categoriesJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = _decodeList(jsonDecode(raw));
      _memo = list;
      return list;
    } catch (_) {
      return null;
    }
  }
}

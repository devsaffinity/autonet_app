import 'dart:convert';

import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/page_meta.dart';

/// Pure: no Flutter, no GetX, no http. Every response in the app funnels through
/// here, so this is the one place that knows the success/error envelope shape.
ApiResult<T> decodeEnvelope<T>(
  int statusCode,
  String rawBody,
  T Function(Object? data) decodeData,
) {
  Object? json;
  try {
    json = rawBody.isEmpty ? null : jsonDecode(rawBody);
  } on FormatException {
    return Err(ApiError.malformed('Server returned non-JSON (HTTP $statusCode)'));
  }
  if (json is! Map) {
    if (statusCode == 204) {
      try {
        return Ok(decodeData(null));
      } catch (_) {
        return const Err(ApiError.malformed());
      }
    }
    return Err(ApiError.malformed('Server returned HTTP $statusCode'));
  }
  if (json['success'] == true) {
    // A decoder throwing here (a missing token field, say) must surface as
    // malformed rather than as an uncaught async error deep in a screen.
    try {
      return Ok(decodeData(json['data']));
    } catch (e) {
      return Err(ApiError.malformed('Could not read server payload: $e'));
    }
  }
  final err = json['error'];
  if (err is! Map) {
    return Err(ApiError.malformed('Malformed error envelope (HTTP $statusCode)'));
  }
  return Err(
    ApiError(
      code: ApiErrorCode.fromWire(err['code'] as String?),
      message: (err['message'] as String?) ?? 'Something went wrong',
      statusCode: statusCode,
      fields: FieldError.listFrom(err['details']),
    ),
  );
}

PageMeta? metaOf(String rawBody) {
  try {
    final j = jsonDecode(rawBody);
    if (j is Map && j['meta'] is Map) {
      return PageMeta.fromJson((j['meta'] as Map).cast<String, dynamic>());
    }
  } catch (_) {}
  return null;
}

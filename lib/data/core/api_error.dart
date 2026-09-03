/// Mirrors autonect-backend/src/common/errors/error-codes.ts (all 15) plus
/// five client-only codes that never appear on the wire.
enum ApiErrorCode {
  validationError('VALIDATION_ERROR'),
  unauthorized('UNAUTHORIZED'),
  forbidden('FORBIDDEN'),
  notFound('NOT_FOUND'),
  conflict('CONFLICT'),
  rateLimited('RATE_LIMITED'),
  internal('INTERNAL'),
  invalidCredentials('INVALID_CREDENTIALS'),
  verificationRequired('VERIFICATION_REQUIRED'),
  accountSuspended('ACCOUNT_SUSPENDED'),
  otpInvalid('OTP_INVALID'),
  otpExpired('OTP_EXPIRED'),
  tooManyAttempts('TOO_MANY_ATTEMPTS'),
  insufficientCredits('INSUFFICIENT_CREDITS'),
  notApproved('NOT_APPROVED'),
  network('CLIENT_NETWORK'),
  timeout('CLIENT_TIMEOUT'),
  malformedResponse('CLIENT_MALFORMED'),
  sessionExpired('CLIENT_SESSION_EXPIRED'),
  unknown('CLIENT_UNKNOWN');

  const ApiErrorCode(this.wire);

  final String wire;

  static ApiErrorCode fromWire(String? v) {
    for (final c in ApiErrorCode.values) {
      if (c.wire == v) return c;
    }
    return ApiErrorCode.unknown;
  }
}

class FieldError {
  const FieldError(this.path, this.message);

  final String path;
  final String message;

  /// error.details is an ARRAY of {path,message} — verified live and at
  /// error-handler.ts:32-36 (issue.path.join('.')).
  static List<FieldError> listFrom(Object? details) {
    if (details is! List) return const [];
    final out = <FieldError>[];
    for (final e in details) {
      if (e is Map && e['path'] is String && e['message'] is String) {
        out.add(FieldError(e['path'] as String, e['message'] as String));
      }
    }
    return out;
  }
}

class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    this.statusCode,
    this.fields = const [],
  });

  final ApiErrorCode code;
  final String message;

  /// null for client-only codes — nothing came back from the server.
  final int? statusCode;
  final List<FieldError> fields;

  /// First message per path wins; zod emits several issues per field.
  Map<String, String> get fieldErrors {
    final m = <String, String>{};
    for (final f in fields) {
      m.putIfAbsent(f.path, () => f.message);
    }
    return m;
  }

  /// TRUE only for "the access token is stale".
  /// VERIFIED: auth.ts:25 and :29 -> 401 UNAUTHORIZED for an expired token and
  /// for a ban-denylist hit; auth.service.ts:88 -> 401 INVALID_CREDENTIALS for
  /// bad login creds. Refreshing on the latter burns a rotation for nothing.
  bool get isStaleAccessToken =>
      statusCode == 401 && code == ApiErrorCode.unauthorized;

  const ApiError.network([this.message = 'No internet connection'])
    : code = ApiErrorCode.network,
      statusCode = null,
      fields = const [];

  const ApiError.timeout([this.message = 'The request timed out'])
    : code = ApiErrorCode.timeout,
      statusCode = null,
      fields = const [];

  const ApiError.malformed([this.message = 'Unexpected response from server'])
    : code = ApiErrorCode.malformedResponse,
      statusCode = null,
      fields = const [];

  const ApiError.sessionExpired([
    this.message = 'Your session expired. Please log in again.',
  ]) : code = ApiErrorCode.sessionExpired,
       statusCode = null,
       fields = const [];

  @override
  String toString() => 'ApiError(${code.wire}/$statusCode): $message';
}

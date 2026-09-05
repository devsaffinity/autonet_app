import 'package:autonect/data/core/api_envelope.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/message_ack.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/token_pair.dart';
import 'package:flutter_test/flutter_test.dart';

ApiResult<MessageAck> ack(int s, String b) =>
    decodeEnvelope<MessageAck>(s, b, MessageAck.fromJson);

void main() {
  group('success envelope', () {
    test('decodes data', () {
      final r = ack(200, '{"success":true,"data":{"message":"hi"}}');
      expect(r.valueOrNull?.message, 'hi');
    });

    test('a throwing decoder becomes malformed, never an uncaught error', () {
      final r = decodeEnvelope<TokenPair>(
        200,
        '{"success":true,"data":{"accessToken":1}}',
        (d) => TokenPair.fromJson((d as Map).cast<String, dynamic>()),
      );
      expect(r.errorOrNull?.code, ApiErrorCode.malformedResponse);
    });

    test('204 with an empty body still yields Ok', () {
      expect(ack(204, '').isOk, isTrue);
    });

    test('non-JSON body is malformed, not a crash', () {
      expect(ack(502, '<html>bad gateway</html>').errorOrNull?.code,
          ApiErrorCode.malformedResponse);
    });
  });

  group('all 15 server error codes round-trip', () {
    const codes = {
      'VALIDATION_ERROR': ApiErrorCode.validationError,
      'UNAUTHORIZED': ApiErrorCode.unauthorized,
      'FORBIDDEN': ApiErrorCode.forbidden,
      'NOT_FOUND': ApiErrorCode.notFound,
      'CONFLICT': ApiErrorCode.conflict,
      'RATE_LIMITED': ApiErrorCode.rateLimited,
      'INTERNAL': ApiErrorCode.internal,
      'INVALID_CREDENTIALS': ApiErrorCode.invalidCredentials,
      'VERIFICATION_REQUIRED': ApiErrorCode.verificationRequired,
      'ACCOUNT_SUSPENDED': ApiErrorCode.accountSuspended,
      'OTP_INVALID': ApiErrorCode.otpInvalid,
      'OTP_EXPIRED': ApiErrorCode.otpExpired,
      'TOO_MANY_ATTEMPTS': ApiErrorCode.tooManyAttempts,
      'INSUFFICIENT_CREDITS': ApiErrorCode.insufficientCredits,
      'NOT_APPROVED': ApiErrorCode.notApproved,
    };

    codes.forEach((wire, code) {
      test(wire, () {
        final r = ack(400, '{"success":false,"error":{"code":"$wire","message":"m"}}');
        expect(r.errorOrNull?.code, code);
        expect(r.errorOrNull?.message, 'm');
        expect(r.errorOrNull?.statusCode, 400);
      });
    });

    test('an unknown 16th code degrades to unknown rather than throwing', () {
      expect(ack(400, errorOf('SOMETHING_NEW')).errorOrNull?.code,
          ApiErrorCode.unknown);
    });
  });

  group('VERIFIED live payloads', () {
    // curl POST /v1/auth/login {"email":"nobody@example.invalid","password":"x"}
    test('401 INVALID_CREDENTIALS', () {
      final r = ack(401,
          '{"success":false,"error":{"code":"INVALID_CREDENTIALS","message":"Invalid email or password"}}');
      final e = r.errorOrNull!;
      expect(e.code, ApiErrorCode.invalidCredentials);
      // The refresh path must never fire for this: it is bad creds, not a stale
      // access token, and a rotation would be burned for nothing.
      expect(e.isStaleAccessToken, isFalse);
    });

    // curl POST /v1/auth/login {"email":"not-an-email"}
    test('400 VALIDATION_ERROR maps details[] to per-field errors', () {
      final r = ack(400, '''
{"success":false,"error":{"code":"VALIDATION_ERROR","message":"Invalid request body",
 "details":[{"path":"email","message":"Invalid email address"},
            {"path":"password","message":"Invalid input: expected string, received undefined"}]}}''');
      expect(r.errorOrNull!.fieldErrors, {
        'email': 'Invalid email address',
        'password': 'Invalid input: expected string, received undefined',
      });
    });

    test('first message per path wins — zod emits several issues per field', () {
      final r = ack(400, '''
{"success":false,"error":{"code":"VALIDATION_ERROR","message":"m",
 "details":[{"path":"password","message":"too short"},
            {"path":"password","message":"needs a capital"}]}}''');
      expect(r.errorOrNull!.fieldErrors['password'], 'too short');
    });

    test('a non-array details is ignored, not fatal', () {
      final r = ack(400,
          '{"success":false,"error":{"code":"VALIDATION_ERROR","message":"m","details":"oops"}}');
      expect(r.errorOrNull!.fields, isEmpty);
    });
  });

  test('isStaleAccessToken is 401 AND UNAUTHORIZED, nothing else', () {
    expect(ack(401, errorOf('UNAUTHORIZED')).errorOrNull!.isStaleAccessToken, isTrue);
    expect(ack(403, errorOf('UNAUTHORIZED')).errorOrNull!.isStaleAccessToken, isFalse);
    expect(ack(401, errorOf('FORBIDDEN')).errorOrNull!.isStaleAccessToken, isFalse);
  });

  group('decodeEnvelopeWithMeta hands the top-level meta sibling to the decoder', () {
    // meta is a SIBLING of data, not a child of it, so a decoder that only ever
    // sees json['data'] can never read hasNextPage.
    ApiResult<Map<String, dynamic>?> metaOnly(String body) =>
        decodeEnvelopeWithMeta<Map<String, dynamic>?>(200, body, (_, m) => m);

    test('meta present is surfaced', () {
      const body = '{"success":true,"data":[],"meta":{"page":2,"limit":20,'
          '"pageSize":20,"total":30,"totalPages":2,"hasNextPage":false,"hasPreviousPage":true}}';
      expect(PageMeta.fromJson(metaOnly(body).valueOrNull!).page, 2);
    });

    test('meta absent passes null to the decoder', () {
      final r = metaOnly('{"success":true,"data":[]}');
      expect(r.isOk, isTrue);
      expect(r.valueOrNull, isNull);
    });

    test('a non-JSON body is still malformed', () {
      expect(metaOnly('not json').errorOrNull?.code,
          ApiErrorCode.malformedResponse);
    });
  });
}

String errorOf(String code) =>
    '{"success":false,"error":{"code":"$code","message":"m"}}';

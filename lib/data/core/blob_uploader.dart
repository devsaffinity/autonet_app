import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/http_transport.dart';
import 'package:autonect/data/models/message_ack.dart';

/// THE ONE DELIBERATE EXCEPTION to "every response goes through
/// decodeEnvelope", and the only HTTP caller in the app that is not ApiClient.
///
/// WHY it must not be ApiClient:
///  1. The target is S3, not our API. S3 answers an empty 200 or an XML
///     `<Error>` document — never our {success,data} envelope — so running it
///     through decodeEnvelope would report every successful upload as
///     malformed.
///  2. The presigned URL IS the credential. Its signature is computed over an
///     exact header set, so adding `authorization` (or `accept`) invalidates it
///     and S3 answers 403. Exactly one header goes out: content-type, which the
///     ticket was signed for.
///  3. An S3 403 is a signature/expiry problem, not a stale session, so it must
///     NOT reach the refresh machinery. Burning a refresh rotation on it risks
///     the reuse-detection family revoke for nothing.
class BlobUploader {
  BlobUploader(this._transport);

  final HttpTransport _transport;

  Future<ApiResult<MessageAck>> put({
    required String url,
    required List<int> bytes,
    required String contentType,
  }) async {
    HttpResponse res;
    try {
      res = await _transport.send(
        HttpRequest(
          method: 'PUT',
          url: url,
          headers: {'content-type': contentType},
          bodyBytes: bytes,
        ),
      );
    } on TransportTimeout {
      return const Err(ApiError.timeout());
    } on TransportFailure catch (e) {
      return Err(ApiError.network(e.message));
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return const Ok(MessageAck('Uploaded'));
    }
    // The S3 body is XML we cannot usefully show a buyer; the status carries
    // everything the caller can act on (403 = re-ticket, 5xx = try again).
    return Err(
      ApiError(
        code: ApiErrorCode.internal,
        statusCode: res.statusCode,
        message: 'Upload was rejected (HTTP ${res.statusCode})',
      ),
    );
  }
}

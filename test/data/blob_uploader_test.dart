import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/blob_uploader.dart';
import 'package:autonect/data/core/http_transport.dart';
import 'package:autonect/data/models/message_ack.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_transport.dart';

/// The presigned PUT is the one call that bypasses both the envelope parser and
/// the refresh machinery. These tests pin exactly that.
void main() {
  const s3Path = '/bucket/requests/u1/img.jpg';
  const s3Url = 'https://s3.eu-west-2.amazonaws.com$s3Path?X-Amz-Signature=abc';
  final bytes = <int>[0xFF, 0xD8, 0xFF, 0xE0];

  late FakeTransport t;
  late BlobUploader uploader;

  setUp(() {
    t = FakeTransport();
    uploader = BlobUploader(t);
  });

  Future<ApiResult<MessageAck>> upload() =>
      uploader.put(url: s3Url, bytes: bytes, contentType: 'image/jpeg');

  test('a 200 with S3\'s empty body is Ok — no envelope is expected', () async {
    t.on('PUT', s3Path, status: 200, body: '');
    final r = await uploader.put(
      url: s3Url,
      bytes: bytes,
      contentType: 'image/jpeg',
    );
    expect(r.isOk, isTrue);
    expect(r.valueOrNull?.message, 'Uploaded');
  });

  test('a 204 is Ok too — any 2xx means the object landed', () async {
    t.on('PUT', s3Path, status: 204, body: '');
    expect((await upload()).isOk, isTrue);
  });

  test('a 403 is an Err carrying the status, and NEVER refreshes', () async {
    t.on('PUT', s3Path, status: 403, body: '<Error><Code>AccessDenied</Code></Error>');
    final r = await upload();
    expect(r.errorOrNull?.statusCode, 403);
    expect(r.errorOrNull?.code, ApiErrorCode.internal);
    // An S3 403 is an expired signature, not a dead session. Rotating a refresh
    // token here risks the server's reuse-detection family revoke for nothing.
    expect(t.countOf('POST', '/v1/auth/refresh'), 0);
  });

  test('a 500 is an Err, not a malformed-envelope error', () async {
    t.on('PUT', s3Path, status: 500, body: '<Error/>');
    expect((await upload()).errorOrNull?.statusCode, 500);
  });

  test('TransportTimeout maps to the timeout code', () async {
    t.on('PUT', s3Path, throws: const TransportTimeout());
    expect((await upload()).errorOrNull?.code, ApiErrorCode.timeout);
  });

  test('TransportFailure maps to the network code', () async {
    t.on('PUT', s3Path, throws: const TransportFailure('socket closed'));
    expect((await upload()).errorOrNull?.code, ApiErrorCode.network);
  });

  test('exactly one header goes out: content-type, and no authorization', () async {
    t.on('PUT', s3Path, status: 200, body: '');
    await uploader.put(url: s3Url, bytes: bytes, contentType: 'image/png');
    final sent = t.calls.where((c) => c.method == 'PUT').last;
    expect(sent.headers['content-type'], 'image/png');
    // Any extra header invalidates the S3 signature the ticket was signed with.
    expect(sent.headers.containsKey('authorization'), isFalse);
    expect(sent.headers.keys, ['content-type']);
  });

  test('the payload travels as bytes, not as a String body', () async {
    t.on('PUT', s3Path, status: 200, body: '');
    await upload();
    final sent = t.calls.where((c) => c.method == 'PUT').last;
    expect(sent.bodyBytes, bytes);
    expect(sent.body, isNull);
  });
}

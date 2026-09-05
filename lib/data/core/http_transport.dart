/// The seam that keeps package:http out of ApiClient — tests inject a scripted
/// transport instead of stubbing a real socket.
class HttpRequest {
  const HttpRequest({
    required this.method,
    required this.url,
    required this.headers,
    this.query,
    this.body,
    this.bodyBytes,
  });

  final String method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String>? query;
  final String? body;

  /// Set INSTEAD of [body] for a raw binary PUT (a presigned S3 upload). A
  /// request carries exactly one payload, so [bodyBytes] takes precedence.
  final List<int>? bodyBytes;
}

class HttpResponse {
  const HttpResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

class TransportTimeout implements Exception {
  const TransportTimeout();
}

class TransportFailure implements Exception {
  const TransportFailure(this.message);
  final String message;
}

abstract class HttpTransport {
  Future<HttpResponse> send(HttpRequest request);
}

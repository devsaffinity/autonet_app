import 'dart:async';
import 'dart:convert';

import 'package:autonect/data/core/http_transport.dart';
import 'package:http/http.dart' as http;

/// The ONLY file in the app permitted to import package:http.
class HttpClientTransport implements HttpTransport {
  HttpClientTransport({http.Client? client, this.timeout = const Duration(seconds: 20)})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  @override
  Future<HttpResponse> send(HttpRequest r) async {
    try {
      var uri = Uri.parse(r.url);
      if (r.query != null && r.query!.isNotEmpty) {
        uri = uri.replace(queryParameters: r.query);
      }
      final req = http.Request(r.method, uri)..headers.addAll(r.headers);
      if (r.bodyBytes != null) {
        req.bodyBytes = r.bodyBytes!;
      } else if (r.body != null) {
        req.body = r.body!;
      }
      final streamed = await _client.send(req).timeout(timeout);
      final res = await http.Response.fromStream(streamed);
      // Decode explicitly: the server is UTF-8 but does not always say so, and
      // http falls back to latin1 when the charset is absent.
      return HttpResponse(
        statusCode: res.statusCode,
        body: utf8.decode(res.bodyBytes),
        headers: res.headers,
      );
    } on TimeoutException {
      throw const TransportTimeout();
    } catch (e) {
      throw TransportFailure(e.toString());
    }
  }

  void close() => _client.close();
}

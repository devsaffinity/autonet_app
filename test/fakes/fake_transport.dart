import 'dart:async';

import 'package:autonect/data/core/http_transport.dart';

/// A scripted HttpTransport that records every request.
///
/// [withDelay] is what makes the concurrency test genuine: without a Completer
/// the fake would answer synchronously and the "concurrent" 401s would in fact
/// serialise, so a broken single-flight would still pass.
class FakeTransport implements HttpTransport {
  final List<HttpRequest> calls = [];

  final Map<String, List<_Scripted>> _script = {};
  final Map<String, int> _served = {};

  static String key(String method, String path) => '$method $path';

  /// Answers every call to [path] with [response] unless a later-indexed
  /// scripted answer exists for it.
  void on(
    String method,
    String path, {
    int status = 200,
    String body = '{"success":true,"data":{}}',
    Object? throws,
    Completer<void>? gate,
  }) {
    _script
        .putIfAbsent(key(method, path), () => [])
        .add(_Scripted(status, body, throws, gate));
  }

  /// Sugar for the common "first call 401s, the retry succeeds" script.
  void onSecondCall(
    String method,
    String path, {
    int status = 200,
    String body = '{"success":true,"data":{}}',
  }) => on(method, path, status: status, body: body);

  /// A gate the test completes by hand, so several requests genuinely overlap.
  Completer<void> withDelay(String method, String path,
      {int status = 200, String body = '{"success":true,"data":{}}'}) {
    final gate = Completer<void>();
    on(method, path, status: status, body: body, gate: gate);
    return gate;
  }

  int countOf(String method, String path) =>
      calls.where((c) => c.method == method && c.url.endsWith(path)).length;

  HttpRequest? lastOf(String method, String path) {
    final m = calls.where((c) => c.method == method && c.url.endsWith(path));
    return m.isEmpty ? null : m.last;
  }

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    calls.add(request);
    final path = Uri.parse(request.url).path;
    final k = key(request.method, path);
    final scripts = _script[k];
    if (scripts == null || scripts.isEmpty) {
      throw TransportFailure('No script for $k');
    }
    final i = (_served[k] ?? 0);
    _served[k] = i + 1;
    final s = scripts[i < scripts.length ? i : scripts.length - 1];
    if (s.gate != null) await s.gate!.future;
    if (s.throws != null) throw s.throws!;
    return HttpResponse(statusCode: s.status, body: s.body);
  }
}

class _Scripted {
  _Scripted(this.status, this.body, this.throws, this.gate);
  final int status;
  final String body;
  final Object? throws;
  final Completer<void>? gate;
}

String tokensBody(String access, String refresh, {String role = 'BUYER'}) =>
    '{"success":true,"data":{"accessToken":"$access","refreshToken":"$refresh",'
    '"user":{"id":"u1","email":"a@b.com","role":"$role","status":"ACTIVE","name":"A"}}}';

String errorBody(String code, [String message = 'nope']) =>
    '{"success":false,"error":{"code":"$code","message":"$message"}}';

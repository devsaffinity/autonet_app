/// The result of every network call. Sealed on purpose: twenty error codes each
/// need distinct UI, and a Dart 3 exhaustive switch turns a missed one into a
/// compile error instead of an uncaught async error.
///
/// [T] is NEVER `void` — `Ok<void>(decodeData(...))` does not compile.
/// Endpoints with no payload use MessageAck.
library;

import 'api_error.dart';

sealed class ApiResult<T> {
  const ApiResult();

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  ApiError? get errorOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final error) => error,
  };

  ApiResult<R> map<R>(R Function(T) f) => switch (this) {
    Ok<T>(:final value) => Ok<R>(f(value)),
    Err<T>(:final error) => Err<R>(error),
  };
}

final class Ok<T> extends ApiResult<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends ApiResult<T> {
  const Err(this.error);
  final ApiError error;
}

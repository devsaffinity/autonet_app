import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exhaustiveness smoke: this switch has no default arm, so adding a fifth
/// subclass of [ViewState] fails to compile here before it can silently fall
/// through a real screen.
String describe(ViewState<int> s) => switch (s) {
  Loading<int>() => 'loading',
  Empty<int>(title: final t) => 'empty:${t ?? '-'}',
  Failed<int>(message: final m) => 'failed:$m',
  Data<int>(value: final v) => 'data:$v',
};

void main() {
  group('ViewState', () {
    test('every arm is reachable through one exhaustive switch', () {
      expect(describe(const Loading<int>()), 'loading');
      expect(describe(const Empty<int>('No offers yet')), 'empty:No offers yet');
      expect(describe(const Data<int>(7)), 'data:7');
      expect(
        describe(const Failed<int>(ApiError.network())),
        startsWith('failed:'),
      );
    });

    test('Empty carries optional title and body', () {
      const e = Empty<int>('None', 'Try again later');
      expect(e.title, 'None');
      expect(e.body, 'Try again later');
      expect(const Empty<int>().title, isNull);
    });

    test('Failed exposes copy and retryability, never the raw error', () {
      const network = Failed<int>(ApiError.network());
      expect(network.retryable, isTrue);
      expect(network.message, isNotEmpty);
      expect(network.isSessionExpired, isFalse);

      const forbidden = Failed<int>(
        ApiError(
          code: ApiErrorCode.forbidden,
          message: 'You do not own this request',
          statusCode: 403,
        ),
      );
      expect(forbidden.retryable, isFalse, reason: 'a 403 never self-heals');
      expect(forbidden.message, 'You do not own this request');
    });

    test('a session expiry is distinguishable from any other failure', () {
      const expired = Failed<int>(ApiError.sessionExpired());
      expect(expired.isSessionExpired, isTrue);
      expect(expired.retryable, isFalse);
    });
  });
}

import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// StateView is the only thing standing between DoD's four-state rule and 55
/// screens each inventing their own blank page. The retry assertions below are
/// the ones that matter: a 'Try again' button on a 403 or a 409 is a button
/// that lies, and nothing else in the app checks that it is absent.
void main() {
  const retryText = 'Try again';

  Widget host(
    ViewState<String> state, {
    VoidCallback? onRetry,
    Widget? emptyAction,
  }) => MaterialApp(
    home: Scaffold(
      body: StateView<String>(
        state: state,
        onRetry: onRetry ?? () {},
        emptyAction: emptyAction,
        builder: (_, value) => Text(value),
      ),
    ),
  );

  testWidgets('Loading renders the shared spinner and nothing else', (t) async {
    await t.pumpWidget(host(const Loading<String>()));
    expect(find.byType(DiscreteCircleLoading), findsOneWidget);
    expect(find.text(retryText), findsNothing);
  });

  testWidgets('Empty renders its title, body and CTA slot', (t) async {
    await t.pumpWidget(host(
      const Empty<String>('No requests yet', 'Your requests will appear here.'),
      emptyAction: const Text('Request a part'),
    ));
    expect(find.text('No requests yet'), findsOneWidget);
    expect(find.text('Your requests will appear here.'), findsOneWidget);
    expect(find.text('Request a part'), findsOneWidget);
    expect(find.byType(DiscreteCircleLoading), findsNothing);
  });

  testWidgets('Data hands the value to the builder', (t) async {
    await t.pumpWidget(host(const Data<String>('twelve offers')));
    expect(find.text('twelve offers'), findsOneWidget);
    expect(find.byType(DiscreteCircleLoading), findsNothing);
  });

  testWidgets('Failed renders the message and fires onRetry', (t) async {
    var taps = 0;
    await t.pumpWidget(host(
      const Failed<String>(ApiError.network()),
      onRetry: () => taps++,
    ));
    expect(
      find.text('No internet connection. Check your network and try again.'),
      findsOneWidget,
    );
    await t.tap(find.text(retryText));
    await t.pump();
    expect(taps, 1);
  });

  // The whole point of Failed.retryable, pinned as a table.
  const retryable = <String, ApiError>{
    'network': ApiError.network(),
    'timeout': ApiError.timeout(),
    'internal': ApiError(
      code: ApiErrorCode.internal,
      message: 'Something went wrong',
      statusCode: 500,
    ),
    'rate limited': ApiError(
      code: ApiErrorCode.rateLimited,
      message: 'Too many requests',
      statusCode: 429,
    ),
  };

  const notRetryable = <String, ApiError>{
    '400': ApiError(
      code: ApiErrorCode.validationError,
      message: 'partName must be at least 2 characters',
      statusCode: 400,
    ),
    '403': ApiError(
      code: ApiErrorCode.forbidden,
      message: 'Request is not open (or not yours)',
      statusCode: 403,
    ),
    '404': ApiError(
      code: ApiErrorCode.notFound,
      message: 'Order not found',
      statusCode: 404,
    ),
    '409': ApiError(
      code: ApiErrorCode.conflict,
      message: 'Illegal transition PLACED -> DELIVERED',
      statusCode: 409,
    ),
  };

  retryable.forEach((name, error) {
    testWidgets('$name offers a retry button', (t) async {
      await t.pumpWidget(host(Failed<String>(error)));
      expect(find.text(retryText), findsOneWidget);
    });
  });

  notRetryable.forEach((name, error) {
    testWidgets('$name shows the message but NO retry button', (t) async {
      await t.pumpWidget(host(Failed<String>(error)));
      expect(find.text(error.message), findsOneWidget);
      expect(find.text(retryText), findsNothing);
    });
  });
}

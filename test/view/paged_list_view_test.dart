import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared list widget every buyer screen goes through.
///
/// It deliberately has NO header slot. One existed until a screen put its
/// filter chips in it and lost them on the first empty result, because the
/// slot was only ever painted in the Data arm. These tests pin what the widget
/// does render in each of the four states, so the next attempt to hang chrome
/// off the list itself has to come back through here.
void main() {
  Widget host({
    required ViewState<List<String>> state,
    bool loadingMore = false,
    String? loadMoreError,
    bool hasMore = false,
    VoidCallback? onLoadMore,
    Widget? emptyAction,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: PagedListView<String>(
            state: state,
            loadingMore: loadingMore,
            loadMoreError: loadMoreError,
            hasMore: hasMore,
            onLoadMore: onLoadMore ?? () {},
            onRefresh: () {},
            emptyAction: emptyAction,
            itemBuilder: (_, s) => ListTile(title: Text(s)),
          ),
        ),
      );

  testWidgets('Loading renders the shared spinner and no rows', (t) async {
    await t.pumpWidget(host(state: const Loading<List<String>>()));
    expect(find.byType(DiscreteCircleLoading), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('Empty renders its copy and the caller CTA', (t) async {
    await t.pumpWidget(host(
      state: const Empty<List<String>>('No orders yet', 'Nothing to show.'),
      emptyAction: const Text('Request a part'),
    ));
    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Nothing to show.'), findsOneWidget);
    expect(find.text('Request a part'), findsOneWidget);
  });

  testWidgets('Failed renders the message and a retry for a retryable error',
      (t) async {
    await t.pumpWidget(host(
        state: const Failed<List<String>>(ApiError.network())));
    expect(find.text('No internet connection. Check your network and try again.'),
        findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Data renders one row per item, at index 0', (t) async {
    await t.pumpWidget(host(state: const Data<List<String>>(['a', 'b'])));
    expect(find.byType(ListTile), findsNWidgets(2));
    // The old header rode at index 0 and pushed every row down one; the
    // itemBuilder now maps straight onto the list.
    expect(t.widget<ListTile>(find.byType(ListTile).first).title,
        isA<Text>().having((w) => w.data, 'data', 'a'));
  });

  testWidgets('a page-2 fetch in flight appends the footer spinner', (t) async {
    await t.pumpWidget(host(
        state: const Data<List<String>>(['a']), loadingMore: true, hasMore: true));
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.byType(DiscreteCircleLoading), findsOneWidget);
  });

  testWidgets('a page-2 failure keeps the rows and offers a retry', (t) async {
    var retries = 0;
    await t.pumpWidget(host(
      state: const Data<List<String>>(['a']),
      loadMoreError: 'Could not load more.',
      hasMore: true,
      onLoadMore: () => retries++,
    ));
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Could not load more.'), findsOneWidget);
    await t.tap(find.text('Retry loading more'));
    expect(retries, 1);
  });
}

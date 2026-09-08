import 'package:autonect/controller/buyer/notifications_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/app_notification.dart';
import 'package:autonect/data/repositories/notifications_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// The badge is the reason anyone opens this screen, and it is the easiest
/// thing here to get quietly wrong: counting the loaded page instead of asking
/// the server undercounts the moment there is a second page.

AppNotification _n(String id, {bool read = false}) =>
    AppNotification.fromJson({
      'id': id,
      'type': 'offer.created',
      'title': 'New offer',
      'body': 'A supplier replied to your request',
      'read': read,
      'createdAt': DateTime(2026, 9, 8).toIso8601String(),
    });

class _FakeRepo implements NotificationsRepository {
  int unread = 0;
  List<List<AppNotification>> pages = const [];
  ApiResult<NotificationPage>? listOverride;
  ApiResult<int> markReadResult = const Ok(1);
  final calls = <String>[];

  @override
  Future<ApiResult<NotificationPage>> list({int page = 1, int limit = 20}) async {
    calls.add('list:$page:$limit');
    if (listOverride case final o?) return o;
    final items = page <= pages.length ? pages[page - 1] : <AppNotification>[];
    return Ok(NotificationPage(
      items: items,
      unread: unread,
      total: pages.fold(0, (a, p) => a + p.length),
      page: page,
      hasMore: page < pages.length,
    ));
  }

  @override
  Future<ApiResult<int>> markRead(String id) async {
    calls.add('markRead:$id');
    return markReadResult;
  }

  @override
  Future<ApiResult<int>> markAllRead() async {
    calls.add('markAllRead');
    return Ok(unread);
  }
}

void main() {
  late _FakeRepo repo;
  late NotificationsController c;

  NotificationsController build() =>
      NotificationsController(repo, toast: (_) {});

  setUp(() {
    repo = _FakeRepo();
    c = build();
  });

  group('load', () {
    test('an empty list is Empty, not Data with zero rows', () async {
      // StateView renders the empty PANEL off Empty; Data([]) would paint a
      // blank scroll view with no explanation.
      await c.load();
      expect(c.state.value, isA<Empty<List<AppNotification>>>());
    });

    test('a failure is Failed so the retry panel appears', () async {
      repo.listOverride = const Err(ApiError.network('offline'));
      await c.load();
      expect(c.state.value, isA<Failed<List<AppNotification>>>());
    });

    test('the badge comes from the SERVER, not from the loaded page', () async {
      // One unread row on page one, but forty unread overall. Counting the page
      // would show 1.
      repo
        ..unread = 40
        ..pages = [
          [_n('a'), _n('b', read: true)],
        ];
      await c.load();
      expect(c.unread.value, 40);
    });
  });

  group('markRead', () {
    test('updates the row and decrements the badge by one', () async {
      repo
        ..unread = 3
        ..pages = [
          [_n('a'), _n('b')],
        ];
      await c.load();

      await c.markRead(_n('a'));

      final items = (c.state.value as Data<List<AppNotification>>).value;
      expect(items.firstWhere((n) => n.id == 'a').read, isTrue);
      expect(items.firstWhere((n) => n.id == 'b').read, isFalse);
      expect(c.unread.value, 2);
    });

    test('an already-read row is a no-op — no call, no decrement', () async {
      repo
        ..unread = 1
        ..pages = [
          [_n('a', read: true)],
        ];
      await c.load();
      repo.calls.clear();

      await c.markRead(_n('a', read: true));

      expect(repo.calls, isEmpty);
      expect(c.unread.value, 1);
    });

    test('the badge never goes below zero', () async {
      // The server is authoritative on the count; a client that decrements
      // blindly can drift negative when the two disagree.
      repo
        ..unread = 0
        ..pages = [
          [_n('a')],
        ];
      await c.load();
      await c.markRead(_n('a'));
      expect(c.unread.value, 0);
    });

    test('a server that changed nothing does not decrement', () async {
      repo
        ..unread = 5
        ..pages = [
          [_n('a')],
        ];
      await c.load();
      repo.markReadResult = const Ok(0);

      await c.markRead(_n('a'));
      expect(c.unread.value, 5);
    });
  });

  group('pagination', () {
    test('loadMore appends rather than replacing', () async {
      repo
        ..unread = 0
        ..pages = [
          [_n('a'), _n('b')],
          [_n('c')],
        ];
      await c.load();
      expect(c.hasMore, isTrue);

      await c.loadMore();

      final items = (c.state.value as Data<List<AppNotification>>).value;
      expect(items.map((n) => n.id), ['a', 'b', 'c']);
      expect(c.hasMore, isFalse);
    });

    test('loadMore does nothing when there is no next page', () async {
      repo.pages = [
        [_n('a')],
      ];
      await c.load();
      repo.calls.clear();

      await c.loadMore();
      expect(repo.calls, isEmpty);
    });

    test('a failed page leaves the loaded rows alone', () async {
      // An error panel over a working list is worse than a missing page.
      repo.pages = [
        [_n('a')],
        [_n('b')],
      ];
      await c.load();
      repo.listOverride = const Err(ApiError.network('offline'));

      await c.loadMore();
      final items = (c.state.value as Data<List<AppNotification>>).value;
      expect(items.map((n) => n.id), ['a']);
    });
  });

  test('refreshUnread updates the badge without touching the list', () async {
    repo
      ..unread = 7
      ..pages = [
        [_n('a')],
      ];
    // Never loaded, so the list is still Loading — the badge must not require
    // the screen to have been opened.
    await c.refreshUnread();

    expect(c.unread.value, 7);
    expect(c.state.value, isA<Loading<List<AppNotification>>>());
    expect(repo.calls.single, 'list:1:1', reason: 'one row, not a whole page');
  });
}

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/app_notification.dart';
import 'package:autonect/data/repositories/notifications_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// The notification centre and the bell's unread badge.
///
/// PERMANENT, because the badge is read from the shell on every screen while the
/// list itself is a route the user visits occasionally. A per-visit controller
/// would mean the badge only ever knew a count from the last time the list
/// happened to be open.
class NotificationsController extends ApiController {
  NotificationsController(this._repo, {super.toast});

  static NotificationsController get to => Get.find<NotificationsController>();

  static NotificationsController ensure() =>
      Get.isRegistered<NotificationsController>()
      ? Get.find<NotificationsController>()
      : Get.put(
          NotificationsController(Get.find<NotificationsRepository>()),
          permanent: true,
        );

  final NotificationsRepository _repo;

  static const StateSlot _listRead = StateSlot('notifications');

  final Rx<ViewState<List<AppNotification>>> state =
      Rx<ViewState<List<AppNotification>>>(const Loading());

  /// The SERVER's count, not a count of the loaded page.
  ///
  /// Deriving it from `items.where((n) => !n.read)` would undercount the moment
  /// there is more than one page — and the badge is the whole reason anyone
  /// opens this screen.
  final RxInt unread = 0.obs;

  final RxBool loadingMore = false.obs;
  int _page = 1;
  bool _hasMore = false;

  bool get hasMore => _hasMore;

  List<AppNotification> get _current => switch (state.value) {
    Data<List<AppNotification>>(:final value) => value,
    _ => const [],
  };

  /// First page. Also the pull-to-refresh.
  ///
  /// [runRead], not [run]: the empty and error panels both offer a retry, and a
  /// retry tapped while the first read was still in flight would be DROPPED as
  /// re-entrant, writing the non-retryable 'please wait' over the list.
  Future<void> load() {
    _page = 1;
    return runRead(_listRead, () => _repo.list(page: 1), (r) {
      switch (r) {
        case Err(:final error):
          state.value = Failed<List<AppNotification>>(error);
        case Ok(:final value):
          unread.value = value.unread;
          _hasMore = value.hasMore;
          state.value = value.items.isEmpty
              ? const Empty<List<AppNotification>>(
                  'No notifications yet',
                  "We'll tell you here when a supplier replies to a request.",
                )
              : Data<List<AppNotification>>(value.items);
      }
    });
  }

  /// Refreshes ONLY the badge, for callers that want the count without
  /// disturbing a list the user may be looking at.
  Future<void> refreshUnread() async {
    if (await _repo.list(page: 1, limit: 1) case Ok(:final value)) {
      unread.value = value.unread;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || loadingMore.value || _current.isEmpty) return;
    loadingMore.value = true;
    try {
      switch (await _repo.list(page: _page + 1)) {
        case Err():
          // Deliberately silent: the page in hand is still valid, and an error
          // panel over a working list is worse than a missing extra page.
          break;
        case Ok(:final value):
          _page += 1;
          _hasMore = value.hasMore;
          unread.value = value.unread;
          state.value = Data<List<AppNotification>>([
            ..._current,
            ...value.items,
          ]);
      }
    } finally {
      loadingMore.value = false;
    }
  }

  /// Marks one read and updates the row in place.
  ///
  /// Optimistic on the ROW and authoritative on the COUNT: the server answers
  /// with how many rows it actually changed, so a row already read decrements
  /// nothing and the badge cannot drift below zero.
  Future<void> markRead(AppNotification n) async {
    if (n.read) return;
    final items = [
      for (final item in _current)
        if (item.id == n.id) item.copyWith(read: true) else item,
    ];
    state.value = Data<List<AppNotification>>(items);

    switch (await _repo.markRead(n.id)) {
      case Ok(:final value):
        if (value > 0 && unread.value > 0) unread.value -= 1;
      case Err():
        // Put the row back: claiming it is read when the server disagrees means
        // it silently reappears unread on the next load with no explanation.
        state.value = Data<List<AppNotification>>(_current);
        await load();
    }
  }

  /// Whether there is anything to clear.
  ///
  /// The Clear all action hides when this is false, for the same reason Mark
  /// all read hides at zero unread: a visible action that does nothing invites
  /// the tap that proves it does nothing.
  bool get hasAny =>
      state.value is Data<List<AppNotification>> && _current.isNotEmpty;

  /// Asks the SERVER to delete one, and reports whether the row may leave.
  ///
  /// Split from [forget] because it is a Dismissible's confirmDismiss: the row
  /// must only animate away if the server agreed, and this must NOT touch the
  /// list while doing it. Removing here would rebuild the list without the
  /// row and dispose the very Dismissible still waiting on this future.
  ///
  /// A 0 is still a yes. It means the row was already gone — cleared on
  /// another device, most likely — and springing it back would restore
  /// something that no longer exists.
  Future<bool> confirmRemove(AppNotification n) async {
    switch (await _repo.remove(n.id)) {
      case Ok():
        return true;
      case Err(:final error):
        absorb(error);
        return false;
    }
  }

  /// Drops the row and its share of the badge, AFTER the dismissal animation.
  void forget(AppNotification n) {
    state.value = Data<List<AppNotification>>([
      for (final item in _current)
        if (item.id != n.id) item,
    ]);
    // Only an UNREAD row was ever counted, or the badge drifts below the truth
    // and the bell under-reports for the rest of the session.
    if (!n.read && unread.value > 0) unread.value -= 1;
  }

  /// Clears everything. Reloads rather than emptying locally: the server is
  /// authoritative on both the list and the count, and a page-two row this
  /// controller never held would otherwise survive in the total.
  Future<void> removeAll() async {
    switch (await _repo.removeAll()) {
      case Ok():
        unread.value = 0;
        await load();
      case Err(:final error):
        absorb(error);
    }
  }

  Future<void> markAllRead() async {
    if (unread.value == 0) return;
    switch (await _repo.markAllRead()) {
      case Ok():
        unread.value = 0;
        await load();
      case Err(:final error):
        absorb(error);
    }
  }
}

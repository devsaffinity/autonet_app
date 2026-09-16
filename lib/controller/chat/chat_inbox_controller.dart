import 'dart:async';

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/chat_socket.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/repositories/chat_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

enum InboxTabFilter { all, active, paused }

/// The inbox — `GET /v1/conversations`.
///
/// Cursor-paginated, not page-numbered: threads reorder by `lastMessageAt` as
/// people write, so an offset page two would skip and repeat rows every time a
/// message landed. That is also why this does NOT extend PagedController,
/// which is built around page numbers and a total.
class ChatInboxController extends ApiController {
  ChatInboxController(
    this._repo, {
    ChatSocket? socket,
    super.toast,
    super.showBusy,
    super.hideBusy,
  }) : _socket = socket;

  final ChatRepository _repo;
  final ChatSocket? _socket;
  StreamSubscription<ChatMessage>? _incomingSub;
  StreamSubscription<Map<String, dynamic>>? _statusSub;

  static const StateSlot _slot = StateSlot('inbox');

  static ChatInboxController ensure() => Get.isRegistered<ChatInboxController>()
      ? Get.find<ChatInboxController>()
      : Get.put(
          ChatInboxController(
            Get.isRegistered<ChatRepository>()
                ? Get.find<ChatRepository>()
                : const _StubChatRepository(),
            socket: Get.isRegistered<ChatSocket>() ? Get.find<ChatSocket>() : null,
          ),
        );

  final Rx<ViewState<List<Conversation>>> state =
      Rx<ViewState<List<Conversation>>>(const Loading());

  final RxBool loadingMore = false.obs;

  String? _cursor;

  bool get hasMore => _cursor != null;

  /// What the user has typed into the search field.
  final RxString query = ''.obs;

  void search(String q) => query.value = q;

  /// Current tab filter: All, Active, Paused.
  final Rx<InboxTabFilter> tabFilter = InboxTabFilter.all.obs;

  void setTabFilter(InboxTabFilter filter) => tabFilter.value = filter;

  @override
  void onInit() {
    super.onInit();
    load();
    final socket = _socket;
    if (socket != null) {
      socket.connect();
      _incomingSub ??= socket.incoming.listen((_) => load());
      _statusSub ??= socket.statusChanges.listen((_) => load());
    }
  }

  /// Total unread messages across all active conversations.
  int get totalUnreadCount {
    final s = state.value;
    if (s is Data<List<Conversation>>) {
      return s.value.fold<int>(0, (sum, c) => sum + c.unreadCount);
    }
    return 0;
  }

  List<Conversation> visible(List<Conversation> all) {
    // Deduplicate by peer so multiple bookings with the same customer never
    // duplicate rows in the inbox list.
    final seenPeers = <String>{};
    final deduped = <Conversation>[];
    for (final c in all) {
      final pid = c.peer?.id;
      if (pid == null || seenPeers.add(pid)) {
        deduped.add(c);
      }
    }

    // Filter by tab: All / Active / Paused
    final tab = tabFilter.value;
    final tabFiltered = switch (tab) {
      InboxTabFilter.all => deduped,
      InboxTabFilter.active => deduped.where((c) => !c.isPaused).toList(),
      InboxTabFilter.paused => deduped.where((c) => c.isPaused).toList(),
    };

    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return tabFiltered;
    return tabFiltered
        .where(
          (c) =>
              (c.peer?.displayName ?? '').toLowerCase().contains(q) ||
              (c.lastMessage?.body ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> load() {
    _cursor = null;
    return runRead<CursorPage<Conversation>>(_slot, _repo.inbox, (r) {
      switch (r) {
        case Err(:final error):
          absorbSuperseded(error);
          state.value = Failed(error);
        case Ok(:final value):
          _cursor = value.nextCursor;
          state.value = value.items.isEmpty
              ? const Empty(
                  'No conversations yet',
                  'A thread opens when you book a provider or take an offer.',
                )
              : Data(value.items);
      }
    });
  }

  /// Append the next page. Silent: it never replaces what is on screen, so a
  /// failure here must not blank the list the user is reading.
  Future<void> loadMore() async {
    final cursor = _cursor;
    final current = state.value;
    if (cursor == null || loadingMore.value || current is! Data<List<Conversation>>) {
      return;
    }
    loadingMore.value = true;
    try {
      final result = await _repo.inbox(cursor: cursor);
      switch (result) {
        case Err():
          break;
        case Ok(:final value):
          _cursor = value.nextCursor;
          state.value = Data([...current.value, ...value.items]);
      }
    } finally {
      loadingMore.value = false;
    }
  }

  @override
  void onClose() {
    _incomingSub?.cancel();
    _statusSub?.cancel();
    super.onClose();
  }
}

class _StubChatRepository implements ChatRepository {
  const _StubChatRepository();

  @override
  Future<ApiResult<CursorPage<Conversation>>> inbox({
    String? cursor,
    int limit = 30,
  }) async =>
      const Ok(CursorPage([], null));

  @override
  Future<ApiResult<Conversation>> openForBooking(String bookingId) async =>
      const Err(ApiError(code: ApiErrorCode.internal, message: 'Not implemented in stub'));

  @override
  Future<ApiResult<Conversation>> openForOffer(String offerId) async =>
      const Err(ApiError(code: ApiErrorCode.internal, message: 'Not implemented in stub'));

  @override
  Future<ApiResult<CursorPage<ChatMessage>>> messages(
    String conversationId, {
    String? cursor,
    int limit = 50,
  }) async =>
      const Ok(CursorPage([], null));

  @override
  Future<ApiResult<ChatMessage>> send({
    required String conversationId,
    required String body,
  }) async =>
      const Err(ApiError(code: ApiErrorCode.internal, message: 'Not implemented in stub'));

  @override
  Future<ApiResult<int>> markRead(String conversationId) async => const Ok(0);
}

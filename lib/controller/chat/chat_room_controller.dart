import 'dart:async';

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/repositories/chat_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// One thread — history, sending, and receiving.
///
/// RECEIVING IS POLLED, and that is a deliberate compromise rather than a
/// finished realtime client. The server has a Socket.io gateway; this app has
/// no socket dependency, and adding one to ship a first chat client was the
/// larger change. Polling is honest about what it is: not instant, and it
/// stops the moment the screen closes.
///
/// The swap is contained: `_repo.messages` is the only source of incoming
/// messages, so replacing this timer with a socket subscription touches this
/// class and nothing else. The SEND path is already identical either way — it
/// goes through the same service the gateway calls.
class ChatRoomController extends ApiController {
  ChatRoomController(
    this._repo, {
    this.pollEvery = const Duration(seconds: 8),
    super.toast,
    super.showBusy,
    super.hideBusy,
  });

  final ChatRepository _repo;

  /// Injectable so a test does not wait eight seconds — and so the interval is
  /// one named value rather than a literal buried in a timer.
  final Duration pollEvery;

  static const StateSlot _messagesSlot = StateSlot('messages');

  static ChatRoomController ensure() => Get.isRegistered<ChatRoomController>()
      ? Get.find<ChatRoomController>()
      : Get.put(ChatRoomController(Get.find<ChatRepository>()));

  final Rx<ViewState<List<ChatMessage>>> state =
      Rx<ViewState<List<ChatMessage>>>(const Loading());

  /// The thread being read. Null until [open] resolves it.
  final Rxn<Conversation> conversation = Rxn<Conversation>();

  /// Who I am, for deciding which side of the thread a bubble sits on.
  final RxnString myUserId = RxnString();

  final RxBool sending = false.obs;

  Timer? _poll;

  /// NEWEST FIRST, matching the server and the reversed list the screen draws.
  List<ChatMessage> get _loaded => switch (state.value) {
    Data<List<ChatMessage>>(:final value) => value,
    _ => const <ChatMessage>[],
  };

  /// Point this controller at a booking's thread.
  ///
  /// Opening is get-or-create, so this is also how a thread comes into
  /// existence the first time somebody taps 'Chat with…'.
  Future<void> openForBooking(String bookingId, {String? asUserId}) =>
      _open(() => _repo.openForBooking(bookingId), bookingId, asUserId);

  Future<void> openForOffer(String offerId, {String? asUserId}) =>
      _open(() => _repo.openForOffer(offerId), offerId, asUserId);

  Future<void> _open(
    Future<ApiResult<Conversation>> Function() open,
    String contextId,
    String? asUserId,
  ) async {
    // Pointing at a different thread invalidates everything held about the
    // last one, INCLUDING answers already in flight.
    if (beginEntity(contextId)) {
      state.value = const Loading();
      conversation.value = null;
    }
    if (asUserId != null) myUserId.value = asUserId;

    final result = await open();
    switch (result) {
      case Err(:final error):
        absorbSuperseded(error);
        state.value = Failed(error);
      case Ok(:final value):
        conversation.value = value;
        await refreshMessages();
        // Only start polling once there is a thread to poll.
        _startPolling();
        unawaited(markRead());
    }
  }

  @override
  @protected
  void resetForEntity() {
    _stopPolling();
    myUserId.value = null;
  }

  Future<void> refreshMessages() {
    final id = conversation.value?.id;
    if (id == null) return Future<void>.value();
    return runRead<CursorPage<ChatMessage>>(
      _messagesSlot,
      () => _repo.messages(id),
      (r) {
        switch (r) {
          case Err(:final error):
            absorbSuperseded(error);
            // A failed POLL must not blank a thread that is already on screen —
            // the connection dropping for one tick is not the same as the
            // conversation being gone.
            if (_loaded.isEmpty) state.value = Failed(error);
          case Ok(:final value):
            state.value = value.items.isEmpty
                ? const Empty('No messages yet', 'Say hello.')
                : Data(value.items);
        }
      },
    );
  }

  void _startPolling() {
    _stopPolling();
    _poll = Timer.periodic(pollEvery, (_) {
      // A poll that lands while a send is in flight would race the optimistic
      // list; the send re-reads anyway.
      if (!sending.value) unawaited(refreshMessages());
    });
  }

  /// Stop listening for new messages.
  ///
  /// PUBLIC because the SCREEN owns the lifetime of 'somebody is looking at
  /// this thread', and its `dispose` is the only thing that reliably knows.
  /// Leaving it to GetX's own disposal is what left a timer polling a closed
  /// thread for the rest of the session — visible in a widget test as a
  /// pending timer, and in the app as traffic nobody asked for.
  void stopPolling() => _stopPolling();

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  /// Send, then re-read.
  ///
  /// Re-reads rather than appending the response: the peer may have written
  /// while this was in flight, and appending alone would show my message after
  /// a gap that quietly filled in later.
  Future<bool> send(String body) async {
    final id = conversation.value?.id;
    if (id == null || body.trim().isEmpty || sending.value) return false;

    sending.value = true;
    try {
      final result = await _repo.send(conversationId: id, body: body);
      switch (result) {
        case Err(:final error):
          absorb(error);
          return false;
        case Ok():
          await refreshMessages();
          return true;
      }
    } finally {
      sending.value = false;
    }
  }

  Future<void> markRead() async {
    final id = conversation.value?.id;
    if (id == null) return;
    await _repo.markRead(id);
  }

  @override
  void onClose() {
    // The timer outlives the screen otherwise, polling a thread nobody is
    // looking at for the rest of the session.
    _stopPolling();
    super.onClose();
  }
}

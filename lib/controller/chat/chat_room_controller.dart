import 'dart:async';

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/chat_socket.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/repositories/chat_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// One thread — history, sending, and receiving.
///
/// RECEIVING IS LIVE, over the Socket.io gateway, with POLLING AS A FALLBACK.
/// The socket is an optimisation, never a single point of failure: while it is
/// disconnected the timer runs at [pollEvery], and once it connects the timer
/// drops to [idlePollEvery] as a safety net against a silently dead socket
/// (one that reports connected but has stopped delivering).
///
/// The server broadcasts to a PER-USER room, so the stream carries every
/// thread this user is in — [_onSocketMessage] filters to the open one.
///
/// Sending stays on REST. That is not a half-measure: the gateway and the HTTP
/// route both call the same `chatService.sendMessage`, and the server now
/// broadcasts from the resulting `message.created` event rather than from
/// inside its socket handler, so a message sent either way reaches a connected
/// peer identically.
class ChatRoomController extends ApiController {
  ChatRoomController(
    this._repo, {
    ChatSocket? socket,
    this.pollEvery = const Duration(seconds: 8),
    this.idlePollEvery = const Duration(minutes: 2),
    super.toast,
    super.showBusy,
    super.hideBusy,
  }) : _socket = socket;

  final ChatRepository _repo;

  /// Null in tests that only exercise the REST path, and on a build where the
  /// socket could not be constructed — the controller then behaves exactly as
  /// the polling-only version did.
  final ChatSocket? _socket;

  /// How often to re-read while there is NO live connection.
  final Duration pollEvery;

  /// How often to re-read while the socket IS connected — the belt-and-braces
  /// interval that catches a connection which has gone quiet without saying so.
  final Duration idlePollEvery;

  static const StateSlot _messagesSlot = StateSlot('messages');

  static ChatRoomController ensure() => Get.isRegistered<ChatRoomController>()
      ? Get.find<ChatRoomController>()
      : Get.put(
          ChatRoomController(
            Get.find<ChatRepository>(),
            // Optional on purpose: a test or a build without the socket
            // registered falls back to polling rather than failing to start.
            socket: Get.isRegistered<ChatSocket>() ? Get.find<ChatSocket>() : null,
          ),
        );

  final Rx<ViewState<List<ChatMessage>>> state =
      Rx<ViewState<List<ChatMessage>>>(const Loading());

  /// The thread being read. Null until [open] resolves it.
  final Rxn<Conversation> conversation = Rxn<Conversation>();

  /// Who I am, for deciding which side of the thread a bubble sits on.
  final RxnString myUserId = RxnString();

  /// Whether communication in this thread is paused (e.g. session completed).
  final RxBool isPaused = false.obs;

  /// Session status: ACTIVE, COMPLETED, CANCELLED, CLOSED, NONE.
  final RxnString sessionStatus = RxnString();

  /// User-facing message explaining the session pause state.
  final RxnString sessionMessage = RxnString();

  /// Latest active booking id, if one exists.
  final RxnString activeBookingId = RxnString();

  final RxBool sending = false.obs;

  Timer? _poll;
  StreamSubscription<ChatMessage>? _incomingSub;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<Map<String, dynamic>>? _statusSub;

  /// Whether the live connection is currently up — the screen shows this so
  /// a user can tell "nothing is happening" from "we are not connected".
  bool get isLive => _socket?.isConnected ?? false;

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
        isPaused.value = value.isPaused;
        sessionStatus.value = value.sessionStatus;
        sessionMessage.value = value.sessionMessage;
        activeBookingId.value = value.activeBookingId;
        await refreshMessages();
        // Only listen and poll once there is a thread to listen ABOUT.
        _startListening();
        _startPolling();
        unawaited(markRead());
    }
  }

  /// Subscribe to the live stream and to connection changes.
  ///
  /// The connection subscription is what re-paces the timer: the socket
  /// dropping silently would otherwise leave the room on the two-minute idle
  /// interval, which reads to a user as chat having stopped working.
  void _startListening() {
    final socket = _socket;
    if (socket == null) return;
    socket.connect();
    _incomingSub ??= socket.incoming.listen(_onSocketMessage);
    _connectionSub ??= socket.connectionChanges.listen((_) => _startPolling());
    _statusSub ??= socket.statusChanges.listen(_onSocketStatus);
  }

  void _onSocketStatus(Map<String, dynamic> data) {
    final convId = data['conversationId'] as String?;
    if (convId != null && convId != conversation.value?.id) return;
    if (data.containsKey('isPaused')) {
      isPaused.value = data['isPaused'] as bool? ?? false;
    }
    if (data.containsKey('sessionStatus')) {
      sessionStatus.value = data['sessionStatus'] as String?;
    }
    if (data.containsKey('sessionMessage')) {
      sessionMessage.value = data['sessionMessage'] as String?;
    }
    unawaited(refreshMessages());
  }

  /// A message pushed by the server.
  ///
  /// RE-READS rather than appending. The push proves something changed, and
  /// the re-read is what keeps one source of truth for ordering and read
  /// state — appending would also need dedupe against the message the sender
  /// already has locally. The cost is one request; `runRead` supersedes, so a
  /// burst of messages cannot pile up requests.
  void _onSocketMessage(ChatMessage message) {
    if (message.conversationId != conversation.value?.id) return;
    unawaited(refreshMessages());
    // Their message arriving while the thread is open means it has been seen.
    if (message.senderId != myUserId.value) unawaited(markRead());
  }

  @override
  @protected
  void resetForEntity() {
    _stopPolling();
    myUserId.value = null;
    isPaused.value = false;
    sessionStatus.value = null;
    sessionMessage.value = null;
    activeBookingId.value = null;
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
    _poll?.cancel();
    // Live: a slow safety net. Not live: the old 8s cadence, so a dropped
    // socket degrades to the previous behaviour instead of to silence.
    final every = isLive ? idlePollEvery : pollEvery;
    _poll = Timer.periodic(every, (_) {
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
    // The socket subscriptions leak exactly the way the timer did: left alive,
    // a closed room keeps re-reading every thread this user is in, forever.
    // The socket itself is NOT disconnected here — it is a shared singleton and
    // the inbox wants it too; only this room's listeners go.
    _incomingSub?.cancel();
    _incomingSub = null;
    _connectionSub?.cancel();
    _connectionSub = null;
    _statusSub?.cancel();
    _statusSub = null;
  }

  /// Send, then re-read.
  ///
  /// Re-reads rather than appending the response: the peer may have written
  /// while this was in flight, and appending alone would show my message after
  /// a gap that quietly filled in later.
  Future<bool> send(String body) async {
    final id = conversation.value?.id;
    if (id == null || body.trim().isEmpty || sending.value) return false;
    if (isPaused.value) {
      toast(sessionMessage.value ?? 'Chat is paused because the booking session has ended. Book again to resume.');
      return false;
    }

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

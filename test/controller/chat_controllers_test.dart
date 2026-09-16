import 'package:autonect/controller/chat/chat_inbox_controller.dart';
import 'package:autonect/controller/chat/chat_room_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// Chat.
///
/// The rule this file exists to protect: a thread is opened by CONTEXT — a
/// booking or an offer — and never by naming a recipient. That is what stops
/// anybody opening a conversation with a stranger, and it is invisible from
/// the screen, so it is asserted here.
Conversation _conversation({
  String id = 'c1',
  String peerId = 'peer',
  bool isPaused = false,
  String sessionStatus = 'ACTIVE',
  String? sessionMessage,
}) =>
    Conversation.fromJson({
      'id': id,
      'type': 'BOOKING',
      'contextId': 'bk1',
      'lastMessageAt': '2026-05-14T09:00:00.000Z',
      'peer': {'id': peerId, 'name': 'Priya Raman'},
      'unreadCount': 2,
      'isPaused': isPaused,
      'sessionStatus': sessionStatus,
      'sessionMessage': sessionMessage,
    });

ChatMessage _message({
  String id = 'm1',
  String senderId = 'peer',
  String body = 'hello',
}) => ChatMessage.fromJson({
  'id': id,
  'conversationId': 'c1',
  'senderId': senderId,
  'createdAt': '2026-05-14T09:00:00.000Z',
  'body': body,
  'type': 'TEXT',
});

CursorPage<ChatMessage> _page(List<ChatMessage> items, [String? cursor]) =>
    CursorPage<ChatMessage>(items, cursor);

ChatRoomController _room(FakeChatRepository repo) => ChatRoomController(
  repo,
  // Far longer than any test runs, so a stray tick never makes a test flaky.
  pollEvery: const Duration(minutes: 5),
  toast: (_) {},
  showBusy: () {},
  hideBusy: () {},
);

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('room', () {
    test('opens by CONTEXT and never sends a recipient', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final c = _room(repo);

      await c.openForBooking('bk1');

      // The booking id, and nothing about who is in the thread — the server
      // derives that. There is no recipient field to get wrong.
      expect(repo.calls.first, 'open:BOOKING:bk1');
      expect(c.conversation.value?.id, 'c1');
      expect(c.state.value, isA<Data<List<ChatMessage>>>());
    });

    test('marks the thread read on open', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final c = _room(repo);

      await c.openForBooking('bk1');
      // markRead is fired without awaiting, so give the microtask a turn.
      await Future<void>.delayed(Duration.zero);

      expect(repo.calls, contains('read:c1'));
    });

    test('an empty thread is Empty, not Failed', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([]));
      final c = _room(repo);

      await c.openForBooking('bk1');

      // Opening a thread CREATES it, so a brand new one legitimately has no
      // messages. That is not an error.
      expect(c.state.value, isA<Empty<List<ChatMessage>>>());
    });

    test('send re-reads rather than appending its own response', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]))
        ..sendResult = Ok(_message(id: 'm2', senderId: 'me', body: 'hi'));
      final c = _room(repo);
      await c.openForBooking('bk1');
      // The peer wrote while my message was in flight.
      repo.messagesQueue.add(
        Ok(
          _page([
            _message(id: 'm3', body: 'and another'),
            _message(id: 'm2', senderId: 'me', body: 'hi'),
            _message(),
          ]),
        ),
      );

      final sent = await c.send('hi');

      expect(sent, isTrue);
      // Appending the response alone would have shown my message and then
      // filled the peer's in above it a poll later.
      expect((c.state.value as Data<List<ChatMessage>>).value, hasLength(3));
    });

    test('a failed send reports false and does not clear the thread', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]))
        ..sendResult = const Err(ApiError.network());
      final c = _room(repo);
      await c.openForBooking('bk1');

      expect(await c.send('hi'), isFalse);
      expect((c.state.value as Data<List<ChatMessage>>).value, hasLength(1));
    });

    test('an empty message never reaches the network', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final c = _room(repo);
      await c.openForBooking('bk1');
      repo.calls.clear();

      expect(await c.send('   '), isFalse);
      expect(repo.calls, isEmpty);
    });

    test('a paused room rejects send and displays toast without calling network', () async {
      String? toasted;
      final repo = FakeChatRepository()
        ..openResult = Ok(
          _conversation(
            isPaused: true,
            sessionStatus: 'COMPLETED',
            sessionMessage: 'Session completed. Chat paused.',
          ),
        )
        ..messagesResult = Ok(_page([_message()]));
      final c = ChatRoomController(
        repo,
        pollEvery: const Duration(minutes: 5),
        toast: (msg) => toasted = msg,
        showBusy: () {},
        hideBusy: () {},
      );
      await c.openForBooking('bk1');
      repo.calls.clear();

      expect(c.isPaused.value, isTrue);
      expect(c.sessionStatus.value, 'COMPLETED');
      expect(c.sessionMessage.value, 'Session completed. Chat paused.');

      final sent = await c.send('hello after session');

      expect(sent, isFalse);
      expect(repo.calls, isEmpty);
      expect(toasted, contains('Session completed'));
    });

    test('a failed refresh does NOT blank a thread already on screen', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final c = _room(repo);
      await c.openForBooking('bk1');

      repo.messagesQueue.add(const Err(ApiError.network()));
      await c.refreshMessages();

      // The connection dropping for one poll is not the same as the
      // conversation being gone — replacing the messages with an error screen
      // would lose what the user is reading mid-sentence.
      expect(c.state.value, isA<Data<List<ChatMessage>>>());
    });

    test('a failed FIRST read does surface as Failed', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = const Err(ApiError.network());
      final c = _room(repo);

      await c.openForBooking('bk1');

      // Nothing was on screen to protect, so the failure must be visible
      // rather than leaving a permanently empty thread.
      expect(c.state.value, isA<Failed<List<ChatMessage>>>());
    });

    test('pointing at another booking discards the first thread', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final c = _room(repo);
      await c.openForBooking('bk1');

      repo.openResult = Ok(_conversation(id: 'c2'));
      await c.openForBooking('bk2');

      expect(c.conversation.value?.id, 'c2');
      expect(repo.calls, contains('open:BOOKING:bk2'));
    });

    test('closing stops the poll', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final c = ChatRoomController(
        repo,
        pollEvery: const Duration(milliseconds: 20),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await c.openForBooking('bk1');

      c.onClose();
      final after = repo.messageReads;
      await Future<void>.delayed(const Duration(milliseconds: 80));

      // Otherwise the timer outlives the screen and polls a thread nobody is
      // looking at for the rest of the session.
      expect(repo.messageReads, after);
    });

    test('polls while open', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final c = ChatRoomController(
        repo,
        pollEvery: const Duration(milliseconds: 20),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await c.openForBooking('bk1');
      final first = repo.messageReads;

      await Future<void>.delayed(const Duration(milliseconds: 70));
      c.onClose();

      expect(repo.messageReads, greaterThan(first));
    });
  });

  group('inbox', () {
    ChatInboxController inbox(FakeChatRepository repo) => ChatInboxController(
      repo,
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    );

    test('an empty inbox explains how a thread starts', () async {
      final repo = FakeChatRepository()
        ..inboxResult = const Ok(CursorPage<Conversation>([], null));
      final c = inbox(repo);

      await c.load();

      final state = c.state.value;
      expect(state, isA<Empty<List<Conversation>>>());
      // There is no 'new conversation' button by design, so the empty state
      // has to say where threads come from.
      expect(
        (state as Empty<List<Conversation>>).body,
        contains('book a provider'),
      );
    });

    test('search filters what is loaded, and says so by matching both fields',
        () async {
      final repo = FakeChatRepository()
        ..inboxResult = Ok(
          CursorPage<Conversation>([
            _conversation(),
            _conversation(id: 'c2', peerId: 'peer2'),
          ], null),
        );
      final c = inbox(repo);
      await c.load();
      final all = (c.state.value as Data<List<Conversation>>).value;

      c.search('priya');
      expect(c.visible(all), hasLength(2));
      c.search('nobody');
      expect(c.visible(all), isEmpty);
    });

    test('tabFilter properly separates active vs paused conversations', () async {
      final repo = FakeChatRepository()
        ..inboxResult = Ok(
          CursorPage<Conversation>([
            _conversation(id: 'c1', peerId: 'peer1', isPaused: false),
            _conversation(id: 'c2', peerId: 'peer2', isPaused: true),
          ], null),
        );
      final c = inbox(repo);
      await c.load();
      final all = (c.state.value as Data<List<Conversation>>).value;

      c.setTabFilter(InboxTabFilter.all);
      expect(c.visible(all), hasLength(2));

      c.setTabFilter(InboxTabFilter.active);
      expect(c.visible(all), hasLength(1));
      expect(c.visible(all).first.id, 'c1');

      c.setTabFilter(InboxTabFilter.paused);
      expect(c.visible(all), hasLength(1));
      expect(c.visible(all).first.id, 'c2');
    });

    test('stops paging when the server offers no cursor', () async {
      final repo = FakeChatRepository()
        ..inboxResult = Ok(CursorPage<Conversation>([_conversation()], null));
      final c = inbox(repo);
      await c.load();
      repo.calls.clear();

      await c.loadMore();

      // The absent cursor is the ONLY stop condition; guessing from a short
      // page would page forever against a server that never said there was
      // more.
      expect(c.hasMore, isFalse);
      expect(repo.calls, isEmpty);
    });

    test('appends the next page rather than replacing the first', () async {
      final repo = FakeChatRepository()
        ..inboxResult = Ok(
          CursorPage<Conversation>([_conversation()], 'cur1'),
        );
      final c = inbox(repo);
      await c.load();
      repo.inboxResult = Ok(
        CursorPage<Conversation>([_conversation(id: 'c2')], null),
      );

      await c.loadMore();

      expect((c.state.value as Data<List<Conversation>>).value, hasLength(2));
      expect(c.hasMore, isFalse);
    });
  });

  _liveTests();
}

/// THE LIVE PATH.
///
/// Receiving used to be polling only. These pin the socket behaviour that
/// replaced it — and, just as importantly, that the socket is an OPTIMISATION:
/// when it is down the room must fall back to the old cadence rather than go
/// silent.
void _liveTests() {
  group('live socket', () {
    test('a pushed message for THIS thread triggers a re-read', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final socket = FakeChatSocket();
      final c = ChatRoomController(
        repo,
        socket: socket,
        pollEvery: const Duration(minutes: 5),
        idlePollEvery: const Duration(minutes: 5),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await c.openForBooking('bk1');
      final before = repo.messageReads;

      socket.push(_message(id: 'm2', body: 'live one'));
      await Future<void>.delayed(Duration.zero);

      expect(repo.messageReads, greaterThan(before));
      c.onClose();
      socket.dispose();
    });

    test('live socket status changes update room paused status in real-time', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation(isPaused: false))
        ..messagesResult = Ok(_page([_message()]));
      final socket = FakeChatSocket();
      final c = ChatRoomController(
        repo,
        socket: socket,
        pollEvery: const Duration(minutes: 5),
        idlePollEvery: const Duration(minutes: 5),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await c.openForBooking('bk1');
      expect(c.isPaused.value, isFalse);

      socket.pushStatus({
        'conversationId': 'c1',
        'isPaused': true,
        'sessionStatus': 'COMPLETED',
        'sessionMessage': 'Session completed. Chat paused.',
      });
      await Future<void>.delayed(Duration.zero);

      expect(c.isPaused.value, isTrue);
      expect(c.sessionStatus.value, 'COMPLETED');
      expect(c.sessionMessage.value, 'Session completed. Chat paused.');

      // Now resume when customer books again
      socket.pushStatus({
        'conversationId': 'c1',
        'isPaused': false,
        'sessionStatus': 'ACTIVE',
      });
      await Future<void>.delayed(Duration.zero);

      expect(c.isPaused.value, isFalse);
      expect(c.sessionStatus.value, 'ACTIVE');

      c.onClose();
      socket.dispose();
    });

    test('a push for ANOTHER thread is ignored', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final socket = FakeChatSocket();
      final c = ChatRoomController(
        repo,
        socket: socket,
        pollEvery: const Duration(minutes: 5),
        idlePollEvery: const Duration(minutes: 5),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await c.openForBooking('bk1');
      final before = repo.messageReads;

      // The server broadcasts to a PER-USER room, so every thread this user is
      // in arrives on one stream. Without the filter, opening one chat would
      // re-read it every time any other chat moved.
      socket.push(
        ChatMessage.fromJson({
          'id': 'x1',
          'conversationId': 'OTHER',
          'senderId': 'peer',
          'createdAt': '2026-05-14T09:00:00.000Z',
          'body': 'different thread',
          'type': 'TEXT',
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repo.messageReads, before);
      c.onClose();
      socket.dispose();
    });

    test('connects on open and reports live', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final socket = FakeChatSocket();
      final c = ChatRoomController(
        repo,
        socket: socket,
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await c.openForBooking('bk1');

      expect(socket.calls, contains('connect'));
      expect(c.isLive, isTrue);
      c.onClose();
      socket.dispose();
    });

    test('falls back to the fast poll when the socket drops', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final socket = FakeChatSocket();
      final c = ChatRoomController(
        repo,
        socket: socket,
        pollEvery: const Duration(milliseconds: 20),
        idlePollEvery: const Duration(minutes: 5),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await c.openForBooking('bk1');
      // Live, so the slow interval applies and nothing should poll.
      final whileLive = repo.messageReads;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(repo.messageReads, whileLive);

      socket.drop();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      // Dropped: back to the old cadence rather than silence.
      expect(repo.messageReads, greaterThan(whileLive));
      c.onClose();
      socket.dispose();
    });

    test('closing releases the socket subscriptions', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final socket = FakeChatSocket();
      final c = ChatRoomController(
        repo,
        socket: socket,
        pollEvery: const Duration(minutes: 5),
        idlePollEvery: const Duration(minutes: 5),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await c.openForBooking('bk1');
      c.onClose();
      final after = repo.messageReads;

      socket.push(_message(id: 'm9'));
      await Future<void>.delayed(Duration.zero);

      // Left subscribed, a closed room would keep re-reading forever — the
      // same leak the polling timer had.
      expect(repo.messageReads, after);
      socket.dispose();
    });

    test('with NO socket it behaves exactly as the polling version did', () async {
      final repo = FakeChatRepository()
        ..openResult = Ok(_conversation())
        ..messagesResult = Ok(_page([_message()]));
      final c = ChatRoomController(
        repo,
        pollEvery: const Duration(milliseconds: 20),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      );
      await c.openForBooking('bk1');
      final before = repo.messageReads;
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(c.isLive, isFalse);
      expect(repo.messageReads, greaterThan(before));
      c.onClose();
    });
  });
}

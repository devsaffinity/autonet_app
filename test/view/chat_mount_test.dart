import 'package:autonect/controller/chat/chat_inbox_controller.dart';
import 'package:autonect/controller/chat/chat_room_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/repositories/chat_repository.dart';
import 'package:autonect/view/screens/chat/chat_home.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// MOUNTING THE CHAT SCREENS — see providers_list_mount_test.dart for why.
///
/// Both drive an `Obx` around a `StateView`, which is the exact shape that
/// once shipped a grey screen: the builder runs outside the tracking zone, so
/// an Rx read down there subscribes to nothing and GetX throws.
Conversation _conversation({
  String id = 'c1',
  String peerId = 'peer',
  int unread = 0,
  String? lastBody = 'See you at nine',
}) => Conversation.fromJson({
  'id': id,
  'type': 'BOOKING',
  'contextId': 'bk1',
  'lastMessageAt': '2026-05-14T09:00:00.000Z',
  'peer': {'id': peerId, 'name': 'Priya Raman'},
  'unreadCount': unread,
  if (lastBody != null)
    'lastMessage': {
      'body': lastBody,
      'senderId': peerId,
      'type': 'TEXT',
      'createdAt': '2026-05-14T09:00:00.000Z',
    },
});

ChatMessage _message({
  String id = 'm1',
  String senderId = 'peer',
  String body = 'Are you still coming?',
  String? readAt,
}) => ChatMessage.fromJson({
  'id': id,
  'conversationId': 'c1',
  'senderId': senderId,
  'createdAt': '2026-05-14T09:00:00.000Z',
  'body': body,
  'type': 'TEXT',
  'readAt': readAt,
});

Future<FakeChatRepository> _pumpRoom(
  WidgetTester tester, {
  List<ChatMessage> messages = const [],
  ApiResult<Conversation>? open,
  ApiResult<ChatMessage>? send,
  String? myUserId,
}) async {
  final repo = FakeChatRepository()
    ..openResult = open ?? Ok(_conversation())
    ..messagesResult = Ok(CursorPage<ChatMessage>(messages, null))
    ..sendResult = send ?? Ok(_message(id: 'm9', senderId: 'me', body: 'hi'));
  Get.put<ChatRepository>(repo);
  Get.put(
    ChatRoomController(
      repo,
      pollEvery: const Duration(minutes: 5),
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    ),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      home: ChatRoomPage(contextId: 'bk1', myUserId: myUserId),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return repo;
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('room', () {
    testWidgets('builds and shows the thread', (tester) async {
      await _pumpRoom(tester, messages: [_message()]);

      expect(tester.takeException(), isNull);
      expect(find.text('Are you still coming?'), findsOneWidget);
      // The peer's name, from the thread rather than from a hardcoded string.
      expect(find.text('Priya Raman'), findsOneWidget);
    });

    testWidgets('none of the mocked conversation survives', (tester) async {
      await _pumpRoom(tester, messages: [_message()]);

      // The screen shipped with a fake exchange about an apartment booking.
      expect(find.textContaining('apartments'), findsNothing);
      expect(find.text('Ahmed anjims'), findsNothing);
      // 'Active Now' claimed presence nothing polls.
      expect(find.text('Active Now'), findsNothing);
    });

    testWidgets('sends what was typed and clears the field', (tester) async {
      final repo = await _pumpRoom(tester, messages: [_message()]);

      await tester.enterText(find.byType(TextField), 'on my way');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repo.calls, contains('send:c1:on my way'));
      expect(
        (tester.widget<TextField>(find.byType(TextField))).controller?.text,
        isEmpty,
      );
    });

    testWidgets('a failed send puts the text back', (tester) async {
      await _pumpRoom(
        tester,
        messages: [_message()],
        send: const Err(ApiError.network()),
      );

      await tester.enterText(find.byType(TextField), 'on my way');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Retyping a message because the network blinked is the worst part of a
      // bad chat client.
      expect(
        (tester.widget<TextField>(find.byType(TextField))).controller?.text,
        'on my way',
      );
    });

    testWidgets('an empty thread invites the first message', (tester) async {
      await _pumpRoom(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('a failed open renders the failure', (tester) async {
      await _pumpRoom(tester, open: const Err(ApiError.network()));

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget); // still composable
    });

    testWidgets('a read tick shows only on my own messages', (tester) async {
      await _pumpRoom(
        tester,
        myUserId: 'me',
        messages: [
          _message(id: 'm1', senderId: 'me', readAt: '2026-05-14T09:05:00.000Z'),
          _message(id: 'm2'),
        ],
      );

      expect(tester.takeException(), isNull);
      // One tick, on the one message I sent. On a received message it would be
      // reporting my own read state back to me.
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
    });
  });

  group('inbox', () {
    Future<FakeChatRepository> pumpInbox(
      WidgetTester tester, {
      List<Conversation> rows = const [],
      ApiResult<CursorPage<Conversation>>? result,
    }) async {
      final repo = FakeChatRepository()
        ..inboxResult =
            result ?? Ok(CursorPage<Conversation>(rows, null));
      Get.put<ChatRepository>(repo);
      Get.put(
        ChatInboxController(
          repo,
          toast: (_) {},
          showBusy: () {},
          hideBusy: () {},
        ),
      );
      await tester.pumpWidget(const GetMaterialApp(home: ChatHomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      return repo;
    }

    testWidgets('builds and lists real threads', (tester) async {
      await pumpInbox(tester, rows: [_conversation(unread: 3)]);

      expect(tester.takeException(), isNull);
      expect(find.text('Priya Raman'), findsOneWidget);
      expect(find.text('See you at nine'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('drops the five fabricated conversations', (tester) async {
      await pumpInbox(tester, rows: [_conversation()]);

      expect(find.text('Amed anjims'), findsNothing);
      expect(find.text('alem leain'), findsNothing);
      // 'Typing...' needs a live socket; showing it from a poll would be
      // inventing somebody's activity.
      expect(find.text('Typing...'), findsNothing);
    });

    testWidgets('the search box actually filters', (tester) async {
      await pumpInbox(tester, rows: [_conversation()]);

      await tester.enterText(find.byType(TextField).first, 'nobody');
      await tester.pump();

      // The controller had search() and visible() written and unreachable:
      // the bar was constructed const, with no onChanged.
      expect(tester.takeException(), isNull);
      expect(find.text('Priya Raman'), findsNothing);
      expect(find.textContaining('Nothing matches'), findsOneWidget);
    });

    testWidgets('an empty inbox says where threads come from', (tester) async {
      await pumpInbox(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('book a provider'), findsOneWidget);
    });

    testWidgets('a thread nobody has written in yet says so', (tester) async {
      await pumpInbox(tester, rows: [_conversation(lastBody: null)]);

      expect(tester.takeException(), isNull);
      // Opening a thread creates it, so this is a real state rather than a
      // decoding gap.
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('a failed load renders the failure, not an empty inbox', (
      tester,
    ) async {
      await pumpInbox(tester, result: const Err(ApiError.network()));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('book a provider'), findsNothing);
    });

    testWidgets('renders InitialsAvatar fallback when peer has no avatarUrl or raw S3 key', (
      tester,
    ) async {
      await pumpInbox(
        tester,
        rows: [
          Conversation.fromJson({
            'id': 'c1',
            'type': 'BOOKING',
            'contextId': 'bk1',
            'lastMessageAt': '2026-05-14T09:00:00.000Z',
            'peer': {
              'id': 'p1',
              'name': 'Rashid Khan',
              'avatarUrl': 'avatars/p1/some-key.jpg',
            },
            'unreadCount': 0,
          }),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Rashid Khan'), findsOneWidget);
      expect(find.text('RK'), findsOneWidget);
    });

    testWidgets('renders CommonImageView when peer has valid https avatarUrl', (
      tester,
    ) async {
      await pumpInbox(
        tester,
        rows: [
          Conversation.fromJson({
            'id': 'c1',
            'type': 'BOOKING',
            'contextId': 'bk1',
            'lastMessageAt': '2026-05-14T09:00:00.000Z',
            'peer': {
              'id': 'p1',
              'name': 'Rashid Khan',
              'avatarUrl': 'https://s3.example.com/avatar.jpg',
            },
            'unreadCount': 0,
          }),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Rashid Khan'), findsOneWidget);
      expect(find.byType(CommonImageView), findsWidgets);
    });
  });
}

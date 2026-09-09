import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/request_enums.dart' show enumFromWire;

/// One page of a CURSOR-paginated list.
///
/// Not [Paged]: chat pages by cursor, not by page number, because a thread
/// grows at the end while you are reading it and offset pagination would
/// silently repeat or skip a message every time somebody sends one.
class CursorPage<T> {
  const CursorPage(this.items, this.nextCursor);

  final List<T> items;

  /// Null when the server did not offer one — that is the stop condition, and
  /// the only one. A client that guessed from a short page would page forever
  /// against a server that never said there was more.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// What a thread is ABOUT. Every conversation is anchored to a deal — there is
/// no direct messaging, which is what lets the server derive the participants
/// instead of trusting the client with them.
enum ConversationType {
  offer('OFFER'),
  booking('BOOKING');

  const ConversationType(this.wire);

  final String wire;

  static ConversationType? fromWire(String? v) =>
      enumFromWire(values, v, (e) => e.wire);
}

/// What kind of thing a message carries.
enum MessageType {
  text('TEXT'),
  image('IMAGE'),
  file('FILE'),
  voice('VOICE');

  const MessageType(this.wire);

  final String wire;

  static MessageType? fromWire(String? v) =>
      enumFromWire(values, v, (e) => e.wire);
}

/// The other person in a thread. NAME AND AVATAR ONLY, matching the server's
/// projection: a conversation is not a reason to hold somebody's email.
class ChatPeer {
  const ChatPeer({required this.id, this.name, this.avatarUrl});

  final String id;
  final String? name;
  final String? avatarUrl;

  /// What to render when the peer has no name set. Never a placeholder person.
  String get displayName {
    final n = name?.trim();
    return (n == null || n.isEmpty) ? 'Autonect user' : n;
  }

  static ChatPeer fromJson(Map<String, dynamic> j) => ChatPeer(
    id: jsonString(j, 'id'),
    name: j['name'] as String?,
    avatarUrl: j['avatarUrl'] as String?,
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.createdAt,
    this.body,
    this.type,
    this.readAt,
    this.attachmentUrl,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final DateTime createdAt;
  final String? body;
  final MessageType? type;

  /// When the PEER read it. Null means unread by them, which is what the
  /// single/double tick renders.
  final DateTime? readAt;

  /// A short-lived signed URL, present only on media. The server mints it per
  /// read, so it must not be cached beyond the screen.
  final String? attachmentUrl;

  bool isMine(String? myUserId) => myUserId != null && senderId == myUserId;

  static ChatMessage fromJson(Map<String, dynamic> j) {
    final attachment = j['attachment'];
    return ChatMessage(
      id: jsonString(j, 'id'),
      conversationId: jsonString(j, 'conversationId'),
      senderId: jsonString(j, 'senderId'),
      createdAt: DateTime.parse(jsonString(j, 'createdAt')),
      body: j['body'] as String?,
      type: MessageType.fromWire(j['type'] as String?),
      readAt: j['readAt'] == null
          ? null
          : DateTime.tryParse(j['readAt'] as String),
      attachmentUrl: attachment is Map ? attachment['url'] as String? : null,
    );
  }
}

/// A thread, as the inbox shows it.
class Conversation {
  const Conversation({
    required this.id,
    required this.contextId,
    required this.lastMessageAt,
    this.type,
    this.peer,
    this.unreadCount = 0,
    this.lastMessage,
  });

  final String id;
  final String contextId;
  final DateTime lastMessageAt;
  final ConversationType? type;
  final ChatPeer? peer;
  final int unreadCount;

  /// The last message in the thread, or null for a thread nobody has written
  /// in yet — which is a real state, because opening a thread creates it.
  final ChatMessage? lastMessage;

  bool get hasUnread => unreadCount > 0;

  static Conversation fromJson(Map<String, dynamic> j) {
    final peer = j['peer'];
    final last = j['lastMessage'];
    return Conversation(
      id: jsonString(j, 'id'),
      contextId: jsonString(j, 'contextId'),
      lastMessageAt: DateTime.parse(jsonString(j, 'lastMessageAt')),
      type: ConversationType.fromWire(j['type'] as String?),
      peer: peer is Map ? ChatPeer.fromJson(peer.cast<String, dynamic>()) : null,
      unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
      // The inbox projection omits id/conversationId on the last message, so it
      // is decoded loosely rather than through ChatMessage.fromJson, which
      // would throw on the missing id.
      lastMessage: last is Map
          ? ChatMessage(
              id: '',
              conversationId: jsonString(j, 'id'),
              senderId: last['senderId'] as String? ?? '',
              createdAt:
                  DateTime.tryParse(last['createdAt'] as String? ?? '') ??
                  DateTime.parse(jsonString(j, 'lastMessageAt')),
              body: last['body'] as String?,
              type: MessageType.fromWire(last['type'] as String?),
            )
          : null,
    );
  }
}

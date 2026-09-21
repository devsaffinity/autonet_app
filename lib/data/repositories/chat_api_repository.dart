import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_envelope.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/repositories/chat_repository.dart';

class ChatApiRepository implements ChatRepository {
  /// [tokens] is accepted but not retained — see CatalogApiRepository for why
  /// every repository takes the same pair.
  ChatApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  static const int _defaultLimit = 30;
  static const int _maxLimit = 100;

  static Conversation _conversation(Object? d) =>
      Conversation.fromJson((d as Map).cast<String, dynamic>());

  /// The ONE cursor decoder.
  ///
  /// `nextCursor` is absent — not null — when there is no more, so a missing
  /// key is the stop condition. Reading it off `meta` rather than guessing
  /// from a short page is what keeps paging terminating.
  static EnvelopeDecoder<CursorPage<T>> _page<T>(
    T Function(Map<String, dynamic>) fromJson,
  ) => (data, meta) => CursorPage<T>(
    (data as List)
        .map((e) => fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false),
    meta?['nextCursor'] as String?,
  );

  Future<ApiResult<Conversation>> _open(String type, String contextId) => _c.send(
    method: 'POST',
    path: '/v1/conversations',
    body: {'type': type, 'contextId': contextId},
    decode: _conversation,
  );

  @override
  Future<ApiResult<Conversation>> openForBooking(String bookingId) =>
      _open('BOOKING', bookingId);

  @override
  Future<ApiResult<Conversation>> openForOffer(String offerId) =>
      _open('OFFER', offerId);

  @override
  Future<ApiResult<Conversation>> byId(String conversationId) async {
    final res = await _c.send(
      method: 'GET',
      path: '/v1/conversations/$conversationId',
      decode: _conversation,
    );
    if (res is Ok<Conversation>) return res;
    final inboxRes = await inbox(limit: 50);
    if (inboxRes is Ok<CursorPage<Conversation>>) {
      final found =
          inboxRes.value.items.where((c) => c.id == conversationId).firstOrNull;
      if (found != null) return Ok(found);
    }
    return res;
  }

  @override
  Future<ApiResult<CursorPage<Conversation>>> inbox({
    String? cursor,
    int limit = _defaultLimit,
  }) => _c.sendEnvelope(
    method: 'GET',
    path: '/v1/conversations',
    query: {
      'limit': '${limit.clamp(1, _maxLimit)}',
      'cursor': ?cursor,
    },
    decode: _page(Conversation.fromJson),
  );

  @override
  Future<ApiResult<CursorPage<ChatMessage>>> messages(
    String conversationId, {
    String? cursor,
    int limit = _defaultLimit,
  }) => _c.sendEnvelope(
    method: 'GET',
    path: '/v1/conversations/$conversationId/messages',
    query: {
      'limit': '${limit.clamp(1, _maxLimit)}',
      'cursor': ?cursor,
    },
    decode: _page(ChatMessage.fromJson),
  );

  @override
  Future<ApiResult<ChatMessage>> send({
    required String conversationId,
    required String body,
  }) {
    final trimmed = body.trim();
    // Refused BEFORE the wire: the server's refine rejects a TEXT message with
    // no body, and a round trip to learn that is a round trip spent on
    // something the caller could see.
    if (trimmed.isEmpty) {
      throw ArgumentError.value(body, 'body', 'A message cannot be empty');
    }
    return _c.send(
      method: 'POST',
      path: '/v1/conversations/$conversationId/messages',
      body: {'type': 'TEXT', 'body': trimmed},
      decode: (d) => ChatMessage.fromJson((d as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<ApiResult<int>> markRead(String conversationId) => _c.send(
    method: 'POST',
    path: '/v1/conversations/$conversationId/read',
    decode: (d) => ((d as Map)['read'] as num?)?.toInt() ?? 0,
  );
}

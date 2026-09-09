import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/conversation.dart';

/// `/v1/conversations`, for both sides.
///
/// EVERY THREAD IS ANCHORED TO A DEAL. There is no direct messaging and no way
/// to name a recipient: [openForBooking] and [openForOffer] send a CONTEXT id
/// and the server derives who is allowed in. That is what stops anybody
/// opening a thread with a stranger, and it is why neither method takes a user
/// id.
abstract class ChatRepository {
  /// Get-or-create the thread for a booking. Idempotent: both parties calling
  /// it get the same thread, whoever arrives first.
  Future<ApiResult<Conversation>> openForBooking(String bookingId);

  /// Get-or-create the thread for an offer.
  Future<ApiResult<Conversation>> openForOffer(String offerId);

  /// The inbox, newest thread first.
  Future<ApiResult<CursorPage<Conversation>>> inbox({String? cursor, int limit});

  /// History, NEWEST FIRST — the order the server returns and the order a chat
  /// renders in a reversed list. [cursor] pages BACKWARDS into the past.
  Future<ApiResult<CursorPage<ChatMessage>>> messages(
    String conversationId, {
    String? cursor,
    int limit,
  });

  /// Send over plain HTTP.
  ///
  /// The socket gateway is untouched and unused by this client; this is the
  /// same service call it makes, so a message sent here is persisted, bumps
  /// the thread and notifies the peer identically.
  Future<ApiResult<ChatMessage>> send({
    required String conversationId,
    required String body,
  });

  /// Mark the peer's messages read; returns how many flipped.
  Future<ApiResult<int>> markRead(String conversationId);
}

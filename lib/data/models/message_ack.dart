/// Every payload-less endpoint uses MessageAck as T. NEVER use void as T —
/// ApiResult's Ok<void> does not compile.
class MessageAck {
  const MessageAck(this.message);

  final String message;

  factory MessageAck.fromJson(Object? d) =>
      MessageAck((d is Map ? d['message'] as String? : null) ?? 'Done');
}

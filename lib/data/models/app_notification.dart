import 'dart:convert' show jsonDecode;

import 'package:autonect/data/models/auth_user.dart' show jsonString;

/// One row of `GET /v1/notifications`.
///
/// `type` is a RAW wire string, deliberately not an enum: the backend emits
/// whatever its routing map defines (offer.created, order.status.changed, …)
/// and adding a new one must not make an older build drop notifications it
/// could still have rendered. The icon falls back instead.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.data,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  /// Free-form payload — usually the id of whatever the notification is about.
  final Map<String, dynamic>? data;

  /// The entity this points at, when the payload names one. Used to deep-link.
  String? get requestId => _idFor('requestId');
  String? get orderId => _idFor('orderId');
  String? get bookingId => _idFor('bookingId');
  String? get conversationId =>
      _idFor('conversationId') ??
      (type.startsWith('message') || type.startsWith('chat')
          ? (_idFor('contextId') ?? _idFor('id'))
          : null);
  String? get offerId => _idFor('offerId');

  String? _idFor(String key) {
    final v = data?[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    read: read ?? this.read,
    createdAt: createdAt,
    data: data,
  );

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final rawData = j['data'];
    Map<String, dynamic>? data;
    if (rawData is Map) {
      data = rawData.cast<String, dynamic>();
    } else if (rawData is String && rawData.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(rawData);
        data = decoded is Map ? decoded.cast<String, dynamic>() : null;
      } catch (_) {
        data = null;
      }
    } else {
      data = null;
    }
    final at = j['createdAt'];
    return AppNotification(
      id: jsonString(j, 'id'),
      type: jsonString(j, 'type'),
      title: jsonString(j, 'title'),
      body: jsonString(j, 'body'),
      read: j['read'] == true,
      // Falls back to now rather than throwing: a notification with an
      // unparseable timestamp is still worth showing.
      createdAt: at is String
          ? (DateTime.tryParse(at) ?? DateTime.now())
          : DateTime.now(),
      data: data,
    );
  }
}

/// A page of notifications plus the unread count.
///
/// The count comes from the SERVER on the same read — it is not
/// `items.where((n) => !n.read).length`, which would only ever count the page
/// in hand and undercount the badge the moment there is more than one page.
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.unread,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  final List<AppNotification> items;
  final int unread;
  final int total;
  final int page;
  final bool hasMore;
}

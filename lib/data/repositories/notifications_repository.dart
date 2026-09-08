import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/app_notification.dart';

/// The in-app notification centre.
///
/// Push is deliberately absent: the backend accepts device tokens, but the app
/// has no firebase_core/firebase_messaging and adding them is a platform
/// configuration job, not a wiring one. Polling this on mount and on
/// pull-to-refresh is enough for a badge.
abstract class NotificationsRepository {
  /// One page, newest first, WITH the server's unread count.
  Future<ApiResult<NotificationPage>> list({int page = 1, int limit = 20});

  /// Returns how many rows changed — 0 when it was already read, which lets a
  /// caller skip a pointless refresh.
  Future<ApiResult<int>> markRead(String id);

  Future<ApiResult<int>> markAllRead();
}

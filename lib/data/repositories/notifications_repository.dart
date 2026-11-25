import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/app_notification.dart';

/// The in-app notification centre.
///
/// Push is a separate delivery of the same events (see PushService and
/// DevicesRepository). Do not create a row here when a push arrives: the server
/// has already stored it, so refresh this list instead.
abstract class NotificationsRepository {
  /// One page, newest first, WITH the server's unread count.
  Future<ApiResult<NotificationPage>> list({int page = 1, int limit = 20});

  /// Returns how many rows changed — 0 when it was already read, which lets a
  /// caller skip a pointless refresh.
  Future<ApiResult<int>> markRead(String id);

  Future<ApiResult<int>> markAllRead();

  /// Deletes one. Returns how many rows went — 0 when it was already gone, or
  /// when it was never this account's, which the server does not distinguish
  /// on purpose: both mean "it is not there", and telling them apart would
  /// confirm that someone else's uuid exists.
  Future<ApiResult<int>> remove(String id);

  /// Clears the whole centre. Returns how many rows went.
  Future<ApiResult<int>> removeAll();
}

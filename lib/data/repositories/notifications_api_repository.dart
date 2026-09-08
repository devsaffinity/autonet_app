import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/app_notification.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/repositories/notifications_repository.dart';

class NotificationsApiRepository implements NotificationsRepository {
  /// [tokens] is accepted but not retained, so main.dart constructs every
  /// repository identically.
  NotificationsApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  static const int _maxLimit = 50;

  @override
  Future<ApiResult<NotificationPage>> list({int page = 1, int limit = 20}) =>
      _c.sendEnvelope(
        method: 'GET',
        path: '/v1/notifications',
        query: {
          'page': '${page < 1 ? 1 : page}',
          'limit': '${limit.clamp(1, _maxLimit)}',
        },
        // The decoder takes the raw meta, not just the items: `unread` rides
        // alongside the pagination fields and PageMeta drops unknown keys, so
        // reading it through PageMeta would silently lose the badge count.
        decode: (data, meta) {
          final pm = meta == null ? PageMeta.empty : PageMeta.fromJson(meta);
          return NotificationPage(
            items: [
              for (final e in data as List)
                AppNotification.fromJson((e as Map).cast<String, dynamic>()),
            ],
            unread: _int(meta?['unread']),
            total: pm.total,
            page: pm.page,
            hasMore: pm.hasNextPage,
          );
        },
      );

  @override
  Future<ApiResult<int>> markRead(String id) => _c.send(
    method: 'PATCH',
    path: '/v1/notifications/$id/read',
    decode: (d) => _int((d as Map?)?['read']),
  );

  @override
  Future<ApiResult<int>> markAllRead() => _c.send(
    method: 'POST',
    path: '/v1/notifications/read-all',
    decode: (d) => _int((d as Map?)?['read']),
  );

  static int _int(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
}

import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/repositories/devices_repository.dart';

class DevicesApiRepository implements DevicesRepository {
  /// [tokens] is accepted but not retained, so main.dart constructs every
  /// repository identically.
  DevicesApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  @override
  Future<ApiResult<void>> register(
    String fcmToken, {
    required String platform,
  }) => _c.send<void>(
    method: 'POST',
    path: '/v1/devices/token',
    body: {'fcmToken': fcmToken, 'platform': platform},
    decode: (_) {},
  );

  @override
  Future<ApiResult<void>> remove(String fcmToken) => _c.send<void>(
    method: 'DELETE',
    path: '/v1/devices/token',
    body: {'fcmToken': fcmToken},
    decode: (_) {},
  );

  @override
  Future<ApiResult<TestPushResult>> sendTest() => _c.send(
    method: 'POST',
    path: '/v1/devices/token/test',
    decode: (d) {
      final m = d is Map ? d : const {};
      return TestPushResult(
        sent: _int(m['sent']),
        removed: _int(m['removed']),
        devices: _int(m['devices']),
      );
    },
  );

  static int _int(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
}

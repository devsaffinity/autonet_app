import 'package:autonect/data/core/api_result.dart';

/// What `POST /v1/devices/token/test` reports.
class TestPushResult {
  const TestPushResult({
    required this.sent,
    required this.removed,
    required this.devices,
  });

  /// Devices FCM accepted the message for. Zero means the server holds no token
  /// for this account, i.e. registration never worked.
  final int sent;

  /// Dead tokens the server pruned while sending.
  final int removed;
  final int devices;
}

/// The push-token half of the notifications API.
///
/// A token belongs to ONE account on the server: registering it under a
/// different user moves it, which is what makes a shared phone behave across
/// logout and login.
abstract class DevicesRepository {
  /// [platform] is the wire value, `ANDROID` or `IOS`.
  Future<ApiResult<void>> register(String fcmToken, {required String platform});

  /// Must run BEFORE the session is cleared — it needs the access token.
  Future<ApiResult<void>> remove(String fcmToken);

  /// Sends a push to the caller's own devices only. Limited to 3 per minute.
  Future<ApiResult<TestPushResult>> sendTest();
}

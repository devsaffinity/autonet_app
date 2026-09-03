import 'package:autonect/constants/app_role.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/message_ack.dart';
import 'package:autonect/data/models/token_pair.dart';

/// The seam widget tests fake. Screens and AuthController depend on this, never
/// on AuthApiRepository, so a test never needs a transport at all.
abstract class AuthRepository {
  /// Returns NO tokens: the account is left PENDING_VERIFICATION and the server
  /// emails a 6-digit OTP. Sign-in happens at verifyOtp.
  Future<ApiResult<MessageAck>> signup({
    required String email,
    required String password,
    required AppRole role,
    String? name,
    String? phone,
  });

  Future<ApiResult<TokenPair>> verifyOtp({
    required String email,
    required String code,
  });

  Future<ApiResult<MessageAck>> resendOtp(String email);

  Future<ApiResult<TokenPair>> login({
    required String email,
    required String password,
  });

  Future<ApiResult<TokenPair>> social({
    required String provider,
    required String idToken,
    AppRole? role,
  });

  /// ALWAYS 200 by design — the server refuses to leak whether an account
  /// exists. Copy must never say "email not found".
  Future<ApiResult<MessageAck>> forgot(String email);

  Future<ApiResult<MessageAck>> reset({
    required String email,
    required String code,
    required String password,
  });

  Future<ApiResult<MessageAck>> logout();
}

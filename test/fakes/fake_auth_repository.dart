import 'package:autonect/constants/app_role.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/message_ack.dart';
import 'package:autonect/data/models/token_pair.dart';
import 'package:autonect/data/repositories/auth_repository.dart';

/// Lets controller tests run with no transport, no ApiClient and no prefs.
class FakeAuthRepository implements AuthRepository {
  ApiResult<TokenPair>? tokenResult;
  ApiResult<MessageAck> ackResult = const Ok(MessageAck('ok'));
  final List<String> calls = [];

  ApiResult<TokenPair> get _tokens =>
      tokenResult ?? const Err(ApiError.malformed('no tokenResult scripted'));

  @override
  Future<ApiResult<MessageAck>> forgot(String email) async {
    calls.add('forgot:$email');
    return ackResult;
  }

  @override
  Future<ApiResult<TokenPair>> login({
    required String email,
    required String password,
  }) async {
    calls.add('login:$email');
    return _tokens;
  }

  @override
  Future<ApiResult<MessageAck>> logout() async {
    calls.add('logout');
    return ackResult;
  }

  @override
  Future<ApiResult<MessageAck>> resendOtp(String email) async {
    calls.add('resend:$email');
    return ackResult;
  }

  @override
  Future<ApiResult<MessageAck>> reset({
    required String email,
    required String code,
    required String password,
  }) async {
    calls.add('reset:$email:$code');
    return ackResult;
  }

  @override
  Future<ApiResult<MessageAck>> signup({
    required String email,
    required String password,
    required AppRole role,
    String? name,
    String? phone,
  }) async {
    calls.add('signup:$email:${role.wire}');
    return ackResult;
  }

  @override
  Future<ApiResult<TokenPair>> social({
    required String provider,
    required String idToken,
    AppRole? role,
  }) async {
    calls.add('social:$provider');
    return _tokens;
  }

  @override
  Future<ApiResult<TokenPair>> verifyOtp({
    required String email,
    required String code,
  }) async {
    calls.add('verify:$email:$code');
    return _tokens;
  }
}

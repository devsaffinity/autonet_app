import 'package:autonect/data/models/auth_user.dart';

/// Shape per auth.service.ts:31 issuePair — the `data` of every TOKENS response.
class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory TokenPair.fromJson(Map<String, dynamic> j) => TokenPair(
    accessToken: jsonString(j, 'accessToken'),
    refreshToken: jsonString(j, 'refreshToken'),
    user: AuthUser.fromJson((j['user'] as Map).cast<String, dynamic>()),
  );
}

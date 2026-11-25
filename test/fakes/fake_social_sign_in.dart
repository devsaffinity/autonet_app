import 'package:autonect/services/social_sign_in_gateway.dart';

/// Scripted stand-in for the Google/Firebase gateway.
class FakeSocialSignInGateway implements SocialSignInGateway {
  FakeSocialSignInGateway([this.result = const SocialSignInCancelled()]);

  SocialSignInResult result;
  bool supported = true;
  int picks = 0;
  int signOuts = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<SocialSignInResult> signInWithGoogle() async {
    picks++;
    return result;
  }

  @override
  Future<void> signOut() async => signOuts++;
}

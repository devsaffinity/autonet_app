/// The outcome of asking the OS to sign the user in with a third party.
sealed class SocialSignInResult {
  const SocialSignInResult();
}

/// [idToken] is what POST /v1/auth/social verifies. For Google it is the
/// FIREBASE ID token (minted after Google authenticates the user), so the
/// backend checks it with the Firebase Admin SDK for project autonect1.
class SocialSignInSuccess extends SocialSignInResult {
  const SocialSignInSuccess(this.idToken);
  final String idToken;
}

/// The user closed the account picker. A normal answer, not an error: nothing
/// is shown and nothing is sent to the server.
class SocialSignInCancelled extends SocialSignInResult {
  const SocialSignInCancelled();
}

/// [message] is already written for the user.
class SocialSignInFailed extends SocialSignInResult {
  const SocialSignInFailed(this.message);
  final String message;
}

/// Google sign-in through Firebase, behind an interface so the controller and
/// every screen test run with no platform channel and no Firebase project.
/// `firebase_social_sign_in_gateway.dart` is the only file that imports the
/// SDKs.
abstract class SocialSignInGateway {
  /// False where it cannot run (web, desktop) or when the build has no Firebase
  /// config. The Google button is then hidden.
  bool get isSupported;

  /// Shows the Google account picker and returns a token for the server.
  /// Never throws.
  Future<SocialSignInResult> signInWithGoogle();

  /// Forgets the Google and Firebase session on this device, so the next tap
  /// shows the account picker instead of silently reusing the last account.
  /// Never throws.
  Future<void> signOut();
}

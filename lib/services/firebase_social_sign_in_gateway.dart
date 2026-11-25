import 'dart:async';

import 'package:autonect/services/firebase_bootstrap.dart';
import 'package:autonect/services/social_sign_in_gateway.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The only file that imports firebase_auth or google_sign_in.
///
/// Flow: Google account picker -> Google ID token -> Firebase credential ->
/// signInWithCredential -> Firebase ID token. The Firebase token is what the
/// backend verifies. On Android the plugin reads the web client id from
/// `default_web_client_id`, which the Google services Gradle plugin generates
/// from google-services.json — so that file must be the one downloaded AFTER
/// Google was enabled under Firebase Authentication.
class FirebaseSocialSignInGateway implements SocialSignInGateway {
  Future<void>? _googleReady;

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<SocialSignInResult> signInWithGoogle() async {
    if (!isSupported) {
      return const SocialSignInFailed(
        'Google sign-in is not available on this device.',
      );
    }
    try {
      if (!await ensureFirebaseStarted()) {
        return const SocialSignInFailed(
          'Google sign-in is not available right now. Please use your email '
          'and password.',
        );
      }
      // google_sign_in 7.x must be initialised once before authenticate().
      await (_googleReady ??= GoogleSignIn.instance.initialize());

      final account = await GoogleSignIn.instance.authenticate();
      final googleToken = account.authentication.idToken;
      if (googleToken == null) {
        // The web client id is missing from google-services.json: Google
        // signed the user in but would not mint an id token.
        debugPrint('Google sign-in: no idToken. Re-download google-services.json '
            'after enabling Google in Firebase Authentication.');
        return const SocialSignInFailed(
          'Google sign-in is not set up correctly. Please try again later.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: googleToken);
      final user = (await FirebaseAuth.instance.signInWithCredential(
        credential,
      )).user;
      final firebaseToken = await user?.getIdToken();
      if (firebaseToken == null || firebaseToken.isEmpty) {
        return const SocialSignInFailed(
          'Could not complete Google sign-in. Please try again.',
        );
      }
      return SocialSignInSuccess(firebaseToken);
    } on GoogleSignInException catch (e) {
      return _fromGoogle(e);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in: Firebase ${e.code}: ${e.message}');
      return SocialSignInFailed(switch (e.code) {
        'network-request-failed' =>
          'No connection. Check your internet and try again.',
        'user-disabled' => 'This Google account has been disabled.',
        _ => 'Could not complete Google sign-in. Please try again.',
      });
    } catch (e, st) {
      debugPrint('Google sign-in failed: $e\n$st');
      return const SocialSignInFailed(
        'Could not complete Google sign-in. Please try again.',
      );
    }
  }

  static SocialSignInResult _fromGoogle(GoogleSignInException e) {
    debugPrint('Google sign-in: ${e.code} ${e.description}');
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return const SocialSignInCancelled();
      case GoogleSignInExceptionCode.uiUnavailable:
        return const SocialSignInFailed(
          'Google sign-in could not open. Please try again.',
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        // Wrong or missing SHA fingerprint / web client: a build problem the
        // user cannot fix, but the message must not blame them.
        return const SocialSignInFailed(
          'Google sign-in is not set up correctly. Please try again later.',
        );
      case GoogleSignInExceptionCode.userMismatch:
      case GoogleSignInExceptionCode.unknownError:
        return const SocialSignInFailed(
          'Could not complete Google sign-in. Please try again.',
        );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Initialise here too: after an app restart nothing has called it yet,
      // and a sign-out that silently did nothing would leave the last account
      // remembered.
      await (_googleReady ??= GoogleSignIn.instance.initialize());
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      if (await ensureFirebaseStarted()) await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}

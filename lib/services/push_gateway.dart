/// A push, reduced to what the app routes on.
///
/// Everything in [data] is a string: FCM cannot carry anything else.
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    required this.data,
  });

  final String title;
  final String body;
  final Map<String, String> data;

  /// What to open. Missing or unknown values are the caller's to handle — new
  /// event types ship without an app release.
  String get type => data['type'] ?? '';
}

/// Firebase Cloud Messaging and the Android notification channel, behind an
/// interface so the push logic and every screen test run without a platform
/// channel or a Firebase project. `firebase_push_gateway.dart` is the only file
/// that imports the SDKs.
abstract class PushGateway {
  /// False where push cannot run (web, desktop) or when the Firebase config
  /// files are not in the build. Every other member is then inert.
  bool get isSupported;

  /// The server's `platform` field: `ANDROID` or `IOS`.
  String get platform;

  /// Starts Firebase and creates the `autonect_default` channel. Idempotent;
  /// never throws — false when the app was built without its Firebase config.
  Future<bool> init();

  /// Shows the OS permission prompt. True when granted. Refusal is a normal
  /// answer, not an error — people say no.
  Future<bool> requestPermission();

  /// The FCM registration token, or null when there is none yet.
  Future<String?> getToken();

  /// Fires when FCM rotates the token on its own.
  Stream<String> get onTokenRefresh;

  /// A push that arrived while the app was in the foreground.
  Stream<PushMessage> get onForeground;

  /// A notification the user tapped, from the background or from a local
  /// notification drawn while in the foreground.
  Stream<PushMessage> get onOpened;

  /// The notification whose tap LAUNCHED the app from a terminated state.
  Future<PushMessage?> initialMessage();

  /// Draws [message] in the shade. Android only — iOS presents foreground
  /// pushes itself, and doing both would show every one twice.
  Future<void> showLocal(PushMessage message);

  /// Forgets this device's token so the next one is a fresh identity.
  Future<void> deleteToken();
}

import 'dart:async';

import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/repositories/devices_repository.dart';
import 'package:autonect/services/push_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Push notifications, end to end: permission, token registration, the
/// foreground banner and tap routing.
///
/// Every failure here is swallowed on purpose. Push is an enhancement — a
/// refused permission, a missing Firebase config or a flaky network must never
/// stop someone logging in or out.
class PushService {
  PushService({
    required this.gateway,
    required this.devices,
    required this.loggedIn,
    required this.openTarget,
    this.onForegroundPush,
  });

  final PushGateway gateway;
  final DevicesRepository devices;

  /// Tracks the session. Registration follows it, so no login path has to
  /// remember to call us.
  final RxBool loggedIn;

  /// Pushes the screen for a tapped notification's `data`.
  final Future<void> Function(Map<String, String> data) openTarget;

  /// A push arrived in the foreground — refresh the unread badge.
  final void Function()? onForegroundPush;

  /// How long logout waits for the server to drop this device before moving
  /// on. A dead network must not trap someone inside the app.
  static const Duration removeTimeout = Duration(seconds: 5);

  bool _started = false;
  bool _appReady = false;
  PushMessage? _pending;
  String? _registeredToken;
  Future<void>? _registering;

  /// Starts Firebase and wires the listeners. Safe to call more than once.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!await gateway.init()) return;

    gateway.onTokenRefresh.listen((t) {
      if (loggedIn.value) unawaited(_register(t));
    });
    gateway.onForeground.listen((m) {
      // 'test' is the wiring check: still shown, so the tester sees it work.
      unawaited(gateway.showLocal(m));
      onForegroundPush?.call();
    });
    gateway.onOpened.listen(_handleTap);

    // The tap that launched a terminated app. Held until the app has a screen
    // to navigate from — the navigator is not ready yet.
    final initial = await gateway.initialMessage();
    if (initial != null) _handleTap(initial);

    ever<bool>(loggedIn, (v) {
      if (v) unawaited(registerDevice());
    });
    if (loggedIn.value) unawaited(registerDevice());
  }

  /// Asks for permission, then sends the token to the server. Idempotent and
  /// non-throwing; concurrent calls share one round trip.
  Future<void> registerDevice() => _registering ??= _doRegister().whenComplete(
    () => _registering = null,
  );

  Future<void> _doRegister() async {
    try {
      if (!gateway.isSupported) return;
      // Refusal is a normal answer. The token is registered regardless, so a
      // person who allows notifications later in system settings gets them
      // without having to log in again.
      await gateway.requestPermission();
      final token = await gateway.getToken();
      if (token != null) await _register(token);
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  Future<void> _register(String token) async {
    final r = await devices.register(token, platform: gateway.platform);
    if (r is Ok) _registeredToken = token;
  }

  /// Logout. Call BEFORE the session is cleared: removal needs the access
  /// token. Without it the next person to log in on this phone keeps receiving
  /// the previous user's notifications.
  Future<void> unregisterDevice() async {
    try {
      final token = _registeredToken ?? await gateway.getToken();
      if (token != null) {
        await devices.remove(token).timeout(removeTimeout);
      }
    } catch (e) {
      debugPrint('Push removal failed: $e');
    }
    await forgetDevice();
  }

  /// The session is already dead server-side (expired), so the server cannot
  /// be told. Dropping the local token still gives the next login a fresh
  /// identity, and the server re-homes a token to whoever registers it next.
  Future<void> forgetDevice() async {
    _registeredToken = null;
    _pending = null;
    try {
      await gateway.deleteToken();
    } catch (_) {}
  }

  /// The splash has routed and a shell is on screen. Releases a tap that
  /// launched the app.
  void appReady() {
    _appReady = true;
    final m = _pending;
    _pending = null;
    if (m != null) _handleTap(m);
  }

  void _handleTap(PushMessage m) {
    // Nobody to show it to. The next login starts clean.
    if (!loggedIn.value) return;
    if (!_appReady) {
      _pending = m;
      return;
    }
    // A routing failure must not surface as an uncaught async error.
    unawaited(
      openTarget(m.data).catchError((Object e) {
        debugPrint('Push tap routing failed: $e');
      }),
    );
  }
}

import 'dart:async';

import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/repositories/devices_repository.dart';
import 'package:autonect/services/push_gateway.dart';
import 'package:autonect/services/push_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class FakeGateway implements PushGateway {
  FakeGateway({this.initOk = true, this.token = 'tok-1'});

  final bool initOk;
  String? token;

  int permissionAsks = 0;
  int deleted = 0;
  final List<PushMessage> shown = [];
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  PushMessage? initial;

  @override
  bool get isSupported => initOk;
  @override
  String get platform => 'ANDROID';
  @override
  Future<bool> init() async => initOk;
  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return false; // refusal must not stop registration
  }

  @override
  Future<String?> getToken() async => token;
  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushMessage> get onForeground => foreground.stream;
  @override
  Stream<PushMessage> get onOpened => opened.stream;
  @override
  Future<PushMessage?> initialMessage() async => initial;
  @override
  Future<void> showLocal(PushMessage message) async => shown.add(message);
  @override
  Future<void> deleteToken() async => deleted++;
}

class FakeDevices implements DevicesRepository {
  final List<(String, String)> registered = [];
  final List<String> removed = [];
  bool failRemove = false;
  bool hangRemove = false;

  @override
  Future<ApiResult<void>> register(
    String fcmToken, {
    required String platform,
  }) async {
    registered.add((fcmToken, platform));
    return const Ok(null);
  }

  @override
  Future<ApiResult<void>> remove(String fcmToken) async {
    if (hangRemove) return Completer<ApiResult<void>>().future;
    removed.add(fcmToken);
    return failRemove ? const Err(ApiError.network()) : const Ok(null);
  }

  @override
  Future<ApiResult<TestPushResult>> sendTest() async =>
      const Ok(TestPushResult(sent: 1, removed: 0, devices: 1));
}

PushMessage msg(String type, [Map<String, String> extra = const {}]) =>
    PushMessage(title: 't', body: 'b', data: {'type': type, ...extra});

void main() {
  late FakeGateway gateway;
  late FakeDevices devices;
  late RxBool loggedIn;
  late List<Map<String, String>> opened;
  late int foregroundPings;

  PushService build() => PushService(
    gateway: gateway,
    devices: devices,
    loggedIn: loggedIn,
    openTarget: (d) async => opened.add(d),
    onForegroundPush: () => foregroundPings++,
  );

  setUp(() {
    gateway = FakeGateway();
    devices = FakeDevices();
    loggedIn = false.obs;
    opened = [];
    foregroundPings = 0;
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('registration', () {
    test('a restored session registers on start, even if permission is refused',
        () async {
      loggedIn.value = true;
      await build().start();
      await settle();

      expect(gateway.permissionAsks, 1);
      expect(devices.registered, [('tok-1', 'ANDROID')]);
    });

    test('logging in after start registers; being logged out does not', () async {
      await build().start();
      await settle();
      expect(devices.registered, isEmpty);

      loggedIn.value = true;
      await settle();
      await settle();
      expect(devices.registered, [('tok-1', 'ANDROID')]);
    });

    test('a rotated token is re-registered only while logged in', () async {
      await build().start();
      gateway.refresh.add('tok-2');
      await settle();
      expect(devices.registered, isEmpty);

      loggedIn.value = true;
      await settle();
      await settle();
      gateway.refresh.add('tok-3');
      await settle();
      expect(devices.registered.map((r) => r.$1), ['tok-1', 'tok-3']);
    });

    test('a build without Firebase config stays inert and does not throw',
        () async {
      gateway = FakeGateway(initOk: false);
      loggedIn.value = true;
      final s = build();
      await s.start();
      await s.registerDevice();

      expect(devices.registered, isEmpty);
      expect(gateway.permissionAsks, 0);
    });

    test('no token yet registers nothing', () async {
      gateway.token = null;
      loggedIn.value = true;
      await build().start();
      await settle();
      expect(devices.registered, isEmpty);
    });
  });

  group('logout', () {
    test('removes the token it registered, then forgets it locally', () async {
      loggedIn.value = true;
      final s = build();
      await s.start();
      await settle();

      await s.unregisterDevice();

      expect(devices.removed, ['tok-1']);
      expect(gateway.deleted, 1);
    });

    test('a failing server still lets logout finish', () async {
      loggedIn.value = true;
      final s = build();
      await s.start();
      await settle();
      devices.failRemove = true;

      await s.unregisterDevice();

      expect(gateway.deleted, 1);
    });

    test('a hanging server cannot trap the user inside the app', () async {
      loggedIn.value = true;
      final s = build();
      await s.start();
      await settle();
      devices.hangRemove = true;

      // Real time: the bound is the whole point.
      final sw = Stopwatch()..start();
      await s.unregisterDevice();
      expect(sw.elapsed, lessThan(PushService.removeTimeout * 2));
      expect(gateway.deleted, 1);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('forgetDevice (expired session) drops the token without a request',
        () async {
      loggedIn.value = true;
      final s = build();
      await s.start();
      await settle();

      await s.forgetDevice();

      expect(devices.removed, isEmpty);
      expect(gateway.deleted, 1);
    });
  });

  group('taps and foreground', () {
    test('a tap before the app is ready is held, then released once', () async {
      loggedIn.value = true;
      final s = build();
      await s.start();
      gateway.opened.add(msg('booking', {'bookingId': 'b1'}));
      await settle();
      expect(opened, isEmpty);

      s.appReady();
      await settle();
      expect(opened.single['bookingId'], 'b1');

      s.appReady();
      await settle();
      expect(opened, hasLength(1));
    });

    test('a tap that launched the app is routed after appReady', () async {
      loggedIn.value = true;
      gateway.initial = msg('chat', {'conversationId': 'c1'});
      final s = build();
      await s.start();
      expect(opened, isEmpty);

      s.appReady();
      await settle();
      expect(opened.single['conversationId'], 'c1');
    });

    test('once ready, taps route immediately', () async {
      loggedIn.value = true;
      final s = build();
      await s.start();
      s.appReady();

      gateway.opened.add(msg('order', {'orderId': 'o1'}));
      await settle();
      expect(opened.single['orderId'], 'o1');
    });

    test('a tap while logged out goes nowhere', () async {
      final s = build();
      await s.start();
      s.appReady();

      gateway.opened.add(msg('booking', {'bookingId': 'b1'}));
      await settle();
      expect(opened, isEmpty);
    });

    test('an unknown type is still passed on for the fallback to handle',
        () async {
      loggedIn.value = true;
      final s = build();
      await s.start();
      s.appReady();

      gateway.opened.add(msg('brand-new-event-type'));
      await settle();
      expect(opened.single['type'], 'brand-new-event-type');
    });

    test('a routing failure is contained', () async {
      loggedIn.value = true;
      final s = PushService(
        gateway: gateway,
        devices: devices,
        loggedIn: loggedIn,
        openTarget: (_) async => throw StateError('boom'),
      );
      await s.start();
      s.appReady();

      gateway.opened.add(msg('booking'));
      await settle();
      await settle();
      // Reaching here without an uncaught async error is the assertion.
    });

    test('a foreground push is drawn and pings the unread badge', () async {
      loggedIn.value = true;
      await build().start();

      gateway.foreground.add(msg('chat'));
      await settle();

      expect(gateway.shown, hasLength(1));
      expect(foregroundPings, 1);
    });
  });
}

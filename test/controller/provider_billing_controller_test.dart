import 'dart:async';

import 'package:autonect/controller/billing/provider_billing_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/services/purchase_gateway.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_billing.dart';

/// PURCHASE = server verdict -> store sheet -> read back from the server.
/// These pin the parts that cost money when wrong: one sheet per tap, nothing
/// synced after a cancelled purchase, and "done" only on the server's word.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBillingRepository repo;
  late FakePurchaseGateway store;
  late FakeTokenStore tokens;
  late List<String> toasts;
  late List<Uri> opened;
  late ProviderBillingController c;
  late DateTime now;

  const tick = Duration(milliseconds: 1);

  ProviderBillingController build({List<Duration> schedule = const [tick, tick], bool ios = false}) => Get.put(
    ProviderBillingController(
      repo,
      store,
      tokens,
      toast: toasts.add,
      confirmSchedule: schedule,
      clock: () => now,
      isIos: () => ios,
      launch: (uri) async {
        opened.add(uri);
        return true;
      },
    ),
  );

  /// Let the fake's async answers and the 1ms poll timers run out.
  Future<void> settle([int ms = 30]) => Future<void>.delayed(Duration(milliseconds: ms));

  setUp(() {
    Get.reset();
    repo = FakeBillingRepository();
    store = FakePurchaseGateway();
    tokens = FakeTokenStore();
    toasts = [];
    opened = [];
    now = DateTime(2026, 10, 12, 12);
    c = build();
  });

  tearDown(() {
    Get.delete<ProviderBillingController>(force: true);
    Get.reset();
  });

  Future<void> loaded(BillingStatus s) async {
    repo.statusResult = Ok(s);
    await c.load();
  }

  group('load', () {
    test('publishes the server status', () async {
      await loaded(billingStatus(rank: 1, baseRank: 1, credits: 4));
      expect(c.current?.credits, 4);
      expect(c.current?.level.code, 'PAY_PER_LEAD');
    });

    test('a failed first load is Failed; a failed refresh keeps what is shown', () async {
      repo.statusQueue.add(const Err(ApiError.timeout()));
      await c.load();
      expect(c.status.value, isA<Failed<BillingStatus>>());

      await loaded(billingStatus(credits: 2));
      repo.statusQueue.add(const Err(ApiError.timeout()));
      await c.reload();
      expect(c.current?.credits, 2);
    });

    test('a status already processing polls until it settles', () async {
      repo.statusQueue.add(Ok(billingStatus(display: 'PROCESSING', pending: {'kind': 'CREDITS'})));
      repo.statusResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 5));
      await c.load();
      expect(c.current?.isProcessing, isTrue);

      await settle();
      expect(c.current?.credits, 5);
      expect(repo.countOf('status'), 2); // stopped once it settled
    });
  });

  group('buying a credit pack', () {
    setUp(() {
      repo.syncResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 5));
    });

    test('config -> store sheet -> sync; confirmed by the balance going up', () async {
      await loaded(billingStatus());
      await c.buy(kLeads5);

      expect(repo.calls, ['status', 'config', 'sync']);
      expect(store.bought, [kLeads5Product]);
      expect(store.appUserId, 'user-1', reason: 'entitlements must follow the account, not the device');
      expect(c.awaiting.value, isNull);
      expect(c.working.value, isNull);
      expect(c.changedThisVisit, isTrue);
      expect(toasts.single, 'Purchase received — 5 credits available.');
    });

    test('on iOS it asks the store for the iOS product id', () async {
      Get.delete<ProviderBillingController>(force: true);
      c = build(ios: true);
      await loaded(billingStatus());
      await c.buy(kLeads5);
      expect(store.bought, [kLeads5Product]);
    });

    test('a double tap opens ONE store sheet', () async {
      await loaded(billingStatus());
      await Future.wait([c.buy(kLeads5), c.buy(kLeads5)]);
      expect(store.bought, hasLength(1));
      expect(repo.countOf('sync'), 1);
    });

    test('config is fetched once per visit, the store configured each time', () async {
      await loaded(billingStatus());
      await c.buy(kLeads5);
      repo.syncResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 10));
      await c.buy(kLeads5);
      expect(repo.countOf('config'), 1);
      expect(store.configured, 2);
    });

    test('cancelled in the store: nothing synced, not charged, controls released', () async {
      store.outcome = const PurchaseCancelled();
      await loaded(billingStatus());
      await c.buy(kLeads5);

      expect(repo.countOf('sync'), 0);
      expect(c.awaiting.value, isNull);
      expect(c.working.value, isNull);
      expect(c.changedThisVisit, isFalse);
      expect(toasts.single, 'Purchase cancelled — you have not been charged.');
    });

    test("the store's own failure message is shown, and nothing synced", () async {
      store.outcome = const PurchaseFailed('Your payment method was declined.');
      await loaded(billingStatus());
      await c.buy(kLeads5);

      expect(repo.countOf('sync'), 0);
      expect(toasts.single, 'Your payment method was declined.');
    });

    test('a product missing from the store listing says so', () async {
      store.outcome = const PurchaseUnavailable();
      await loaded(billingStatus());
      await c.buy(kLeads5);

      expect(repo.countOf('sync'), 0);
      expect(toasts.single, "That plan isn't available in your store account yet.");
    });

    test('a plan with no store product is refused before the store is opened', () async {
      await loaded(
        billingStatus(
          plans: [
            {...planJson(kLeads5, name: '5 Lead Credits', pricePence: 5500, productId: '', credits: 5), 'androidProductId': null, 'iosProductId': null},
          ],
        ),
      );
      await c.buy(kLeads5);

      expect(store.bought, isEmpty);
      expect(toasts.single, "That plan isn't on sale in your store yet.");
    });

    test('unsupported platform: refused with an explanation, no network', () async {
      store.isSupported = false;
      await loaded(billingStatus());
      await c.buy(kLeads5);

      expect(repo.calls, ['status']);
      expect(toasts.single, kPurchasesUnsupportedCopy);
    });

    test('an offer the server refused is not bought; its reason is shown', () async {
      await loaded(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));
      await c.buy(kLeads5);

      expect(store.bought, isEmpty);
      expect(toasts.single, 'Your plan already includes unlimited leads.');
    });

    test('an unknown plan is refused', () async {
      await loaded(billingStatus());
      await c.buy('not-a-plan');
      expect(repo.countOf('config'), 0);
      expect(toasts.single, "That plan isn't available right now.");
    });

    test('503 on config: surfaced, the store is never opened', () async {
      repo.configResult = const Err(
        ApiError(code: ApiErrorCode.internal, message: 'Purchases are not available right now.', statusCode: 503),
      );
      await loaded(billingStatus());
      await c.buy(kLeads5);

      expect(store.bought, isEmpty);
      expect(toasts.single, 'Purchases are not available right now.');
      expect(c.working.value, isNull);
    });

    test('the store SDK could not be configured: surfaced, nothing bought', () async {
      store.configureOk = false;
      await loaded(billingStatus());
      await c.buy(kLeads5);

      expect(store.bought, isEmpty);
      expect(toasts.single, 'Purchases could not start on this device. Please try again.');
    });

    test('signed out mid-flow: asks them to sign in rather than buying anonymously', () async {
      tokens.userId = null;
      await loaded(billingStatus());
      await c.buy(kLeads5);

      expect(store.bought, isEmpty);
      expect(toasts.single, 'Please sign in again to make a purchase.');
    });

    test('slow confirmation: keeps polling, then says so; confirms when it lands', () async {
      repo.syncResult = Ok(billingStatus()); // webhook not in yet
      repo.statusResult = Ok(billingStatus());
      await loaded(billingStatus());
      await c.buy(kLeads5);
      expect(c.awaiting.value, isNotNull);

      await settle();
      expect(repo.countOf('status'), 3); // load + two polls
      expect(toasts.last, kProcessingSlowCopy);
      expect(c.awaiting.value, isNotNull, reason: 'still processing — not declared failed');

      repo.statusResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 5));
      await c.reload();
      expect(c.awaiting.value, isNull);
      expect(toasts.last, 'Purchase received — 5 credits available.');
    });

    test('an unconfirmed purchase stops waiting after its max age', () async {
      repo.syncResult = Ok(billingStatus());
      repo.statusResult = Ok(billingStatus());
      await loaded(billingStatus());
      await c.buy(kLeads5);
      await settle();

      now = now.add(const Duration(minutes: 11));
      await c.reload();
      expect(c.awaiting.value, isNull);
    });
  });

  group('subscribing', () {
    test('confirmed only when the server shows THAT plan active', () async {
      repo.syncResult = Ok(billingStatus(display: 'PROCESSING', pending: {'kind': 'SUBSCRIPTION'}));
      await loaded(billingStatus());
      repo.statusResult = Ok(billingStatus(rank: 2, display: 'ACTIVE_RENEWING')); // the webhook lands

      await c.buy(kElectricianPro);
      expect(store.bought, [kProProduct]);
      expect(c.awaiting.value, isNotNull);

      await settle();
      expect(c.awaiting.value, isNull);
      expect(c.current?.isSubscribed, isTrue);
      expect(toasts.last, 'Electrician Pro (Monthly) is active. Thank you!');
    });
  });

  group('restore purchases', () {
    test('restores, syncs, and reports what came back', () async {
      repo.syncResult = Ok(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));
      await loaded(billingStatus());

      await c.restorePurchases();

      expect(store.restores, 1);
      expect(repo.countOf('sync'), 1);
      expect(c.current?.isSubscribed, isTrue);
      expect(toasts.last, 'Your purchases have been restored.');
    });

    test('nothing to restore says so instead of spinning', () async {
      repo.syncResult = Ok(billingStatus());
      repo.statusResult = Ok(billingStatus());
      await loaded(billingStatus());

      await c.restorePurchases();

      expect(c.awaiting.value, isNull);
      expect(toasts.last, 'Nothing to restore on this store account.');
    });

    test('a store failure is surfaced', () async {
      store.restoreOutcome = const PurchaseFailed('Store unavailable.');
      await loaded(billingStatus());
      await c.restorePurchases();
      expect(repo.countOf('sync'), 0);
      expect(toasts.single, 'Store unavailable.');
    });
  });

  group('managing the subscription', () {
    test('opens the store page the server gave us', () async {
      await loaded(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));
      await c.openStoreManagement();

      expect(opened.single.toString(), kManageUrl);
      expect(toasts, isEmpty);
    });

    test('with no subscription, explains rather than opening nothing', () async {
      await loaded(billingStatus());
      await c.openStoreManagement();

      expect(opened, isEmpty);
      expect(toasts.single, kStoreManagedCopy);
    });

    test('a store that will not open is reported', () async {
      Get.delete<ProviderBillingController>(force: true);
      c = Get.put(
        ProviderBillingController(repo, store, tokens,
            toast: toasts.add, confirmSchedule: const [], clock: () => now, isIos: () => false, launch: (_) async => false),
      );
      await loaded(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));
      await c.openStoreManagement();

      expect(toasts.single, 'Could not open the store. Open it and look under Subscriptions.');
    });
  });

  group('app lifecycle', () {
    test('returning while the store sheet is open does not re-read', () async {
      repo.syncResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 5));
      await loaded(billingStatus());
      now = now.add(const Duration(minutes: 1));
      store.hold = Completer<PurchaseOutcome>();

      final buying = c.buy(kLeads5);
      await settle(5);
      expect(store.bought, hasLength(1));

      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(5);
      expect(repo.countOf('status'), 1);

      store.hold!.complete(const PurchaseCancelled());
      await buying;
    });

    test('coming back from the store re-reads, but not twice in five seconds', () async {
      await loaded(billingStatus());
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(5);
      expect(repo.countOf('status'), 1);

      now = now.add(const Duration(seconds: 6));
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(5);
      expect(repo.countOf('status'), 2);
    });

    test('closing the screen stops polling', () async {
      repo.syncResult = Ok(billingStatus());
      repo.statusResult = Ok(billingStatus());
      Get.delete<ProviderBillingController>(force: true);
      c = build(schedule: const [Duration(milliseconds: 20)]);
      await loaded(billingStatus());
      await c.buy(kLeads5);

      Get.delete<ProviderBillingController>(force: true);
      await settle(50);
      expect(repo.countOf('status'), 1);
    });
  });
}

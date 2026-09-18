import 'dart:async';

import 'package:autonect/controller/billing/provider_billing_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/services/payment_sheet_gateway.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_billing.dart';

/// PURCHASE = server verdict → payment sheet → read back from the server.
/// These pin the parts that cost money when wrong: one PaymentIntent per tap,
/// nothing synced after a cancelled sheet, and "done" only on the server's word.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBillingRepository repo;
  late FakePaymentSheetGateway sheet;
  late List<String> toasts;
  late ProviderBillingController c;
  late DateTime now;

  const tick = Duration(milliseconds: 1);

  ProviderBillingController build({List<Duration> schedule = const [tick, tick]}) => Get.put(
    ProviderBillingController(repo, sheet, toast: toasts.add, confirmSchedule: schedule, clock: () => now),
  );

  /// Let the fake's async answers and the 1ms poll timers run out.
  Future<void> settle([int ms = 30]) => Future<void>.delayed(Duration(milliseconds: ms));

  setUp(() {
    Get.reset();
    repo = FakeBillingRepository();
    sheet = FakePaymentSheetGateway();
    toasts = [];
    now = DateTime(2026, 9, 18, 12);
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

    test('a status already processing starts polling until it settles', () async {
      repo.statusQueue.add(Ok(billingStatus(display: 'PROCESSING', pending: {'kind': 'CREDITS'})));
      repo.statusResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 5));
      await c.load();
      expect(c.current?.isProcessing, isTrue);

      await settle();
      expect(c.current?.credits, 5);
      expect(repo.countOf('status'), 2); // stopped once it settled
    });
  });

  group('buy credits', () {
    setUp(() {
      repo.creditsIntentResult = Ok(sheetSession());
      repo.syncResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 5));
    });

    test('config → intent → sheet → sync; confirmed by the balance going up', () async {
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);

      expect(repo.calls, ['status', 'config', 'createCreditsIntent', 'sync']);
      expect(repo.lastLookupKey, kLeads5);
      expect(sheet.presented.single.planLookupKey, kLeads5);
      expect(repo.lastSync?.paymentIntentId, 'pi_1');
      expect(repo.lastSync?.subscriptionId, isNull);
      expect(c.awaiting.value, isNull);
      expect(c.working.value, isNull);
      expect(c.changedThisVisit, isTrue);
      expect(toasts.single, 'Payment received — 5 credits available.');
    });

    test('a double tap creates ONE PaymentIntent', () async {
      await loaded(billingStatus());
      final first = c.buyCredits(kLeads5);
      final second = c.buyCredits(kLeads5);
      await Future.wait([first, second]);
      expect(repo.countOf('createCreditsIntent'), 1);
      expect(sheet.presented, hasLength(1));
    });

    test('config is fetched once per visit', () async {
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);
      repo.syncResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 10));
      await c.buyCredits(kLeads5);
      expect(repo.countOf('config'), 1);
      expect(sheet.configured, 2);
    });

    test('sheet cancelled: nothing synced, not charged, controls released', () async {
      sheet.outcome = const PaymentCancelled();
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);

      expect(repo.countOf('sync'), 0);
      expect(c.awaiting.value, isNull);
      expect(c.working.value, isNull);
      expect(c.changedThisVisit, isFalse);
      expect(toasts.single, 'Payment cancelled — you have not been charged.');
    });

    test("sheet failed: Stripe's own message, nothing synced", () async {
      sheet.outcome = const PaymentFailed('Your card was declined.');
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);

      expect(repo.countOf('sync'), 0);
      expect(toasts.single, 'Your card was declined.');
    });

    test('unsupported platform: refused with an explanation, no network', () async {
      sheet.isSupported = false;
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);

      expect(repo.calls, ['status']);
      expect(toasts.single, kPaymentsUnsupportedCopy);
    });

    test("an offer the server refused is not bought; its reason is shown", () async {
      await loaded(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));
      await c.buyCredits(kLeads5);

      expect(repo.countOf('createCreditsIntent'), 0);
      expect(toasts.single, 'Your plan already includes unlimited leads.');
    });

    test('an unknown plan is refused', () async {
      await loaded(billingStatus());
      await c.buyCredits('not-a-plan');
      expect(repo.countOf('config'), 0);
      expect(toasts.single, "That plan isn't available right now.");
    });

    test('503 on config: surfaced, nothing created', () async {
      repo.configResult = const Err(
        ApiError(code: ApiErrorCode.internal, message: 'Payments are not available right now.', statusCode: 503),
      );
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);

      expect(repo.countOf('createCreditsIntent'), 0);
      expect(toasts.single, 'Payments are not available right now.');
      expect(c.working.value, isNull);
    });

    test('the sheet could not be configured: surfaced, nothing created', () async {
      sheet.configureOk = false;
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);

      expect(repo.countOf('createCreditsIntent'), 0);
      expect(toasts.single, 'Payments could not start on this device. Please try again.');
    });

    test('409 on create: the screen was stale, so it re-reads', () async {
      repo.creditsIntentResult = const Err(
        ApiError(code: ApiErrorCode.conflict, message: 'You already have unlimited leads.', statusCode: 409),
      );
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);

      expect(sheet.presented, isEmpty);
      expect(repo.countOf('status'), 2);
      expect(toasts.single, 'You already have unlimited leads.');
    });

    test('slow confirmation: keeps polling, then says so; confirms when it lands', () async {
      repo.syncResult = Ok(billingStatus()); // webhook not in yet
      repo.statusResult = Ok(billingStatus());
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);
      expect(c.awaiting.value, isNotNull);

      await settle();
      expect(repo.countOf('status'), 3); // load + two polls
      expect(toasts.last, kProcessingSlowCopy);
      expect(c.awaiting.value, isNotNull, reason: 'still Processing — not declared failed');

      repo.statusResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 5));
      await c.reload();
      expect(c.awaiting.value, isNull);
      expect(toasts.last, 'Payment received — 5 credits available.');
    });

    test('an unconfirmed payment stops waiting after its max age', () async {
      repo.syncResult = Ok(billingStatus());
      repo.statusResult = Ok(billingStatus());
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);
      await settle();

      now = now.add(const Duration(minutes: 11));
      await c.reload();
      expect(c.awaiting.value, isNull);
    });
  });

  group('subscribe', () {
    test('confirmed only when the server shows THAT plan active', () async {
      repo.subscriptionResult = Ok(
        sheetSession(subscription: true, lookupKey: kElectricianPro, planName: 'Electrician Pro (Monthly)'),
      );
      repo.syncResult = Ok(billingStatus(display: 'PROCESSING', pending: {'kind': 'SUBSCRIPTION'}));
      await loaded(billingStatus());
      repo.statusResult = Ok(billingStatus(rank: 2, display: 'ACTIVE_RENEWING')); // the webhook lands

      await c.subscribe(kElectricianPro);
      expect(repo.lastSync?.subscriptionId, 'sub_1');
      expect(repo.lastSync?.paymentIntentId, isNull);
      expect(c.awaiting.value, isNotNull);

      await settle();
      expect(c.awaiting.value, isNull);
      expect(c.current?.isSubscribed, isTrue);
      expect(toasts.last, 'Electrician Pro (Monthly) is active. Thank you!');
    });

    test('nothing owed now (upgrade on the card on file): no sheet, still synced', () async {
      repo.subscriptionResult = Ok(sheetSession(subscription: true, requiresPayment: false, lookupKey: kElectricianPro));
      repo.syncResult = Ok(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));
      await loaded(billingStatus(rank: 1, baseRank: 1, credits: 3));

      await c.subscribe(kElectricianPro);
      expect(sheet.presented, isEmpty);
      expect(repo.countOf('sync'), 1);
      expect(c.current?.isSubscribed, isTrue);
    });
  });

  group('retry payment', () {
    test('past due → paid in the sheet → back in good standing', () async {
      repo.retryResult = Ok(sheetSession(subscription: true, lookupKey: kElectricianPro));
      repo.syncResult = Ok(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));
      await loaded(billingStatus(rank: 2, display: 'PAST_DUE'));

      await c.retryPayment();
      expect(repo.countOf('retryPayment'), 1);
      expect(sheet.presented, hasLength(1));
      expect(toasts.last, 'Payment received — your plan is back in good standing.');
    });
  });

  group('cancel / resume', () {
    test('cancel publishes the server answer and names the end date', () async {
      await loaded(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));
      repo.cancelResult = Ok(billingStatus(rank: 2, display: 'ACTIVE_CANCELLING'));

      await c.cancelSubscription();
      expect(c.current?.displayState, BillingDisplayState.activeCancelling);
      expect(c.current?.isSubscribed, isTrue, reason: 'access continues to the period end');
      expect(c.changedThisVisit, isTrue);
      expect(toasts.single, 'Cancelled — you keep your plan until 18 October 2026.');
    });

    test('a failed cancel changes nothing on screen', () async {
      await loaded(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));
      repo.cancelResult = const Err(ApiError.network());

      await c.cancelSubscription();
      expect(c.current?.displayState, BillingDisplayState.activeRenewing);
      expect(c.changedThisVisit, isFalse);
      expect(c.working.value, isNull);
      expect(toasts.single, contains('No internet connection'));
    });

    test('resume returns to renewing', () async {
      await loaded(billingStatus(rank: 2, display: 'ACTIVE_CANCELLING'));
      repo.resumeResult = Ok(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));

      await c.resumeSubscription();
      expect(c.current?.displayState, BillingDisplayState.activeRenewing);
      expect(toasts.single, 'Your plan is active again and renews on 18 October 2026.');
    });

    test('a second tap while one is in flight is dropped', () async {
      await loaded(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));
      repo.cancelResult = Ok(billingStatus(rank: 2, display: 'ACTIVE_CANCELLING'));
      await Future.wait([c.cancelSubscription(), c.cancelSubscription()]);
      expect(repo.countOf('cancel'), 1);
    });
  });

  group('app lifecycle', () {
    test('returning while the sheet is open does not re-read', () async {
      repo.creditsIntentResult = Ok(sheetSession());
      repo.syncResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 5));
      await loaded(billingStatus());
      now = now.add(const Duration(minutes: 1));
      sheet.hold = Completer<PaymentSheetOutcome>();

      final buying = c.buyCredits(kLeads5);
      await settle(5);
      expect(sheet.presented, hasLength(1));

      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(5);
      expect(repo.countOf('status'), 1);

      sheet.hold!.complete(const PaymentCancelled());
      await buying;
    });

    test('returning to the app re-reads, but not twice in five seconds', () async {
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
      repo.creditsIntentResult = Ok(sheetSession());
      Get.delete<ProviderBillingController>(force: true);
      c = build(schedule: const [Duration(milliseconds: 20)]);
      await loaded(billingStatus());
      await c.buyCredits(kLeads5);

      Get.delete<ProviderBillingController>(force: true);
      await settle(50);
      expect(repo.countOf('status'), 1);
    });
  });
}

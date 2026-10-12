import 'package:autonect/controller/billing/provider_billing_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/domain/plan_cards.dart';
import 'package:autonect/services/purchase_gateway.dart';
import 'package:autonect/view/screens/electrician/profile/electrician_access_tier_page.dart';
import 'package:autonect/view/screens/supplier/widgets/access_tier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_billing.dart';

/// The electrician's Access Tier screen, the credit packs sheet, and the
/// registration wizard's plan cards — each rendered from server data, each
/// button reaching the store (or, at registration, only the form).
void main() {
  late FakeBillingRepository repo;
  late FakePurchaseGateway store;
  late List<String> toasts;
  late List<Uri> opened;

  setUp(() {
    Get.reset();
    repo = FakeBillingRepository();
    store = FakePurchaseGateway();
    toasts = [];
    opened = [];
    Get.put<BillingRepository>(repo);
    Get.put<PurchaseGateway>(store);
    Get.put(
      ProviderBillingController(
        repo,
        store,
        FakeTokenStore(),
        toast: toasts.add,
        confirmSchedule: const [],
        isIos: () => false,
        launch: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    );
  });

  tearDown(Get.reset);

  Future<void> mount(WidgetTester tester, BillingStatus s) async {
    repo.statusResult = Ok(s);
    await tester.pumpWidget(const GetMaterialApp(home: ElectricianAccessTierPage()));
    await tester.pumpAndSettle();
  }

  Future<void> tapOn(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) => tapOn(tester, find.text(text));

  Finder inDialog(String text) => find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

  group('Access Tier page', () {
    testWidgets('free: server prices, both upgrades offered', (tester) async {
      await mount(tester, billingStatus());

      expect(find.text('Current Active Tier'), findsOneWidget);
      expect(find.text('Choose Pay-Per-Lead or Pro to accept client leads.'), findsOneWidget);
      expect(find.text('£149'), findsOneWidget);
      expect(find.text('£12'), findsOneWidget);
      expect(find.text('Upgrade to Pro'), findsOneWidget);
      expect(find.text('Choose Credits'), findsOneWidget);
      expect(find.text('Restore purchases'), findsOneWidget);
      expect(find.textContaining(r'$'), findsNothing, reason: 'GBP only');
    });

    testWidgets('pay-per-lead: balance, Buy Credits, no way back to Free', (tester) async {
      await mount(tester, billingStatus(rank: 1, baseRank: 1, credits: 2));

      expect(find.text('Available Lead Credits'), findsOneWidget);
      expect(find.text('2 credits'), findsOneWidget);
      expect(find.text('Buy Credits'), findsOneWidget);
      expect(find.text('Top-Up Credits'), findsOneWidget);
      expect(find.text('Included'), findsOneWidget);
    });

    testWidgets('choose credits → packs sheet → store → balance confirmed', (tester) async {
      await mount(tester, billingStatus());
      repo.syncResult = Ok(billingStatus(rank: 1, baseRank: 1, credits: 5));

      await tap(tester, 'Choose Credits');
      expect(find.text('Purchase Lead Credits'), findsOneWidget);
      expect(find.text('1 Lead Credit'), findsOneWidget);
      expect(find.text('5 Lead Credits'), findsOneWidget);
      expect(find.text('Save £5'), findsOneWidget);

      await tap(tester, '5 Lead Credits');
      expect(find.text('Purchase Lead Credits'), findsNothing);
      expect(store.bought, [kLeads5Product]);
      expect(find.text('5 credits'), findsOneWidget);
      expect(toasts.last, 'Purchase received — 5 credits available.');
    });

    testWidgets('upgrade: confirm, buy in the store, then Pro is shown active', (tester) async {
      await mount(tester, billingStatus(rank: 1, baseRank: 1, credits: 2));
      repo.syncResult = Ok(billingStatus(rank: 2, baseRank: 1, credits: 2, display: 'ACTIVE_RENEWING'));

      await tap(tester, 'Upgrade to Pro');
      expect(find.text('£149 / month'), findsOneWidget);
      expect(find.textContaining('Billed by the app store'), findsOneWidget);
      await tapOn(tester, inDialog('Continue'));

      expect(store.bought, [kProProduct]);
      expect(find.text('Manage in Store'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
    });

    testWidgets('dismissing the upgrade dialog buys nothing', (tester) async {
      await mount(tester, billingStatus());
      await tap(tester, 'Upgrade to Pro');
      await tap(tester, 'Not now');
      expect(store.bought, isEmpty);
    });

    testWidgets('pro: manage explains the store owns it, then opens the store', (tester) async {
      await mount(tester, billingStatus(rank: 2, baseRank: 1, display: 'ACTIVE_RENEWING'));

      expect(find.textContaining('Renews on 18 November 2026'), findsOneWidget);
      expect(find.text('Included in Pro'), findsOneWidget);

      await tap(tester, 'Manage in Store');
      expect(find.textContaining('Cancelling happens in the store that charges you'), findsOneWidget);
      expect(find.textContaining('your plan becomes Pay-Per-Lead'), findsOneWidget);
      await tapOn(tester, inDialog('Open Store'));

      expect(opened.single.toString(), kManageUrl);
    });

    testWidgets('cancelling: resume points at the store too', (tester) async {
      await mount(tester, billingStatus(rank: 2, display: 'ACTIVE_CANCELLING'));

      expect(find.textContaining('Ends on 18 November 2026'), findsOneWidget);
      await tap(tester, 'Resume in Store');
      expect(find.textContaining('Resubscribe in the store'), findsOneWidget);
      await tapOn(tester, inDialog('Open Store'));
      expect(opened, hasLength(1));
    });

    testWidgets('past due: fixing the card happens in the store', (tester) async {
      await mount(tester, billingStatus(rank: 2, display: 'PAST_DUE'));

      expect(find.text('PAYMENT FAILED'), findsOneWidget);
      await tapOn(tester, find.text('Fix Payment in Store').first);
      expect(find.textContaining('Update your payment method in the store'), findsWidgets);
      await tapOn(tester, inDialog('Open Store'));
      expect(opened, hasLength(1));
    });

    testWidgets('a cancelled store sheet leaves the plan as it was', (tester) async {
      await mount(tester, billingStatus());
      store.outcome = const PurchaseCancelled();

      await tap(tester, 'Upgrade to Pro');
      await tapOn(tester, inDialog('Continue'));

      expect(repo.countOf('sync'), 0);
      expect(find.text('Upgrade to Pro'), findsOneWidget);
      expect(toasts.last, 'Purchase cancelled — you have not been charged.');
    });

    testWidgets('restore purchases brings back a subscription', (tester) async {
      await mount(tester, billingStatus());
      repo.syncResult = Ok(billingStatus(rank: 2, display: 'ACTIVE_RENEWING'));

      await tap(tester, 'Restore purchases');

      expect(store.restores, 1);
      expect(find.text('Manage in Store'), findsOneWidget);
      expect(toasts.last, 'Your purchases have been restored.');
    });
  });

  group('registration plan cards', () {
    const plans = [
      BillingPlan(id: '1', lookupKey: kElectricianPro, name: 'Pro', pricePence: 14900, interval: PlanInterval.month),
      BillingPlan(id: '2', lookupKey: kLead1, name: '1', pricePence: 1200, interval: PlanInterval.oneTime, credits: 1),
    ];

    Future<List<TierAction>> pumpCards(WidgetTester tester) async {
      final actions = <TierAction>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AccessTier(cards: registrationTierCards(plans, selectedTier: 'FREE'), onAction: actions.add),
            ),
          ),
        ),
      );
      return actions;
    }

    testWidgets('Pro is priced but cannot be chosen before approval', (tester) async {
      final actions = await pumpCards(tester);
      expect(find.text('£149'), findsOneWidget);
      await tap(tester, 'Available after approval');
      expect(actions, isEmpty);
    });

    testWidgets('Free and Pay-Per-Lead can be chosen', (tester) async {
      final actions = await pumpCards(tester);
      await tap(tester, 'Choose Pay-Per-Lead');
      await tap(tester, 'Continue with Free');
      expect(actions, [TierAction.choosePayPerLead, TierAction.chooseFree]);
    });
  });
}

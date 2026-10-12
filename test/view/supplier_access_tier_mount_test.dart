import 'package:autonect/controller/billing/provider_billing_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/services/purchase_gateway.dart';
import 'package:autonect/view/screens/supplier/profile/supplier_access_tier_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_billing.dart';

/// The supplier's Plans & Billing renders what `GET /v1/billing/status` says
/// — level, dates, what may be bought — and every button reaches the store
/// through the controller.
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
    // Pre-registered so ensure() finds it: toasts recorded, no poll timers.
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
    await tester.pumpWidget(const GetMaterialApp(home: SupplierAccessTierPage()));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('standard supplier: server prices, upgrade and pack offered', (tester) async {
    await mount(tester, billingStatus(supplier: true, credits: 25));

    expect(find.text('Plans & Billing'), findsOneWidget);
    expect(find.text('CURRENT ACTIVE PLAN'), findsOneWidget);
    expect(find.text('STANDARD'), findsOneWidget);
    expect(find.text('25 credits available'), findsOneWidget);
    expect(find.text('Supplier Unlimited'), findsOneWidget);
    expect(find.text('£299'), findsOneWidget);
    expect(find.text('Upgrade to Pro (£299/mo)'), findsOneWidget);
    expect(find.text('10 Credits Pack'), findsOneWidget);
    expect(find.text('Buy 10 Credits Pack (£10)'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(find.text('YOUR CURRENT PLAN'), findsNothing);
  });

  testWidgets('pay-per-lead supplier: credits card is the current plan', (tester) async {
    await mount(tester, billingStatus(supplier: true, rank: 1, baseRank: 1, credits: 7));

    expect(find.text('Pay-Per-Lead'), findsOneWidget);
    expect(find.text('7 credits available'), findsOneWidget);
    expect(find.text('YOUR CURRENT PLAN'), findsOneWidget);
    expect(find.text('Upgrade to Pro (£299/mo)'), findsOneWidget);
  });

  testWidgets('subscribed: renewal date, manage in store, packs included', (tester) async {
    await mount(tester, billingStatus(supplier: true, rank: 2, display: 'ACTIVE_RENEWING'));

    expect(find.text('Pro Unlimited'), findsOneWidget);
    expect(find.text('ACTIVE PRO'), findsOneWidget);
    expect(find.text('YOUR CURRENT PLAN'), findsOneWidget);
    expect(find.textContaining('Renews on 18 November 2026'), findsNWidgets(2));
    expect(find.text('Manage in Store'), findsOneWidget);
    expect(find.text('Included in Pro'), findsOneWidget);
    expect(find.textContaining('Upgrade to Pro'), findsNothing);
  });

  testWidgets('manage: the dialog is honest about who cancels, then opens the store', (tester) async {
    await mount(tester, billingStatus(supplier: true, rank: 2, display: 'ACTIVE_RENEWING'));

    await tap(tester, 'Manage in Store');
    expect(find.text('Manage Subscription'), findsOneWidget);
    expect(find.textContaining('until 18 November 2026'), findsOneWidget);
    expect(find.textContaining('your plan becomes Standard'), findsOneWidget);

    await tap(tester, 'Open Store');
    expect(opened.single.toString(), kManageUrl);
  });

  testWidgets('dismissing the manage dialog opens nothing', (tester) async {
    await mount(tester, billingStatus(supplier: true, rank: 2, display: 'ACTIVE_RENEWING'));

    await tap(tester, 'Manage in Store');
    await tap(tester, 'Not now');
    expect(opened, isEmpty);
    expect(find.text('ACTIVE PRO'), findsOneWidget);
  });

  testWidgets('cancelling: the card offers to resume in the store', (tester) async {
    await mount(tester, billingStatus(supplier: true, rank: 2, display: 'ACTIVE_CANCELLING'));

    expect(find.text('CANCELLING'), findsOneWidget);
    expect(find.textContaining('Ends on 18 November 2026'), findsNWidgets(2));
    await tap(tester, 'Resume in Store');
    expect(find.textContaining('Resubscribe in the store'), findsOneWidget);
  });

  testWidgets('past due: payment failed banner and a route to fix it', (tester) async {
    await mount(tester, billingStatus(supplier: true, rank: 2, display: 'PAST_DUE'));

    expect(find.text('PAYMENT FAILED'), findsOneWidget);
    expect(find.text('Fix Payment in Store'), findsOneWidget);
    expect(find.text('Your last payment failed.'), findsOneWidget);
  });

  testWidgets('upgrade: confirm, buy in the store, confirmed by the server', (tester) async {
    await mount(tester, billingStatus(supplier: true, credits: 3));
    repo.syncResult = Ok(billingStatus(supplier: true, rank: 2, credits: 3, display: 'ACTIVE_RENEWING'));

    await tap(tester, 'Upgrade to Pro (£299/mo)');
    expect(find.text('£299 / month'), findsOneWidget);
    await tap(tester, 'Continue');

    expect(store.bought, [kSupplierProProduct]);
    expect(find.text('ACTIVE PRO'), findsOneWidget);
    expect(toasts.last, 'Supplier Unlimited (Monthly) is active. Thank you!');
  });

  testWidgets('a failed first load offers retry, which recovers', (tester) async {
    repo.statusQueue.add(const Err(ApiError.network()));
    await mount(tester, billingStatus(supplier: true, credits: 25));

    expect(find.text('Try again'), findsOneWidget);
    await tap(tester, 'Try again');
    expect(find.text('CURRENT ACTIVE PLAN'), findsOneWidget);
  });
}

import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:autonect/view/screens/supplier/profile/supplier_access_tier_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeBillingRepo implements BillingRepository {
  bool subscribeCalled = false;
  bool purchaseCreditsCalled = false;
  bool cancelCalled = false;

  final List<BillingPlan> returnPlans = const [
    BillingPlan(
      id: 'plan-1',
      lookupKey: 'supplier-monthly',
      name: 'Supplier Unlimited (Monthly)',
      pricePence: 29900,
      interval: PlanInterval.month,
      credits: null,
    ),
    BillingPlan(
      id: 'plan-2',
      lookupKey: 'credits-10',
      name: '10 Credit Pack',
      pricePence: 1000,
      interval: PlanInterval.oneTime,
      credits: 10,
    ),
  ];

  @override
  Future<ApiResult<List<BillingPlan>>> plans() async => Ok(returnPlans);

  @override
  Future<ApiResult<Map<String, dynamic>>> subscribe(String lookupKey) async {
    subscribeCalled = true;
    return const Ok({'url': 'https://checkout.stripe.com/test-sub'});
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> purchaseCredits(String lookupKey) async {
    purchaseCreditsCalled = true;
    return const Ok({'url': 'https://checkout.stripe.com/test-credits'});
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> cancelSubscription() async {
    cancelCalled = true;
    return const Ok({'status': 'canceled'});
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> wallet() async => const Ok({
        'credits': 25,
        'hasActiveSubscription': false,
        'subscription': null,
        'ledger': [],
      });
}

class _StubSupplierRepo implements SupplierRepository {
  final bool isSubscribed;
  _StubSupplierRepo({this.isSubscribed = false});

  @override
  Future<ApiResult<SupplierDashboardData>> dashboard() async => Ok(
        SupplierDashboardData(
          incomingRequests: 3,
          activeNegotiations: 1,
          creditBalance: 25,
          subscribed: isSubscribed,
          todaysEarningsPence: 0,
        ),
      );

  @override
  Future<ApiResult<Paged<SupplierLead>>> feed({
    int page = 1,
    int limit = 20,
    String? partName,
    Region? region,
    String? make,
    String? model,
    int? minOffers,
    int? maxOffers,
    String? sort,
  }) async =>
      const Ok(
        Paged(
          [],
          PageMeta(
            page: 1,
            limit: 20,
            pageSize: 0,
            total: 0,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        ),
      );

  @override
  Future<ApiResult<SupplierLeadDetail>> leadDetail(String id) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<Paged<SupplierOffer>>> listOffers({
    int page = 1,
    int limit = 20,
    OfferStatus? status,
  }) async =>
      const Ok(
        Paged(
          [],
          PageMeta(
            page: 1,
            limit: 20,
            pageSize: 0,
            total: 0,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubProfileRepo implements ProfileRepository {
  @override
  Future<ApiResult<MeProfile>> me() async => Ok(
        MeProfile(
          id: 'supplier-user-1',
          email: 'seller@test.com',
          name: 'Apex Auto Spares',
          role: 'SUPPLIER',
          supplierProfile: const SupplierProfile(
            businessName: 'Apex Auto Spares Ltd',
            approved: true,
            kycStatus: KycStatus.approved,
            ratingAvg: 4.9,
            ratingCount: 14,
            address: 'London, UK',
            categories: const [],
            regionsServed: const [Region.london],
            brands: const ['BMW', 'Audi'],
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubOrdersRepo implements OrdersRepository {
  @override
  Future<ApiResult<Paged<Order>>> list({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async =>
      const Ok(
        Paged(
          [],
          PageMeta(
            page: 1,
            limit: 20,
            pageSize: 0,
            total: 0,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeBillingRepo fakeBilling;
  late _StubSupplierRepo stubSupplier;
  late _StubProfileRepo stubProfile;

  setUp(() {
    Get.reset();
    fakeBilling = _FakeBillingRepo();
    stubSupplier = _StubSupplierRepo();
    stubProfile = _StubProfileRepo();

    Get.put<BillingRepository>(fakeBilling);
    Get.put<SupplierRepository>(stubSupplier);
    Get.put<ProfileRepository>(stubProfile);
    Get.put<OrdersRepository>(_StubOrdersRepo());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('SupplierAccessTierPage mounts and displays plans correctly',
      (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierAccessTierPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verifies app bar and status banner
    expect(find.text('Plans & Billing'), findsOneWidget);
    expect(find.text('CURRENT ACTIVE PLAN'), findsOneWidget);
    expect(find.text('Pay-Per-Lead'), findsOneWidget);
    expect(find.text('25 credits available in your wallet'), findsOneWidget);

    // Verifies Pro plan card
    expect(find.text('Supplier Unlimited'), findsOneWidget);
    expect(find.text('£299'), findsOneWidget);
    expect(find.text('Upgrade to Pro (£299/mo)'), findsOneWidget);

    // Verifies Credit pack card
    expect(find.text('10 Credits Pack'), findsOneWidget);
    expect(find.text('£10.00'), findsOneWidget);
    expect(find.text('Buy 10 Credits Pack (£10.00)'), findsOneWidget);
  });

  testWidgets('SupplierAccessTierPage displays active status when subscribed',
      (tester) async {
    Get.delete<SupplierHomeController>();
    Get.delete<SupplierRepository>();
    stubSupplier = _StubSupplierRepo(isSubscribed: true);
    Get.put<SupplierRepository>(stubSupplier);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierAccessTierPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pro Unlimited'), findsOneWidget);
    expect(find.text('ACTIVE PRO'), findsOneWidget);
    expect(find.text('YOUR CURRENT PLAN'), findsOneWidget);
    expect(find.text('Manage / Cancel Subscription'), findsOneWidget);
  });
}

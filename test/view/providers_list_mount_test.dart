import 'package:autonect/controller/buyer/providers_list_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/providers_repository.dart';
import 'package:autonect/controller/buyer/provider_detail_controller.dart';
import 'package:autonect/view/screens/buyer/providers/provider_detail.dart';
import 'package:autonect/view/screens/buyer/providers/providers_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// MOUNTING THE REAL SCREENS.
///
/// The directory's controller was covered and its screen was not, which is
/// exactly how a build-time throw shipped: `_serviceChips` wrapped a ListView
/// in an Obx but read `c.service.value` down inside itemBuilder, where the
/// tracking zone no longer exists. GetX saw an Obx with no subscriptions and
/// threw, and a release build paints that as a grey rectangle — no crash, no
/// log, just a blank screen.
///
/// A controller test cannot catch it, because nothing is ever built. These
/// pump the widget, which is the only thing that can.
void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  testWidgets('ProvidersListPage builds without throwing', (tester) async {
    final repo = FakeProvidersRepository()
      ..listResult = Ok(Paged<ServiceProvider>(
        [ServiceProvider.fromJson({
          'id': 'p1', 'fullName': 'Jack Brennan', 'headline': 'ECU Specialist',
          'brands': ['BMW'], 'skills': ['Coding'], 'services': ['ECU_CODING'],
          'ratingAvg': 4.4, 'ratingCount': 112,
        })],
        const PageMeta(page: 1, limit: 20, pageSize: 1, total: 1,
            totalPages: 1, hasNextPage: false, hasPreviousPage: false),
      ));
    Get.put<ProvidersRepository>(repo);
    Get.put(ProvidersListController(repo,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));

    await tester.pumpWidget(const GetMaterialApp(home: ProvidersListPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Jack Brennan'), findsOneWidget);
  });

  _detailTests();
}

/// Pumps on a TALL surface.
///
/// The profile is a ListView, which builds lazily: on the default 800x600
/// test window its footer CTA is never constructed, so an assertion about it
/// fails for a reason that has nothing to do with the code. A tall window
/// builds the whole page, which is the point of a mount test.
Future<void> _pumpTall(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(home: home));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

ServiceProvider _p({String name = 'Jack Brennan'}) => ServiceProvider.fromJson({
  'id': 'p1', 'fullName': name, 'headline': 'ECU Specialist',
  'brands': ['BMW'], 'skills': ['Coding'], 'services': ['ECU_CODING'],
  'ratingAvg': 4.4, 'ratingCount': 112, 'location': 'Liverpool',
  'yearsExperience': 12, 'bio': 'Specialises in diagnostics.',
  'vehiclesServiced': 1240,
});

void _detailTests() {
  testWidgets('ProviderDetailPage builds without throwing', (tester) async {
    final repo = FakeProvidersRepository()..byIdResult = Ok(_p());
    Get.put<ProvidersRepository>(repo);
    Get.put(ProviderDetailController(repo,
        reviews: FakeReviewsRepository(),
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));

    await _pumpTall(tester, const ProviderDetailPage(providerId: 'p1'));

    expect(tester.takeException(), isNull);
    // Upper-cased in the header, as the comp draws it.
    expect(find.text('JACK BRENNAN'), findsOneWidget);
    expect(find.text('ECU Specialist'), findsOneWidget);
    // Sections driven by data, not literals.
    expect(find.text('Expertise Profile'), findsOneWidget);
    expect(find.text('1240+ Vehicles Serviced'), findsOneWidget);
    expect(find.text('12 Years Experience'), findsOneWidget);
    // The Specializations tile comes from services[], with the enum's own
    // label — not one of four hardcoded tiles.
    expect(find.text('ECU Tuning'), findsOneWidget);
    expect(find.text('BMW'), findsOneWidget);
    // The CTA names what THIS provider offers.
    expect(find.text('Book ECU Tuning'), findsOneWidget);
    // A buyer does not know /v1/providers only returns approved providers, so
    // to them this badge means the provider cleared KYC.
    expect(find.text('EXPERT VERIFIED'), findsOneWidget);
    // Where they work — the booking screen shows the same value.
    expect(find.text('Liverpool'), findsOneWidget);
  });

  testWidgets('a provider with none of the new fields renders no empty '
      'headings', (tester) async {
    // Everyone who registered before those columns existed. A heading over
    // nothing is worse than no heading.
    final bare = ServiceProvider.fromJson({
      'id': 'p1', 'fullName': 'Bare Provider', 'brands': <String>[],
      'ratingAvg': 0, 'ratingCount': 0,
    });
    final repo = FakeProvidersRepository()..byIdResult = Ok(bare);
    Get.put<ProvidersRepository>(repo);
    Get.put(ProviderDetailController(repo,
        reviews: FakeReviewsRepository(),
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));

    await _pumpTall(tester, const ProviderDetailPage(providerId: 'p1'));

    expect(tester.takeException(), isNull);
    expect(find.text('BARE PROVIDER'), findsOneWidget);
    expect(find.text('Expertise Profile'), findsNothing);
    expect(find.text('Specializations'), findsNothing);
    expect(find.text('Brands Supported'), findsNothing);
    expect(find.textContaining('Vehicles Serviced'), findsNothing);
    // Unrated reads 'New', never 0.0.
    expect(find.text('New'), findsOneWidget);
    // Testimonials always render their heading — an empty one is meaningful.
    expect(find.text('Client Testimonials'), findsOneWidget);
    expect(find.textContaining('No reviews yet'), findsOneWidget);
    // The badge is about approval, not about having filled a profile in.
    expect(find.text('EXPERT VERIFIED'), findsOneWidget);
    // With no services, the CTA cannot name one.
    expect(find.text('Book a callout'), findsOneWidget);
  });

  testWidgets('a failed reviews read does not blank the profile', (
    tester,
  ) async {
    // Testimonials are a bonus section: a provider whose reviews time out
    // still has a profile worth reading.
    final repo = FakeProvidersRepository()..byIdResult = Ok(_p());
    Get.put<ProvidersRepository>(repo);
    Get.put(ProviderDetailController(repo,
        // forTargetResult left null, so the fake returns an Err.
        reviews: FakeReviewsRepository(),
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));

    await _pumpTall(tester, const ProviderDetailPage(providerId: 'p1'));

    expect(tester.takeException(), isNull);
    expect(find.text('JACK BRENNAN'), findsOneWidget);
    expect(find.textContaining('No reviews yet'), findsOneWidget);
  });

  testWidgets('the directory renders its empty state without throwing', (
    tester,
  ) async {
    // The Empty arm is a different subtree from Data, and an Obx fault can
    // hide in either.
    final repo = FakeProvidersRepository()
      ..listResult = Ok(Paged<ServiceProvider>(
        const [],
        const PageMeta(page: 1, limit: 20, pageSize: 0, total: 0,
            totalPages: 0, hasNextPage: false, hasPreviousPage: false),
      ));
    Get.put<ProvidersRepository>(repo);
    Get.put(ProvidersListController(repo,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));

    await tester.pumpWidget(const GetMaterialApp(home: ProvidersListPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('No providers match'), findsOneWidget);
  });

  testWidgets('tapping a service chip repaints it as selected', (tester) async {
    // The regression itself: the chip row must react to the selection it
    // drives. Before the fix this threw instead of repainting.
    final repo = FakeProvidersRepository()
      ..listResult = Ok(Paged<ServiceProvider>(
        [_p()],
        const PageMeta(page: 1, limit: 20, pageSize: 1, total: 1,
            totalPages: 1, hasNextPage: false, hasPreviousPage: false),
      ));
    Get.put<ProvidersRepository>(repo);
    final c = Get.put(ProvidersListController(repo,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));

    await tester.pumpWidget(const GetMaterialApp(home: ProvidersListPage()));
    await tester.pump();

    await tester.tap(find.text('ECU Tuning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(c.service.value, BookingServiceType.ecuCoding);
  });
}

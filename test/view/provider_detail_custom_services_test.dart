import 'package:autonect/controller/buyer/new_booking_controller.dart';
import 'package:autonect/controller/buyer/provider_detail_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/electrician_service.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/data/repositories/providers_repository.dart';
import 'package:autonect/data/repositories/reviews_repository.dart';
import 'package:autonect/view/screens/buyer/providers/new_booking.dart';
import 'package:autonect/view/screens/buyer/providers/provider_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

ServiceProvider _providerWithServices() => const ServiceProvider(
      id: 'prov-1',
      fullName: 'John Auto Electrician',
      brands: ['BMW', 'Audi'],
      ratingAvg: 4.9,
      ratingCount: 15,
      skills: ['Coding', 'Remapping'],
      services: [BookingServiceType.ecuCoding, BookingServiceType.diagnostic],
      customServices: [
        ElectricianService(
          id: 'cs-1',
          electricianId: 'prov-1',
          name: 'ECU Remapping',
          price: '£360',
          pricingType: 'Fixed Price',
          serviceType: BookingServiceType.ecuCoding,
          description: 'Stage 1 custom remap',
        ),
        ElectricianService(
          id: 'cs-2',
          electricianId: 'prov-1',
          name: 'Diagnostic Sweep',
          price: '£89',
          pricingType: 'Per Session',
          serviceType: BookingServiceType.diagnostic,
          description: 'Full vehicle diagnostics',
        ),
      ],
      location: 'London',
      region: Region.london,
    );

ServiceProvider _providerWithoutCustomServices() => const ServiceProvider(
      id: 'prov-2',
      fullName: 'Plain Specialist',
      brands: ['Ford'],
      ratingAvg: 0,
      ratingCount: 0,
      skills: [],
      services: [BookingServiceType.repair],
      customServices: [],
      location: 'London',
      region: Region.london,
    );

Future<void> _pumpApp(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(home: widget));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  testWidgets('ProviderDetailPage renders Services Offered when customServices exist',
      (tester) async {
    final provider = _providerWithServices();
    final providersRepo = FakeProvidersRepository()..byIdResult = Ok(provider);
    final reviewsRepo = FakeReviewsRepository()
      ..forTargetResult = Ok(ReviewsPage(
        items: const [],
        meta: PageMeta.empty,
        summary: ReviewsSummary.fromMeta(null),
      ));

    Get.put<ProvidersRepository>(providersRepo);
    Get.put<ReviewsRepository>(reviewsRepo);
    Get.put(ProviderDetailController(providersRepo, reviews: reviewsRepo));

    await _pumpApp(tester, const ProviderDetailPage(providerId: 'prov-1'));

    expect(find.text('Services Offered'), findsOneWidget);
    expect(find.text('2 available'), findsOneWidget);
    expect(find.text('ECU Remapping'), findsOneWidget);
    expect(find.text('£360'), findsOneWidget);
    expect(find.text('Fixed Price'), findsOneWidget);
    expect(find.text('Diagnostic Sweep'), findsOneWidget);
    expect(find.text('£89'), findsOneWidget);
    expect(find.text('Per Session'), findsOneWidget);
    expect(find.text('Book ECU Remapping'), findsOneWidget);
  });

  testWidgets('ProviderDetailPage falls back to Specializations when customServices are empty',
      (tester) async {
    final provider = _providerWithoutCustomServices();
    final providersRepo = FakeProvidersRepository()..byIdResult = Ok(provider);
    final reviewsRepo = FakeReviewsRepository()
      ..forTargetResult = Ok(ReviewsPage(
        items: const [],
        meta: PageMeta.empty,
        summary: ReviewsSummary.fromMeta(null),
      ));

    Get.put<ProvidersRepository>(providersRepo);
    Get.put<ReviewsRepository>(reviewsRepo);
    Get.put(ProviderDetailController(providersRepo, reviews: reviewsRepo));

    await _pumpApp(tester, const ProviderDetailPage(providerId: 'prov-2'));

    expect(find.text('Services Offered'), findsNothing);
    expect(find.text('Specializations'), findsOneWidget);
    expect(find.text('Repair'), findsOneWidget);
  });

  testWidgets('NewBookingPage displays selectable custom services and preselects',
      (tester) async {
    final provider = _providerWithServices();
    final bookingsRepo = FakeBookingsRepository()
      ..availabilityResult = Ok(DayAvailability(
        date: '2026-09-22',
        slots: [
          BookingSlot(
            time: '09:00',
            scheduledAt: DateTime.parse('2026-09-22T09:00:00.000Z'),
            available: true,
          ),
        ],
      ));

    Get.put<BookingsRepository>(bookingsRepo);
    final controller = NewBookingController(bookingsRepo);
    Get.put(controller);

    await _pumpApp(
      tester,
      NewBookingPage(
        provider: provider,
        selectedService: provider.customServices.first,
      ),
    );

    expect(find.text('Select Service'), findsOneWidget);
    expect(find.text('ECU Remapping'), findsWidgets);
    expect(find.text('Diagnostic Sweep'), findsOneWidget);

    // Initial service is pre-selected
    expect(controller.selectedCustomService.value?.id, 'cs-1');

    // Tap the second service
    await tester.tap(find.text('Diagnostic Sweep'));
    await tester.pumpAndSettle();

    expect(controller.selectedCustomService.value?.id, 'cs-2');
    expect(controller.serviceType.value, BookingServiceType.diagnostic);
  });
}

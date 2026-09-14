import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/view/screens/electrician/home/upcoming_booking_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

Booking _booking({String status = 'IN_PROGRESS'}) => Booking.fromJson({
  'id': 'bk-100',
  'buyerId': 'b100',
  'electricianId': 'e100',
  'scheduledAt': '2026-10-24T10:00:00.000Z',
  'createdAt': '2026-10-20T09:00:00.000Z',
  'serviceType': 'ECU_CODING',
  'status': status,
  'description': 'Please check my sensor wiring around the rear bumper assembly.',
  'regNumber': 'WP0AB2Y1...7829',
  'location': 'Downtown District, Sector 7',
  'durationMins': 105,
  'quotedPence': 28500,
  'buyer': {'id': 'b100', 'name': 'Marcus Thorne'},
  'events': [{'status': status, 'at': '2026-10-20T09:00:00.000Z'}],
});

Future<void> _pumpTall(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(home: home));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('ElectricianBookingDetailsPage', () {
    testWidgets('renders Figma mockup defaults when opened without a booking', (
      tester,
    ) async {
      final repo = FakeBookingsRepository();
      Get.put<BookingsRepository>(repo);

      await _pumpTall(tester, const ElectricianBookingDetailsPage());

      expect(tester.takeException(), isNull);
      expect(find.text('Booking Details'), findsOneWidget);
      expect(find.text('Marcus Thorne'), findsOneWidget);
      expect(find.text('PREMIUM CLIENT'), findsOneWidget);
      expect(find.text('12 BOOKINGS'), findsOneWidget);
      expect(find.text('SERVICE DETAILS'), findsOneWidget);
      expect(find.text('ECU Coding'), findsOneWidget);
      expect(find.text('SCHEDULE'), findsOneWidget);
      expect(find.text('TIME SLOT'), findsOneWidget);
      expect(find.text('ESTIMATED DURATION'), findsOneWidget);
      expect(find.text('SERVICE FEE'), findsOneWidget);
      expect(find.text('VEHICLE SPECS'), findsOneWidget);
      expect(find.text('Porsche Taycan Turbo S'), findsOneWidget);
      expect(find.text('CUSTOMER NOTES'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Mark as Completed'), findsOneWidget);
    });

    testWidgets('renders real booking data when bound to a real booking', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..advanceResult = Ok(_booking(status: 'COMPLETED'));
      Get.put<BookingsRepository>(repo);

      final b = _booking(status: 'CONFIRMED');
      await _pumpTall(tester, ElectricianBookingDetailsPage(booking: b));

      expect(tester.takeException(), isNull);
      expect(find.text('Marcus Thorne'), findsOneWidget);
      expect(find.text('ECU Coding'), findsOneWidget);
      expect(find.text('Start Job'), findsOneWidget);

      // Tap Start Job advances booking
      await tester.tap(find.text('Start Job'));
      await tester.pump();
      expect(repo.calls, contains('advance:bk-100:IN_PROGRESS'));
    });
  });
}

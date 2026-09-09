import 'package:autonect/controller/buyer/my_bookings_controller.dart';
import 'package:autonect/controller/buyer/new_booking_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/buyer/providers/booking_confirmed.dart';
import 'package:autonect/view/screens/buyer/providers/my_bookings.dart';
import 'package:autonect/view/screens/buyer/providers/new_booking.dart';
import 'package:autonect/view/widget/month_calendar.dart';
import 'package:autonect/view/widget/slot_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// The booking flow. Two things here are worth more than the rest:
/// a slot the server marked taken must be UNPICKABLE rather than offered and
/// then refused, and a booking with no quote must never render as £0.00.

ServiceProvider _provider() => ServiceProvider.fromJson({
  'id': 'prov-1', 'fullName': 'Jack Brennan', 'headline': 'ECU Specialist',
  'brands': ['BMW'], 'skills': ['Coding'],
  'services': ['ECU_CODING', 'DIAGNOSTIC'],
  'ratingAvg': 4.4, 'ratingCount': 112, 'region': 'LONDON',
});

Map<String, dynamic> _slotJson(String time, String iso, {bool free = true}) => {
  'time': time, 'scheduledAt': iso, 'available': free,
};

DayAvailability _day({bool elevenTaken = false}) =>
    DayAvailability.fromJson({
      'date': '2026-09-10',
      'slots': [
        _slotJson('09:00', '2026-09-10T08:00:00.000Z'),
        _slotJson('11:30', '2026-09-10T10:30:00.000Z', free: !elevenTaken),
        _slotJson('14:00', '2026-09-10T13:00:00.000Z'),
      ],
    });

Booking _booking({
  String status = 'PENDING',
  int? quotedPence,
  String scheduledAt = '2026-09-10T08:00:00.000Z',
}) => Booking.fromJson({
  'id': 'bk-1', 'buyerId': 'b1', 'electricianId': 'prov-1',
  'scheduledAt': scheduledAt, 'createdAt': '2026-09-09T10:00:00.000Z',
  'serviceType': 'ECU_CODING', 'status': status, 'region': 'LONDON',
  'description': 'Rewiring', 'quotedPence': quotedPence,
  'electrician': {
    'id': 'prov-1', 'name': 'J Brennan',
    'electricianProfile': {'fullName': 'Jack Brennan', 'headline': 'ECU Specialist'},
  },
  'events': [{'status': 'PENDING', 'at': '2026-09-09T10:00:00.000Z'}],
});

PageMeta _meta(int n) => PageMeta(
  page: 1, limit: 20, pageSize: n, total: n,
  totalPages: n == 0 ? 0 : 1, hasNextPage: false, hasPreviousPage: false,
);

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

  group('isoDate', () {
    test('names the LOCAL day, not the UTC one', () {
      // toIso8601String() would convert to UTC first and name yesterday for
      // anyone booking after midnight in a positive offset.
      expect(isoDate(DateTime(2026, 9, 10, 0, 30)), '2026-09-10');
      expect(isoDate(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('MonthCalendar', () {
    test('isSameDay ignores the time of day', () {
      expect(isSameDay(DateTime(2026, 9, 10, 9), DateTime(2026, 9, 10, 17)),
          isTrue);
      expect(isSameDay(DateTime(2026, 9, 10), DateTime(2026, 9, 11)), isFalse);
    });
  });

  group('NewBookingController', () {
    NewBookingController controller(FakeBookingsRepository repo) =>
        NewBookingController(repo,
            toast: (_) {}, showBusy: () {}, hideBusy: () {});

    test('starts on the first service the provider actually offers', () async {
      final repo = FakeBookingsRepository()..availabilityResult = Ok(_day());
      final c = controller(repo);
      c.start(_provider());
      await Future<void>.delayed(Duration.zero);

      // Matches what the profile CTA named, so the two screens agree.
      expect(c.serviceType.value, BookingServiceType.ecuCoding);
      expect(repo.calls.first, startsWith('availability:prov-1:'));
    });

    test('cannot submit until a slot is picked', () async {
      final repo = FakeBookingsRepository()..availabilityResult = Ok(_day());
      final c = controller(repo);
      c.start(_provider());
      await Future<void>.delayed(Duration.zero);
      expect(c.canSubmit, isFalse);

      c.selectedSlot.value = _day().slots.first;
      expect(c.canSubmit, isTrue);
    });

    test('changing day CLEARS the slot', () async {
      final repo = FakeBookingsRepository()..availabilityResult = Ok(_day());
      final c = controller(repo);
      c.start(_provider());
      await Future<void>.delayed(Duration.zero);
      c.selectedSlot.value = _day().slots.first;

      await c.selectDay(DateTime(2026, 9, 11));
      // Leaving it set would let Confirm submit an instant the buyer can no
      // longer see on screen.
      expect(c.selectedSlot.value, isNull);
      expect(c.canSubmit, isFalse);
    });

    test('sends the slot instant VERBATIM, in UTC', () async {
      final repo = FakeBookingsRepository()
        ..availabilityResult = Ok(_day())
        ..createResult = Ok(_booking());
      final c = controller(repo);
      c.start(_provider());
      await Future<void>.delayed(Duration.zero);
      c.selectedSlot.value = _day().slots.first;

      await c.submit(description: 'Rewiring');
      // Rebuilding the instant client-side is how the two ends disagree about
      // what 09:00 meant in July.
      expect(repo.calls.last,
          contains('create:prov-1:ECU_CODING:2026-09-10T08:00:00.000Z'));
    });

    test('a taken slot re-reads availability instead of leaving it stale',
        () async {
      final repo = FakeBookingsRepository()
        ..availabilityResult = Ok(_day())
        ..createResult = Err<Booking>(const ApiError.network());
      final c = controller(repo);
      c.start(_provider());
      await Future<void>.delayed(Duration.zero);
      c.selectedSlot.value = _day().slots.first;
      final before = repo.calls.where((x) => x.startsWith('availability')).length;

      await c.submit();
      await Future<void>.delayed(Duration.zero);

      expect(repo.calls.where((x) => x.startsWith('availability')).length,
          greaterThan(before));
    });
  });

  group('SlotPicker', () {
    testWidgets('a taken slot cannot be picked', (tester) async {
      BookingSlot? picked;
      final slots = _day(elevenTaken: true).slots;
      await _pumpTall(tester, Scaffold(body: SlotPicker(
        slots: slots, selected: null, onSelect: (s) => picked = s,
      )));

      await tester.tap(find.text('11:30'));
      await tester.pump();
      // Offered-then-refused is the worst possible moment to learn a slot is
      // gone: the buyer has already filled the rest of the form.
      expect(picked, isNull);

      await tester.tap(find.text('09:00'));
      await tester.pump();
      expect(picked?.time, '09:00');
    });

    testWidgets('splits morning from afternoon on the LABEL', (tester) async {
      await _pumpTall(tester, Scaffold(body: SlotPicker(
        slots: _day().slots, selected: null, onSelect: (_) {},
      )));

      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
    });
  });

  group('BookingConfirmedPage', () {
    testWidgets('says requested, not scheduled, while PENDING', (tester) async {
      await _pumpTall(tester, BookingConfirmedPage(booking: _booking()));

      expect(tester.takeException(), isNull);
      expect(find.text('Booking Confirmed'), findsOneWidget);
      // The provider has not accepted yet; claiming it is locked in would be
      // the screen overstating what happened.
      expect(find.textContaining('requested'), findsOneWidget);
      expect(find.text('ECU Tuning'), findsOneWidget);
    });
  });

  group('MyBookingsPage', () {
    testWidgets('renders a booking and offers cancel only while allowed', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)));
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, const MyBookingsPage());

      expect(tester.takeException(), isNull);
      expect(find.text('Jack Brennan'), findsOneWidget);
      // quotedPence is null until the provider quotes — £0.00 would read as
      // free.
      expect(find.text('Awaiting quote'), findsOneWidget);
      expect(find.text('Cancel booking'), findsOneWidget);
    });

    testWidgets('a COMPLETED booking offers no cancel', (tester) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>(
            [_booking(status: 'COMPLETED', quotedPence: 12500)], _meta(1)));
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, const MyBookingsPage());

      // Past IN_PROGRESS the server returns 409, so the control must not be
      // offered at all.
      expect(find.text('Cancel booking'), findsNothing);
      expect(find.text('£125.00'), findsOneWidget);
    });

    testWidgets('renders the empty state', (tester) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>(const [], _meta(0)));
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, const MyBookingsPage());

      expect(tester.takeException(), isNull);
      expect(find.text('No bookings yet'), findsOneWidget);
    });
  });

  group('NewBookingPage', () {
    testWidgets('builds without throwing, and Confirm waits for a slot', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()..availabilityResult = Ok(_day());
      Get.put<BookingsRepository>(repo);
      Get.put(NewBookingController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, NewBookingPage(provider: _provider()));

      expect(tester.takeException(), isNull);
      expect(find.text('Booking with Jack Brennan'), findsOneWidget);
      expect(find.text('Confirm Selection'), findsOneWidget);
      // No slot picked yet, so the summary must not invent a time.
      expect(find.text('Not selected'), findsOneWidget);
    });
  });

  group('Booking model', () {
    test('quotedPence null means unquoted, not free', () {
      expect(_booking().isQuoted, isFalse);
      expect(_booking(quotedPence: 0).isQuoted, isTrue);
    });

    test('canCancel mirrors the server rule', () {
      expect(_booking().canCancel, isTrue);
      expect(_booking(status: 'CONFIRMED').canCancel, isTrue);
      expect(_booking(status: 'IN_PROGRESS').canCancel, isFalse);
      expect(_booking(status: 'COMPLETED').canCancel, isFalse);
    });

    test('an unknown status decodes to null rather than throwing', () {
      final b = Booking.fromJson({
        'id': 'x', 'buyerId': 'b', 'electricianId': 'e',
        'scheduledAt': '2026-09-10T08:00:00.000Z',
        'createdAt': '2026-09-09T10:00:00.000Z',
        'status': 'RESCHEDULED',
      });
      expect(b.status, isNull);
      expect(b.events, isEmpty);
      expect(b.provider, isNull);
    });
  });

  group('ViewState wiring', () {
    test('an availability failure is Failed, so the picker offers retry',
        () async {
      final repo = FakeBookingsRepository()
        ..availabilityResult = Err<DayAvailability>(const ApiError.network());
      final c = NewBookingController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {});
      c.start(_provider());
      await Future<void>.delayed(Duration.zero);

      expect(c.slots.value, isA<Failed<List<BookingSlot>>>());
    });
  });
}

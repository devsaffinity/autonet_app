import 'package:autonect/controller/electrician/provider_bookings_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/view/screens/electrician/home/booking_requests.dart';
import 'package:autonect/view/screens/electrician/home/electrician_booking.dart';
import 'package:autonect/view/screens/electrician/home/widgets/provider_booking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// The provider side of a booking — the half that unstranded the loop. Every
/// booking sat at PENDING because the route to advance one existed but
/// nothing could list the ids to advance.

Booking _booking({
  String status = 'PENDING',
  bool receiptIssued = false,
  int? quotedPence,
  int? finalPence,
}) => Booking.fromJson({
  'id': 'bk-1', 'buyerId': 'b1', 'electricianId': 'e1',
  'scheduledAt': '2026-09-10T08:00:00.000Z',
  'createdAt': '2026-09-09T10:00:00.000Z',
  'serviceType': 'ECU_CODING', 'status': status,
  'description': 'Intermittent dash warning', 'regNumber': 'LM19XYZ',
  'durationMins': 90,
  'quotedPence': ?quotedPence,
  'finalPence': ?finalPence,
  if (receiptIssued) 'receipt': {'number': 'REC-001', 'issuedAt': '2026-09-10T12:00:00.000Z'},
  'buyer': {'id': 'b1', 'name': 'Dana Okafor'},
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
  await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: home)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('forward-only machine', () {
    test('offers exactly one legal next step, never a menu of 409s', () {
      expect(ProviderBookingsController.nextStep(BookingStatus.pending),
          BookingStatus.confirmed);
      expect(ProviderBookingsController.nextStep(BookingStatus.confirmed),
          BookingStatus.inProgress);
      expect(ProviderBookingsController.nextStep(BookingStatus.inProgress),
          BookingStatus.completed);
      // Terminal states have nowhere to go.
      expect(ProviderBookingsController.nextStep(BookingStatus.completed), isNull);
      expect(ProviderBookingsController.nextStep(BookingStatus.cancelled), isNull);
      expect(ProviderBookingsController.nextStep(null), isNull);
    });

    test('the label names the action, not the status', () {
      // 'Accept request' is what the provider is doing; 'Confirmed' is what
      // the row becomes.
      expect(ProviderBookingsController.nextStepLabel(BookingStatus.pending),
          'Accept request');
      expect(ProviderBookingsController.nextStepLabel(BookingStatus.inProgress),
          'Mark completed');
      expect(ProviderBookingsController.nextStepLabel(BookingStatus.completed),
          isNull);
    });
  });

  group('ProviderBookingsController', () {
    ProviderBookingsController controller(
      FakeBookingsRepository repo, {
      BookingStatus? initial,
    }) => ProviderBookingsController(repo,
        initialFilter: initial, toast: (_) {}, showBusy: () {}, hideBusy: () {});

    test('the requests screen asks only for PENDING', () async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)));
      final c = controller(repo, initial: BookingStatus.pending);

      await c.refreshFirst();
      expect(repo.calls.last, contains(':PENDING'));
    });

    test('accepting re-reads rather than patching the row', () async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)))
        ..advanceResult = Ok(_booking(status: 'CONFIRMED'));
      final c = controller(repo, initial: BookingStatus.pending);
      await c.refreshFirst();
      final before = repo.calls.where((x) => x.startsWith('bookings:')).length;

      await c.advance(_booking(), BookingStatus.confirmed);

      expect(repo.calls, contains('advance:bk-1:CONFIRMED'));
      // Accepting moves the booking OUT of the PENDING filter; patching in
      // place would leave a CONFIRMED row under the Pending tab.
      expect(repo.calls.where((x) => x.startsWith('bookings:')).length,
          greaterThan(before));
    });

    test('declining is a CANCELLATION with a reason, not a status advance',
        () async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)))
        ..cancelResult = Ok(_booking(status: 'CANCELLED'));
      final c = controller(repo, initial: BookingStatus.pending);
      await c.refreshFirst();

      await c.decline(_booking(), 'Fully booked that week');

      // That is how the server models it; inventing a separate verb would put
      // the client out of step with the row it produces.
      expect(repo.calls, contains('cancel:bk-1:Fully booked that week'));
      expect(repo.calls.any((x) => x.startsWith('advance:')), isFalse);
    });
  });

  group('ElectricianBookingRequestPage', () {
    testWidgets('shows a pending request with the buyer and the fault', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)));
      Get.put<BookingsRepository>(repo);

      await _pumpTall(tester, const ElectricianBookingRequestPage());

      expect(tester.takeException(), isNull);
      expect(find.text('Dana Okafor'), findsOneWidget);
      // The single most useful line for somebody deciding to take the job.
      expect(find.text('Intermittent dash warning'), findsOneWidget);
      expect(find.text('LM19XYZ'), findsOneWidget);
      expect(find.text('Accept request'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('renders the empty state, not the mock fixtures', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>(const [], _meta(0)));
      Get.put<BookingsRepository>(repo);

      await _pumpTall(tester, const ElectricianBookingRequestPage());

      expect(find.text('No new requests'), findsOneWidget);
      // The mock showed an Acceptance Rate of 94%. Nothing computes one, and
      // a fabricated figure on a provider's own dashboard is a number they
      // would act on.
      expect(find.textContaining('94%'), findsNothing);
      expect(find.textContaining('Acceptance Rate'), findsNothing);
    });
  });

  group('ElectricianMyBookingsPage', () {
    testWidgets('a confirmed booking offers Start, not Accept', (tester) async {
      final repo = FakeBookingsRepository()
        ..listResult =
            Ok(Paged<Booking>([_booking(status: 'CONFIRMED')], _meta(1)));
      Get.put<BookingsRepository>(repo);

      await _pumpTall(tester, const ElectricianMyBookingsPage());

      expect(tester.takeException(), isNull);
      expect(find.text('Start job'), findsOneWidget);
      expect(find.text('Accept request'), findsNothing);
    });

    testWidgets('a completed booking offers no action at all and no price edit button', (tester) async {
      final repo = FakeBookingsRepository()
        ..listResult =
            Ok(Paged<Booking>([_booking(status: 'COMPLETED')], _meta(1)));
      Get.put<BookingsRepository>(repo);

      await _pumpTall(tester, const ElectricianMyBookingsPage());

      expect(find.text('Mark completed'), findsNothing);
      expect(find.text('Decline'), findsNothing);
      expect(find.text('Change'), findsNothing);
      expect(find.text('Set price'), findsNothing);
      // COMPLETED is terminal, and it is what makes the booking reviewable.
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('FINAL PRICE'), findsOneWidget);
    });
  });

  group('quoting', () {
    test('canQuote: only active bookings (CONFIRMED, IN_PROGRESS) can be quoted; COMPLETED is locked', () {
      // The server and UX lock completed/pending/cancelled bookings.
      expect(ProviderBookingsController.canQuote(BookingStatus.pending), isFalse);
      expect(ProviderBookingsController.canQuote(BookingStatus.cancelled), isFalse);
      expect(ProviderBookingsController.canQuote(BookingStatus.confirmed), isTrue);
      expect(ProviderBookingsController.canQuote(BookingStatus.inProgress), isTrue);
      expect(ProviderBookingsController.canQuote(BookingStatus.completed), isFalse);
    });

    test('canQuoteBooking: locks null, completed, cancelled, and receipt-issued bookings', () {
      expect(ProviderBookingsController.canQuoteBooking(null), isFalse);
      expect(ProviderBookingsController.canQuoteBooking(_booking(status: 'PENDING')), isFalse);
      expect(ProviderBookingsController.canQuoteBooking(_booking(status: 'CANCELLED')), isFalse);
      expect(ProviderBookingsController.canQuoteBooking(_booking(status: 'COMPLETED')), isFalse);
      expect(ProviderBookingsController.canQuoteBooking(_booking(status: 'CONFIRMED')), isTrue);
      expect(ProviderBookingsController.canQuoteBooking(_booking(status: 'IN_PROGRESS')), isTrue);
      expect(
        ProviderBookingsController.canQuoteBooking(
          _booking(status: 'CONFIRMED', receiptIssued: true),
        ),
        isFalse,
      );
    });

    test('sends quotedPence, and re-reads so the stored figure wins', () async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking(status: 'CONFIRMED')], _meta(1)))
        ..quoteResult = Ok(_booking(status: 'CONFIRMED'));
      final c = ProviderBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {});
      await c.refreshFirst();
      final before = repo.calls.where((x) => x.startsWith('bookings:')).length;

      await c.quote(_booking(status: 'CONFIRMED'), quotedPence: 8950);

      expect(repo.calls, contains('quote:bk-1:quoted=8950'));
      // The row must show what was STORED, not what was typed.
      expect(repo.calls.where((x) => x.startsWith('bookings:')).length,
          greaterThan(before));
    });

    test('a final price goes in its own field, not over the quote', () async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking(status: 'COMPLETED')], _meta(1)))
        ..quoteResult = Ok(_booking(status: 'COMPLETED'));
      final c = ProviderBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {});

      await c.quote(_booking(status: 'COMPLETED'), finalPence: 9500);

      // A buyer is owed the difference between 'you said' and 'you charged'.
      expect(repo.calls, contains('quote:bk-1:final=9500'));
    });
  });

  group('Booking.buyer', () {
    test('carries a name and nothing contactable', () {
      final b = _booking();
      expect(b.buyer?.name, 'Dana Okafor');
      expect(b.buyer?.id, 'b1');
    });

    test('is absent on a payload that predates it, without throwing', () {
      final b = Booking.fromJson({
        'id': 'x', 'buyerId': 'b', 'electricianId': 'e',
        'scheduledAt': '2026-09-10T08:00:00.000Z',
        'createdAt': '2026-09-09T10:00:00.000Z',
      });
      expect(b.buyer, isNull);
    });
  });

  group('ProviderBookingCard', () {
    testWidgets('completed booking displays FINAL PRICE without any edit button', (tester) async {
      final b = _booking(status: 'COMPLETED', quotedPence: 5600);
      await _pumpTall(tester, ProviderBookingCard(booking: b));

      expect(find.text('FINAL PRICE'), findsOneWidget);
      expect(find.text('£56.00'), findsOneWidget);
      expect(find.text('Change'), findsNothing);
      expect(find.text('Set price'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('completed booking with finalPence displays final price and no edit button', (tester) async {
      final b = _booking(status: 'COMPLETED', quotedPence: 5000, finalPence: 5600);
      await _pumpTall(tester, ProviderBookingCard(booking: b));

      expect(find.text('FINAL PRICE'), findsOneWidget);
      expect(find.text('£56.00'), findsOneWidget);
      expect(find.text('Change'), findsNothing);
      expect(find.text('Set price'), findsNothing);
    });

    testWidgets('confirmed booking with quote displays QUOTED PRICE with Change button', (tester) async {
      final b = _booking(status: 'CONFIRMED', quotedPence: 7500);
      var quoteTapped = false;
      await _pumpTall(
        tester,
        ProviderBookingCard(
          booking: b,
          onQuote: () => quoteTapped = true,
        ),
      );

      expect(find.text('QUOTED PRICE'), findsOneWidget);
      expect(find.text('£75.00'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      await tester.tap(find.text('Change'));
      expect(quoteTapped, isTrue);
    });

    testWidgets('confirmed booking without quote displays ESTIMATED PAY and Set price button', (tester) async {
      final b = _booking(status: 'CONFIRMED');
      await _pumpTall(tester, ProviderBookingCard(booking: b));

      expect(find.text('ESTIMATED PAY'), findsOneWidget);
      expect(find.text('Not priced'), findsOneWidget);
      expect(find.text('Set price'), findsOneWidget);
    });

    testWidgets('confirmed booking with receipt issued hides price edit button', (tester) async {
      final b = _booking(status: 'CONFIRMED', quotedPence: 5000, receiptIssued: true);
      await _pumpTall(tester, ProviderBookingCard(booking: b));

      expect(find.text('Change'), findsNothing);
      expect(find.text('Set price'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });
  });
}

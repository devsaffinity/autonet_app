import 'dart:async';

import 'package:autonect/controller/buyer/my_bookings_controller.dart';
import 'package:autonect/controller/buyer/new_booking_controller.dart';
import 'package:autonect/controller/buyer/receipt_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/booking_receipt.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/buyer/providers/booking_confirmed.dart';
import 'package:autonect/view/screens/buyer/providers/booking_detail.dart';
import 'package:autonect/view/screens/buyer/providers/my_bookings.dart';
import 'package:autonect/view/screens/buyer/providers/new_booking.dart';
import 'package:autonect/data/repositories/chat_repository.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/month_calendar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/slot_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// The booking flow. Two things here are worth more than the rest:
/// a slot the server marked taken must be UNPICKABLE rather than offered and
/// then refused, and a booking with no quote must never render as £0.00.

ServiceProvider _provider({String? location = 'Bay 4, Speke Road, Liverpool'}) =>
    ServiceProvider.fromJson({
      'id': 'prov-1', 'fullName': 'Jack Brennan', 'headline': 'ECU Specialist',
      'brands': ['BMW'], 'skills': ['Coding'],
      'services': ['ECU_CODING', 'DIAGNOSTIC'],
      'ratingAvg': 4.4, 'ratingCount': 112, 'region': 'LONDON',
      'location': location,
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
  int? buyerRating,
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
  'reviews': [
    if (buyerRating != null)
      {'id': 'rv-1', 'authorId': 'b1', 'rating': buyerRating,
       'text': 'Sorted it', 'createdAt': '2026-09-11T10:00:00.000Z'},
  ],
});

/// A bookings repository whose receipt call waits until the test says so,
/// which is the only way to see the button while the receipt is on its way.
class _HeldReceipts extends FakeBookingsRepository {
  final held = Completer<ApiResult<BookingReceipt>>();

  @override
  Future<ApiResult<BookingReceipt>> receipt(String bookingId) {
    calls.add('receipt:$bookingId');
    return held.future;
  }
}

PageMeta _meta(int n) => PageMeta(
  page: 1, limit: 20, pageSize: n, total: n,
  totalPages: n == 0 ? 0 : 1, hasNextPage: false, hasPreviousPage: false,
);

/// Pumps at a REAL phone width, where layout is actually decided.
///
/// [_pumpTall] uses a 1200dp surface so a lazy ListView builds its whole
/// page, and at 1200dp almost any row fits — which is exactly how a row of
/// three buttons shipped stacked one per line and still passed. Anything
/// asserting about ARRANGEMENT has to be pumped at a width a phone has.
Future<void> _pumpPhone(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(home: home));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

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
      // Both are RECORDED on the booking, not merely shown on screen.
      expect(repo.calls.last, contains(':mins=90'));
      expect(repo.calls.last, contains(':loc=Bay 4, Speke Road, Liverpool'));
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

    testWidgets("the comp's three actions; the receipt waits for the job", (
      tester,
    ) async {
      await _pumpTall(tester, BookingConfirmedPage(booking: _booking()));

      // FIRST name, which is what a person would say.
      expect(find.text('Chat with Jack'), findsOneWidget);
      expect(find.text('View my Bookings'), findsOneWidget);
      expect(find.text('Download Receipt'), findsOneWidget);

      // A just-made booking is neither completed nor priced, and the server
      // issues no receipt until it is both. The control says so rather than
      // offering a tap that can only fail.
      final receipt = tester.widget<MyButton>(
          find.widgetWithText(MyButton, 'Download Receipt'));
      expect(receipt.enabled, isFalse);
      expect(find.textContaining('once the job is complete'), findsOneWidget);
    });

    testWidgets('a completed, priced booking offers its receipt', (
      tester,
    ) async {
      Get.put<BookingsRepository>(FakeBookingsRepository());
      await _pumpTall(tester, BookingConfirmedPage(
          booking: _booking(status: 'COMPLETED', quotedPence: 12500)));

      final receipt = tester.widget<MyButton>(
          find.widgetWithText(MyButton, 'Download Receipt'));
      expect(receipt.enabled, isTrue);
      expect(find.textContaining('once the job is complete'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chat opens the thread for THIS booking', (tester) async {
      final chat = FakeChatRepository();
      Get.put<ChatRepository>(chat);
      await _pumpTall(tester, BookingConfirmedPage(booking: _booking()));

      await tester.tap(find.text('Chat with Jack'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ChatRoomPage), findsOneWidget);
      // Opened by CONTEXT — the booking — never by naming a recipient.
      expect(chat.calls.first, 'open:BOOKING:bk-1');
    });

    testWidgets('the schedule reads back the slot that was booked', (
      tester,
    ) async {
      await _pumpTall(tester, BookingConfirmedPage(booking: _booking()));

      // Both in the DEVICE zone, computed the same way the screen does —
      // hard-coding the strings would pin the test to whatever zone the
      // machine running it happens to be in.
      final at = DateTime.parse('2026-09-10T08:00:00.000Z').toLocal();
      expect(find.text(formatShortDate(at)), findsOneWidget);
      // 24-hour, matching the slot chip the buyer actually tapped. The
      // comp's '11:30 AM' would make one booking read two ways in one flow.
      expect(find.text(formatClock(at)), findsOneWidget);

      // The provider's own headline, not the comp's generic job title.
      expect(find.text('ECU Specialist'), findsOneWidget);
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

    testWidgets('a COMPLETED booking offers a review; nothing else does', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>(
            [_booking(status: 'COMPLETED', quotedPence: 12500)], _meta(1)));
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, const MyBookingsPage());

      // COMPLETED is the only state the server accepts a review from, and it
      // is what finally lets an electrician earn a rating at all.
      expect(find.text('Rate this provider'), findsOneWidget);
    });

    testWidgets("the comp's card actions, and the filter that left the page",
        (tester) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)));
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, const MyBookingsPage());

      expect(find.text('Chat Now'), findsOneWidget);
      expect(find.text('View Booking'), findsOneWidget);
      expect(find.text('Save Receipt'), findsOneWidget);

      // The five chips came off the page: All / Pending / Confirmed /
      // Completed / Cancelled does not fit on one line at any phone width,
      // so 'Cancelled' wrapped onto a row of its own. The filter itself
      // survives as one glyph, because the repository takes `status` and a
      // buyer with a year of callouts needs it.
      expect(find.text('Pending'), findsNothing);
      expect(find.byTooltip('Filter by status'), findsOneWidget);
    });

    testWidgets('the funnel filters, and All clears it', (tester) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)));
      Get.put<BookingsRepository>(repo);
      final c = Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, const MyBookingsPage());

      await tester.tap(find.byTooltip('Filter by status'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed').last);
      await tester.pumpAndSettle();
      expect(c.filter.value, BookingStatus.completed);

      await tester.tap(find.byTooltip('Filter by status'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      // The menu is keyed by INDEX. Keyed by the status itself, 'All' would
      // carry a null value, PopupMenuButton would read that as a DISMISSED
      // menu, and the filter would silently stay on Completed.
      expect(c.filter.value, isNull);
    });

    testWidgets('Save Receipt waits for a completed, priced job', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)));
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, const MyBookingsPage());

      // The control carries its reason rather than a tap target. Matched on
      // the PREFIX rather than the whole sentence: the copy is the screen's
      // to reword, the fact that a reason is attached is not.
      expect(
        find.byWidgetPredicate((w) => w is Tooltip &&
            (w.message ?? '').startsWith('A receipt is available')),
        findsOneWidget,
      );
      await tester.tap(find.text('Save Receipt'));
      await tester.pump();
      expect(repo.calls.where((x) => x.startsWith('receipt:')), isEmpty);
    });

    testWidgets("Save Receipt fetches THIS booking's receipt, and says so", (
      tester,
    ) async {
      final repo = _HeldReceipts()
        ..listResult = Ok(Paged<Booking>(
            [_booking(status: 'COMPLETED', quotedPence: 12500)], _meta(1)));
      final toasts = <String>[];
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));
      Get.put(ReceiptController(repo,
          share: (_, _) async {},
          toast: toasts.add, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, const MyBookingsPage());
      await tester.tap(find.text('Save Receipt'));
      await tester.pump();

      expect(repo.calls, contains('receipt:bk-1'));
      // On its way: the button says so, and a second tap does nothing.
      expect(find.text('Preparing…'), findsOneWidget);
      await tester.tap(find.text('Preparing…'));
      await tester.pump();
      expect(repo.calls.where((x) => x == 'receipt:bk-1'), hasLength(1));

      // The server's own reason reaches the buyer, and the button comes back.
      repo.held.complete(const Err(ApiError(
        code: ApiErrorCode.conflict,
        statusCode: 409,
        message: 'The provider has not recorded a price for this job yet',
      )));
      await tester.pump();
      await tester.pump();
      expect(toasts, ['The provider has not recorded a price for this job yet']);
      expect(find.text('Save Receipt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a reviewed booking shows the review, never a second one', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([
          _booking(status: 'COMPLETED', quotedPence: 12500, buyerRating: 4),
        ], _meta(1)));
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));
      final semantics = tester.ensureSemantics();

      await _pumpTall(tester, const MyBookingsPage());

      // A review is FINAL: the server has no edit and refuses a second one.
      expect(find.text('Rate this provider'), findsNothing);
      expect(find.text('You rated this provider'), findsOneWidget);
      // The stars as one sentence for a screen reader.
      expect(find.bySemanticsLabel('You rated this provider 4 out of 5'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('View Booking opens the detail, with what the row holds',
        (tester) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)));
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, const MyBookingsPage());
      await tester.tap(find.text('View Booking'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(BookingDetailPage), findsOneWidget);
      // NO SECOND FETCH: the list already holds the whole booking, so the
      // detail renders the row it was handed.
      expect(repo.calls.where((x) => x.startsWith('booking:')), isEmpty);
      // The buyer can still cancel from here, using the LIST's handler —
      // a second copy of the reason dialog is how the two screens would
      // end up disagreeing about what is still cancellable.
      expect(find.text('Cancel booking'), findsOneWidget);
    });

    testWidgets("the card's three actions sit on ONE line at phone width",
        (tester) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)));
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpPhone(tester, const MyBookingsPage());

      // The regression itself, and it was invisible on a wide surface: a
      // Container given an `alignment` EXPANDS to fill bounded incoming
      // constraints, so inside a Wrap each pill took the whole card width
      // and became a run of its own. The comp's row of three came out as
      // three full-width bars.
      final chat = tester.getTopLeft(find.text('Chat Now'));
      final view = tester.getTopLeft(find.text('View Booking'));
      final receipt = tester.getTopLeft(find.text('Save Receipt'));

      // One line...
      expect(view.dy, chat.dy);
      expect(receipt.dy, chat.dy);
      // ...in the comp's order, left to right. Equal dy alone would also
      // hold if all three were stacked at zero height.
      expect(view.dx, greaterThan(chat.dx));
      expect(receipt.dx, greaterThan(view.dx));

      // Thirds, so the row cannot become three bars whatever the label or
      // the font measures. The labels ellipsize instead — this suite runs
      // on the test font, where every glyph is as wide as it is tall, so a
      // third here is far tighter than Cairo will ever make it.
      expect(tester.takeException(), isNull);
    });

    testWidgets('a PENDING booking offers no review', (tester) async {
      final repo = FakeBookingsRepository()
        ..listResult = Ok(Paged<Booking>([_booking()], _meta(1)));
      Get.put<BookingsRepository>(repo);
      Get.put(MyBookingsController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, const MyBookingsPage());

      // Reviewing work that has not happened would only earn a 409.
      expect(find.text('Rate this provider'), findsNothing);
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

  group('BookingDetailPage', () {
    testWidgets('a reviewed, priced job: the review read-only, and a receipt',
        (tester) async {
      Get.put<BookingsRepository>(FakeBookingsRepository());
      await _pumpTall(tester, BookingDetailPage(
        booking: _booking(status: 'COMPLETED', quotedPence: 12500, buyerRating: 5),
        onReview: () {},
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Rate this provider'), findsNothing);
      expect(find.text('You rated this provider'), findsOneWidget);
      expect(find.text('Download Receipt'), findsOneWidget);
    });

    testWidgets('a completed job not yet reviewed offers the review', (
      tester,
    ) async {
      Get.put<BookingsRepository>(FakeBookingsRepository());
      await _pumpTall(tester, BookingDetailPage(
        booking: _booking(status: 'COMPLETED', quotedPence: 12500),
        onReview: () {},
      ));

      expect(find.text('Rate this provider'), findsOneWidget);
      expect(find.text('You rated this provider'), findsNothing);
    });

    testWidgets('an unfinished job offers neither', (tester) async {
      await _pumpTall(tester, BookingDetailPage(
        booking: _booking(status: 'CONFIRMED', quotedPence: 12500),
        onReview: () {},
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Rate this provider'), findsNothing);
      expect(find.text('Download Receipt'), findsNothing);
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
      // TWO widgets, not one: the comp sets the provider's name in the brand
      // colour and the lead-in in black, and MyText carries one colour. The
      // assertion is on both halves rather than on the joined string, which
      // no single widget renders any more.
      expect(find.text('Booking with '), findsOneWidget);
      expect(find.text('Jack Brennan'), findsOneWidget);
      expect(find.text('Confirm Selection'), findsOneWidget);
      // The comp's 'Selected slot' line, reading today's date back in words
      // so the day is legible once the calendar has scrolled away.
      expect(find.text('Selected slot'), findsOneWidget);
      expect(find.text(formatLongDate(DateTime.now())), findsOneWidget);
      // No slot picked yet, so the summary must not invent a time.
      expect(find.text('Not selected'), findsOneWidget);
      // The comp draws a map here; this draws the address, which is the part
      // the buyer reads and the provider needs.
      expect(find.text('SERVICE LOCATION'), findsOneWidget);
      expect(find.text('Bay 4, Speke Road, Liverpool'), findsOneWidget);
      // ECU tuning is 90 minutes on the enum. APPROXIMATE is the honest word.
      expect(find.text('Approximate service duration: 90 mins'), findsOneWidget);
    });

    testWidgets('a provider with no address shows no empty Location card', (
      tester,
    ) async {
      final repo = FakeBookingsRepository()..availabilityResult = Ok(_day());
      Get.put<BookingsRepository>(repo);
      Get.put(NewBookingController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));

      await _pumpTall(tester, NewBookingPage(provider: _provider(location: null)));

      // A 'Location' heading over an empty card tells a buyer nothing and
      // looks broken.
      expect(find.text('SERVICE LOCATION'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('BookingServiceType duration', () {
    test('every callout carries a plausible typical duration', () {
      for (final s in BookingServiceType.values) {
        // The server clamps durationMins to 15..600 and 400s outside it, so a
        // constant drifting out of range would break every booking of that
        // type — and only that type.
        expect(s.typicalMinutes, greaterThanOrEqualTo(15));
        expect(s.typicalMinutes, lessThanOrEqualTo(600));
      }
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

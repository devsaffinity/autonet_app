import 'dart:convert';
import 'dart:typed_data';

import 'package:autonect/controller/buyer/receipt_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_receipt.dart';
import 'package:autonect/services/receipt_pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart' show TtfParser;

import '../fakes/fake_buyer_repositories.dart';

/// Receipts, and the rule that a review is final.
///
/// What these pin:
///   - a receipt is only offered for a COMPLETED, PRICED booking;
///   - a booking that cannot have one never reaches the network;
///   - the server's reason is what the customer reads when it says no;
///   - the PDF is real (it parses as a PDF) and prints the frozen snapshot;
///   - a booking the buyer reviewed reports itself reviewed.
Booking _booking({
  String status = 'COMPLETED',
  int? quotedPence = 9000,
  int? finalPence = 12000,
  List<Map<String, dynamic>> reviews = const [],
  bool receipt = false,
}) => Booking.fromJson({
  'id': 'bk1',
  'buyerId': 'buyer1',
  'electricianId': 'prov1',
  'scheduledAt': '2026-09-10T08:00:00.000Z',
  'createdAt': '2026-09-01T10:00:00.000Z',
  'serviceType': 'DIAGNOSTIC',
  'status': status,
  'region': 'LONDON',
  'quotedPence': quotedPence,
  'finalPence': finalPence,
  'reviews': reviews,
  if (receipt) 'receipt': {'number': 7, 'issuedAt': '2026-09-11T10:00:00.000Z'},
});

BookingReceipt _receipt() => BookingReceipt.fromJson({
  'receiptNumber': 'AUT-000042',
  'bookingId': 'bk1',
  'amountPence': 12000,
  'currency': 'GBP',
  'serviceType': 'DIAGNOSTIC',
  'providerName': 'Jack Brennan',
  'buyerName': 'Priya Raman',
  'serviceDate': '2026-09-10T08:00:00.000Z',
  'issuedAt': '2026-09-11T10:00:00.000Z',
  'vehicle': 'BMW 320d (AB12 CDE)',
  'paymentNote': 'Paid directly to Jack Brennan. Autonect did not process this payment.',
});

void main() {
  // rootBundle — the PDF loads its embedded font from the app's assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('booking rules', () {
    test('a receipt needs a COMPLETED booking with a price', () {
      expect(_booking().canHaveReceipt, isTrue);
      // Falls back to the quote, as the server does.
      expect(_booking(finalPence: null).canHaveReceipt, isTrue);
      expect(_booking(status: 'CONFIRMED').canHaveReceipt, isFalse);
      expect(_booking(quotedPence: null, finalPence: null).canHaveReceipt, isFalse);
    });

    test('the buyer\'s own review marks the booking reviewed', () {
      final reviewed = _booking(
        reviews: [
          {
            'id': 'r1',
            'authorId': 'buyer1',
            'rating': 4,
            'text': 'Good',
            'createdAt': '2026-09-11T10:00:00.000Z',
          },
        ],
      );
      expect(reviewed.isReviewed, isTrue);
      expect(reviewed.buyerReview?.rating, 4);
      expect(_booking().isReviewed, isFalse);
    });

    test('a review by someone else does not count as the buyer\'s', () {
      final other = _booking(
        reviews: [
          {
            'id': 'r9',
            'authorId': 'someone-else',
            'rating': 1,
            'createdAt': '2026-09-11T10:00:00.000Z',
          },
        ],
      );
      expect(other.isReviewed, isFalse);
    });

    test('decodes whether a receipt was issued', () {
      expect(_booking(receipt: true).receiptIssued, isTrue);
      expect(_booking().receiptIssued, isFalse);
    });
  });

  group('receipt PDF', () {
    test('produces a real PDF', () async {
      final bytes = await ReceiptPdf.build(_receipt());
      // The PDF magic number — not merely "some bytes came back".
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });

    test('names the file after the receipt number', () {
      expect(ReceiptPdf.fileName(_receipt()), 'Autonect-Receipt-AUT-000042.pdf');
    });

    test('embeds the app font rather than PDF\'s built-in Helvetica', () async {
      // Helvetica does not fail loudly on a name like Łukasz — it draws the Ł
      // as an empty box. So the regression to catch is Helvetica coming back.
      final pdf = latin1.decode(await ReceiptPdf.build(_receipt()));
      expect(pdf, contains('Cairo'));
      expect(pdf, isNot(contains('Helvetica')));
    });

    test('the embedded font can draw international names', () async {
      const names = [
        ('Łukasz Wiśniewski', 'Şükrü Öztürk'),
        ('Ștefan Dvořák', 'Zoë O’Brien'),
        ('محمد احسن', 'Priya Raman'),
      ];
      final fonts = [
        for (final asset in [ReceiptPdf.regularFontAsset, ReceiptPdf.boldFontAsset])
          TtfParser(await rootBundle.load(asset)),
      ];
      for (final pair in names) {
        for (final c in '${pair.$1}${pair.$2}Škoda'.runes.where((c) => c != 0x20)) {
          for (final font in fonts) {
            expect(
              font.charToGlyphIndexMap.containsKey(c),
              isTrue,
              reason: 'no glyph for U+${c.toRadixString(16).toUpperCase()}',
            );
          }
        }
        // And each renders — the Arabic one through the right-to-left path.
        final receipt = BookingReceipt.fromJson({
          'receiptNumber': 'AUT-000003',
          'bookingId': 'bk3',
          'amountPence': 4550,
          'currency': 'GBP',
          'serviceType': 'DIAGNOSTIC',
          'providerName': pair.$1,
          'buyerName': pair.$2,
          'serviceDate': '2026-09-10T08:00:00.000Z',
          'issuedAt': '2026-09-11T10:00:00.000Z',
          'vehicle': 'Škoda Octavia (AB12 CDE)',
          'paymentNote': 'Paid directly to ${pair.$1}. Autonect did not process this payment.',
        });
        final bytes = await ReceiptPdf.build(receipt);
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: pair.$1);
      }
    });

    test('the embedded font has a glyph for the receipt\'s own symbols', () async {
      // The pound sign in every total, and the footer's middle dot.
      for (final asset in [ReceiptPdf.regularFontAsset, ReceiptPdf.boldFontAsset]) {
        final font = TtfParser(await rootBundle.load(asset));
        for (final c in [0x00A3, 0x00B7]) {
          expect(
            font.charToGlyphIndexMap.containsKey(c),
            isTrue,
            reason: '$asset lacks U+${c.toRadixString(16).toUpperCase()}',
          );
        }
      }
    });

    test('renders without a vehicle or a known service', () async {
      final bare = BookingReceipt.fromJson({
        'receiptNumber': 'AUT-000001',
        'bookingId': 'bk2',
        'amountPence': 0,
        'currency': 'GBP',
        'serviceType': 'SOMETHING_NEW',
        'providerName': 'Autonect provider',
        'buyerName': 'Autonect customer',
        'serviceDate': '2026-09-10T08:00:00.000Z',
        'issuedAt': '2026-09-11T10:00:00.000Z',
        'paymentNote': 'Paid directly to Autonect provider. Autonect did not process this payment.',
      });
      final bytes = await ReceiptPdf.build(bare);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('ReceiptController', () {
    ReceiptController controller(
      FakeBookingsRepository repo, {
      List<String>? toasts,
      List<String>? shared,
      bool failShare = false,
    }) => ReceiptController(
      repo,
      share: (Uint8List bytes, String name) async {
        if (failShare) throw Exception('share sheet unavailable');
        shared?.add(name);
      },
      toast: (m) => toasts?.add(m),
      showBusy: () {},
      hideBusy: () {},
    );

    test('fetches, renders and shares the receipt', () async {
      final repo = FakeBookingsRepository()..receiptResult = Ok(_receipt());
      final shared = <String>[];
      final c = controller(repo, shared: shared);

      final ok = await c.open(_booking());

      expect(ok, isTrue);
      expect(repo.calls, contains('receipt:bk1'));
      expect(shared, ['Autonect-Receipt-AUT-000042.pdf']);
      expect(c.working.value, isNull);
    });

    test('never calls the server for a booking that cannot have one', () async {
      final repo = FakeBookingsRepository();
      final toasts = <String>[];
      final c = controller(repo, toasts: toasts);

      final ok = await c.open(_booking(status: 'CONFIRMED', finalPence: null));

      expect(ok, isFalse);
      expect(repo.calls, isEmpty);
      expect(toasts.single, contains('once the job is completed'));
    });

    test('shows the server\'s reason when it refuses', () async {
      final repo = FakeBookingsRepository()
        ..receiptResult = const Err(
          ApiError(
            code: ApiErrorCode.conflict,
            statusCode: 409,
            message: 'The provider has not recorded a price for this job yet',
          ),
        );
      final toasts = <String>[];
      final c = controller(repo, toasts: toasts);

      expect(await c.open(_booking()), isFalse);
      expect(toasts.single, 'The provider has not recorded a price for this job yet');
    });

    test('a failed share is reported and releases the button', () async {
      final repo = FakeBookingsRepository()..receiptResult = Ok(_receipt());
      final toasts = <String>[];
      final c = controller(repo, toasts: toasts, failShare: true);

      expect(await c.open(_booking()), isFalse);
      expect(toasts.single, contains('Could not open the receipt'));
      // Otherwise the button would stay on "Preparing receipt…" forever.
      expect(c.working.value, isNull);
    });
  });
}

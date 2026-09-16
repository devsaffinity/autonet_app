import 'dart:typed_data';

import 'package:autonect/data/models/booking_receipt.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a [BookingReceipt] as an A4 PDF.
///
/// No sharing or saving here — those live in ReceiptController, which is what
/// lets this be unit-tested: a test can build a real PDF without a device.
///
/// THE FONT IS EMBEDDED, NOT PDF's BUILT-IN HELVETICA. Helvetica covers Latin-1
/// only, and dart_pdf draws anything past U+00FF as an empty box — silently, so
/// a provider called Łukasz would be handed a receipt made out to "□ukasz".
/// Cairo is the app's own typeface and covers Latin Extended and Arabic.
///
/// EVERYTHING PRINTED COMES FROM THE RECEIPT, never from the live booking. The
/// receipt is the server's frozen snapshot; reading the booking here would let
/// a later change reach a document the customer already holds.
class ReceiptPdf {
  const ReceiptPdf._();

  static const PdfColor _brand = PdfColor.fromInt(0xFFD94F2B);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _rule = PdfColor.fromInt(0xFFE3E5E9);

  static const String regularFontAsset = 'assets/fonts/Cairo-Regular.ttf';
  static const String boldFontAsset = 'assets/fonts/Cairo-Bold.ttf';

  /// Names and vehicles are typed by users, in any script. dart_pdf only shapes
  /// Arabic-script text laid out right-to-left, so such a value is marked RTL.
  /// The ranges are Hebrew through Arabic Extended, and the two presentation-form
  /// blocks.
  static pw.TextDirection _direction(String s) =>
      s.runes.any(
            (c) =>
                (c >= 0x0590 && c <= 0x08FF) ||
                (c >= 0xFB1D && c <= 0xFDFF) ||
                (c >= 0xFE70 && c <= 0xFEFC),
          )
          ? pw.TextDirection.rtl
          : pw.TextDirection.ltr;

  /// The file name a customer sees when they save or share it.
  static String fileName(BookingReceipt r) => 'Autonect-Receipt-${r.receiptNumber}.pdf';

  static Future<Uint8List> build(BookingReceipt r) async {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(await rootBundle.load(regularFontAsset)),
        bold: pw.Font.ttf(await rootBundle.load(boldFontAsset)),
      ),
      title: 'Receipt ${r.receiptNumber}',
      author: 'Autonect',
      subject: 'Receipt for completed service',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(44, 44, 44, 40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(r),
            pw.SizedBox(height: 26),
            _parties(r),
            pw.SizedBox(height: 22),
            _lineItems(r),
            pw.SizedBox(height: 18),
            _paymentNote(r),
            pw.Spacer(),
            _footer(r),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static pw.Widget _header(BookingReceipt r) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _brand, width: 2)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.RichText(
              text: const pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Auto',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(
                    text: 'nect',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _brand,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('RECEIPT', style: const pw.TextStyle(fontSize: 10, color: _muted)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              r.receiptNumber,
              style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Issued ${formatDayMonthYear(r.issuedAt.toLocal())}',
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
        ),
      ],
    ),
  );

  static pw.Widget _parties(BookingReceipt r) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(child: _labelled('PROVIDER', r.providerName)),
      pw.SizedBox(width: 20),
      pw.Expanded(child: _labelled('CUSTOMER', r.buyerName)),
    ],
  );

  static pw.Widget _lineItems(BookingReceipt r) => pw.Column(
    children: [
      _row('Service', r.serviceType?.label ?? 'Service'),
      _row('Date of service', formatLongDate(r.serviceDate.toLocal())),
      // Omitted rather than printed as "Unknown": the booking recorded none.
      if (r.vehicle != null) _row('Vehicle', r.vehicle!),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.only(top: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _rule)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Total', style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Text(
              formatPence(r.amountPence),
              style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    ],
  );

  /// The one sentence that must never be dropped: Autonect was not paid.
  static pw.Widget _paymentNote(BookingReceipt r) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: const pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFFDF4F1),
      border: pw.Border(left: pw.BorderSide(color: _brand, width: 3)),
    ),
    child: pw.Text(r.paymentNote, style: const pw.TextStyle(fontSize: 10)),
  );

  static pw.Widget _footer(BookingReceipt r) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _rule)),
    ),
    child: pw.Text(
      'Booking reference ${r.bookingId}  ·  Generated by Autonect',
      style: const pw.TextStyle(fontSize: 8, color: _muted),
    ),
  );

  static pw.Widget _labelled(String label, String value) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
      pw.SizedBox(height: 3),
      pw.Text(
        value,
        textDirection: _direction(value),
        style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );

  static pw.Widget _row(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _muted)),
        pw.Text(
          value,
          textDirection: _direction(value),
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    ),
  );
}

import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/booking_enums.dart';

/// A receipt for a completed booking — `GET /v1/bookings/:id/receipt`.
///
/// A SNAPSHOT the server takes once, the first time either party asks for it.
/// Every field here is frozen from that moment: the provider's price is locked
/// and later profile renames do not reach it. So the document a customer saves
/// today is the same document they would get again next year.
///
/// AUTONECT TAKES NO PAYMENT. [paymentNote] says so in the server's own words,
/// and the PDF prints it verbatim rather than paraphrasing it.
class BookingReceipt {
  const BookingReceipt({
    required this.receiptNumber,
    required this.bookingId,
    required this.amountPence,
    required this.currency,
    required this.providerName,
    required this.buyerName,
    required this.serviceDate,
    required this.issuedAt,
    required this.paymentNote,
    this.serviceType,
    this.vehicle,
  });

  /// Printed as the document's identity, e.g. `AUT-000042`.
  final String receiptNumber;
  final String bookingId;

  /// Integer pence. Never a double anywhere near money.
  final int amountPence;
  final String currency;

  /// Null when the server sends a service this build does not know; the PDF
  /// then prints a neutral label instead of failing to render.
  final BookingServiceType? serviceType;

  final String providerName;
  final String buyerName;
  final DateTime serviceDate;
  final DateTime issuedAt;

  /// Null when the booking recorded no vehicle — not "Unknown vehicle".
  final String? vehicle;
  final String paymentNote;

  factory BookingReceipt.fromJson(Map<String, dynamic> j) => BookingReceipt(
    receiptNumber: jsonString(j, 'receiptNumber'),
    bookingId: jsonString(j, 'bookingId'),
    amountPence: (j['amountPence'] as num).toInt(),
    currency: j['currency'] as String? ?? 'GBP',
    serviceType: BookingServiceType.fromWire(j['serviceType'] as String?),
    providerName: jsonString(j, 'providerName'),
    buyerName: jsonString(j, 'buyerName'),
    serviceDate: DateTime.parse(jsonString(j, 'serviceDate')),
    issuedAt: DateTime.parse(jsonString(j, 'issuedAt')),
    vehicle: j['vehicle'] as String?,
    paymentNote: jsonString(j, 'paymentNote'),
  );
}

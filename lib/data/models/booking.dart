import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/request_enums.dart';

/// The provider on a booking — `booking.electrician` on the wire.
///
/// Two names arrive: the account's [name] and the trade profile's
/// [fullName]. Choosing between them is presentation and lives in the widget
/// layer, as it does for OfferSupplier.
class BookingProvider {
  const BookingProvider({
    required this.id,
    this.name,
    this.fullName,
    this.headline,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String? name, fullName, headline;

  /// Only ever present on a booking, never in the directory: a buyer who has
  /// actually booked somebody may call them, but browsing must not hand out
  /// every provider's number.
  final String? phone;
  final String? avatarUrl;

  factory BookingProvider.fromJson(Map<String, dynamic> j) {
    final profile = j['electricianProfile'];
    final p = profile is Map ? profile : const {};
    return BookingProvider(
      id: jsonString(j, 'id'),
      name: j['name'] as String?,
      fullName: p['fullName'] as String?,
      headline: p['headline'] as String?,
      phone: p['phone'] as String?,
      avatarUrl: j['avatarUrl'] as String?,
    );
  }
}

/// The buyer on a booking — `booking.buyer` on the wire.
///
/// Holds id, name and avatarUrl from the server's projection.
class BookingBuyer {
  const BookingBuyer({required this.id, this.name, this.avatarUrl});

  final String id;
  final String? name;
  final String? avatarUrl;

  factory BookingBuyer.fromJson(Map<String, dynamic> j) => BookingBuyer(
        id: jsonString(j, 'id'),
        name: j['name'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
      );
}

/// One entry in a booking's status history.
/// The review left on a booking — `booking.reviews[]` on the wire.
///
/// REVIEWS ARE FINAL. The server has no update route and refuses a second
/// review of the same booking, so once this exists the app shows it read-only
/// rather than offering a button whose only outcome would be a 409.
class SubmittedReview {
  const SubmittedReview({
    required this.id,
    required this.authorId,
    required this.rating,
    required this.createdAt,
    this.text,
  });

  final String id;
  final String authorId;
  final int rating;
  final String? text;
  final DateTime createdAt;

  factory SubmittedReview.fromJson(Map<String, dynamic> j) => SubmittedReview(
    id: jsonString(j, 'id'),
    authorId: jsonString(j, 'authorId'),
    rating: (j['rating'] as num?)?.toInt() ?? 0,
    text: j['text'] as String?,
    createdAt: DateTime.parse(jsonString(j, 'createdAt')),
  );
}

class BookingEvent {
  const BookingEvent({required this.status, required this.at, this.note});

  final BookingStatus? status;
  final DateTime at;
  final String? note;

  factory BookingEvent.fromJson(Map<String, dynamic> j) => BookingEvent(
    status: BookingStatus.fromWire(j['status'] as String?),
    at: DateTime.parse(jsonString(j, 'at')),
    note: j['note'] as String?,
  );
}

/// An electrician callout — `POST /v1/bookings` and the three reads.
class Booking {
  const Booking({
    required this.id,
    required this.buyerId,
    required this.electricianId,
    required this.scheduledAt,
    required this.createdAt,
    required this.events,
    this.reviews = const [],
    this.receiptIssued = false,
    this.serviceType,
    this.status,
    this.region,
    this.regNumber,
    this.location,
    this.description,
    this.durationMins,
    this.quotedPence,
    this.finalPence,
    this.provider,
    this.buyer,
  });

  final String id, buyerId, electricianId;

  /// The chosen slot, as an instant. Rendered in the device's local zone —
  /// the server anchors the grid to Europe/London and sends UTC, so the two
  /// agree for a UK user and never disagree by accident.
  final DateTime scheduledAt;
  final DateTime createdAt;

  final BookingServiceType? serviceType;
  final BookingStatus? status;
  final Region? region;
  final String? regNumber, location, description;
  final int? durationMins;

  /// NULL UNTIL THE PROVIDER QUOTES. A buyer books a date and a service, never
  /// a price, so this is absent on every freshly created booking — 'no quote
  /// yet' rather than 'free'.
  final int? quotedPence;

  /// What the job ACTUALLY came to, set on completion. Kept beside
  /// [quotedPence] rather than overwriting it, because a buyer is owed the
  /// difference between what they were told and what they were charged.
  final int? finalPence;

  /// What this job was worth: what it came to, falling back to the quote.
  /// Null when NEITHER was recorded — not zero, which would read as free.
  int? get earnedPence => finalPence ?? quotedPence;

  final BookingProvider? provider;

  /// Present on both sides — the provider needs it, and the buyer simply gets
  /// their own name back.
  final BookingBuyer? buyer;

  final List<BookingEvent> events;

  /// Every review on this booking. In practice at most one, by the buyer.
  final List<SubmittedReview> reviews;

  /// Whether a receipt has been issued. Once true the price is LOCKED server
  /// side, so the provider app must not offer to change it.
  final bool receiptIssued;

  /// The buyer's own review, if they have left one — the thing that decides
  /// whether to show "Leave a review" or their review read-only.
  SubmittedReview? get buyerReview {
    for (final r in reviews) {
      if (r.authorId == buyerId) return r;
    }
    return null;
  }

  bool get isReviewed => buyerReview != null;

  /// Whether a receipt can be produced: the job is finished AND a price was
  /// recorded. Mirrors the server's rule so the button is only enabled when
  /// tapping it can succeed — the server stays the authority.
  bool get canHaveReceipt =>
      status == BookingStatus.completed && earnedPence != null;

  bool get isQuoted => quotedPence != null;

  /// Mirrors the server's rule so the UI does not offer a control that could
  /// only earn a 409. The server stays the authority.
  bool get canCancel => status?.isCancellable ?? false;

  /// Whether this booking is active and upcoming (not completed and not cancelled).
  bool get isUpcoming =>
      status != BookingStatus.completed &&
      status != BookingStatus.cancelled;

  /// Whether this booking is in a terminal state (completed or cancelled).
  bool get isTerminal =>
      status == BookingStatus.completed ||
      status == BookingStatus.cancelled;

  factory Booking.fromJson(Map<String, dynamic> j) {
    final provider = j['electrician'];
    final events = j['events'];
    return Booking(
      id: jsonString(j, 'id'),
      buyerId: jsonString(j, 'buyerId'),
      electricianId: jsonString(j, 'electricianId'),
      scheduledAt: DateTime.parse(jsonString(j, 'scheduledAt')),
      createdAt: DateTime.parse(jsonString(j, 'createdAt')),
      serviceType: BookingServiceType.fromWire(j['serviceType'] as String?),
      status: BookingStatus.fromWire(j['status'] as String?),
      region: Region.fromWire(j['region'] as String?),
      regNumber: j['regNumber'] as String?,
      location: j['location'] as String?,
      description: j['description'] as String?,
      durationMins: (j['durationMins'] as num?)?.toInt(),
      quotedPence: (j['quotedPence'] as num?)?.toInt(),
      finalPence: (j['finalPence'] as num?)?.toInt(),
      provider: provider is Map
          ? BookingProvider.fromJson(provider.cast<String, dynamic>())
          : null,
      buyer: j['buyer'] is Map
          ? BookingBuyer.fromJson((j['buyer'] as Map).cast<String, dynamic>())
          : null,
      events: events is List
          ? events
                .map((e) => BookingEvent.fromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false)
          : const <BookingEvent>[],
      reviews: j['reviews'] is List
          ? (j['reviews'] as List)
                .map((e) => SubmittedReview.fromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false)
          : const <SubmittedReview>[],
      // Presence is the signal; the server sends { number, issuedAt } or null.
      receiptIssued: j['receipt'] is Map,
    );
  }
}

/// One slot on a provider's day — `GET /v1/bookings/availability/{id}`.
class BookingSlot {
  const BookingSlot({
    required this.time,
    required this.scheduledAt,
    required this.available,
  });

  /// 'HH:MM' on a LONDON clock, computed server-side. Rendered verbatim
  /// rather than re-derived from [scheduledAt], so the label a buyer taps is
  /// the one the server means.
  final String time;

  /// Echoed back into `POST /v1/bookings` unchanged. Reconstructing the
  /// instant client-side is how a client and server end up disagreeing about
  /// what '09:00' meant in July.
  final DateTime scheduledAt;

  /// False when taken OR already past. The server folds both in, because to a
  /// buyer they are the same thing: not bookable.
  final bool available;

  factory BookingSlot.fromJson(Map<String, dynamic> j) => BookingSlot(
    time: jsonString(j, 'time'),
    scheduledAt: DateTime.parse(jsonString(j, 'scheduledAt')),
    available: j['available'] as bool? ?? false,
  );
}

/// A provider's day.
class DayAvailability {
  const DayAvailability({required this.date, required this.slots});

  final String date;
  final List<BookingSlot> slots;

  factory DayAvailability.fromJson(Map<String, dynamic> j) {
    final slots = j['slots'];
    return DayAvailability(
      date: jsonString(j, 'date'),
      slots: slots is List
          ? slots
                .map((e) => BookingSlot.fromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false)
          : const <BookingSlot>[],
    );
  }
}

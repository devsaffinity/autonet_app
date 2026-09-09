import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/provider_schedule.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';

class BookingsApiRepository implements BookingsRepository {
  /// [tokens] is accepted but not retained — see CatalogApiRepository for why
  /// every buyer repository takes the same pair.
  BookingsApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  /// The server 400s a limit above PAGINATION.MAX_LIMIT rather than clamping.
  static const int _maxLimit = 100;

  static Booking _one(Object? d) =>
      Booking.fromJson((d as Map).cast<String, dynamic>());

  @override
  Future<ApiResult<Booking>> create({
    required String electricianId,
    required BookingServiceType serviceType,
    required Region region,
    required DateTime scheduledAt,
    String? description,
    String? regNumber,
    String? location,
    int? durationMins,
  }) => _c.send(
    method: 'POST',
    path: '/v1/bookings',
    body: {
      'electricianId': electricianId,
      'serviceType': serviceType.wire,
      'region': region.wire,
      // UTC, always. The server reads the grid on a London clock; sending a
      // local-offset string would work by accident in winter and drift in
      // summer.
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      // Omitted rather than sent blank — each is `min(1).optional()`, so an
      // empty string is a 400 where an absent key is simply "not given".
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (regNumber != null && regNumber.trim().isNotEmpty)
        'regNumber': regNumber.trim(),
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
      // The server clamps this to 15..600 and 400s outside it, so a caller
      // sending something silly learns immediately rather than booking a
      // nine-hour diagnostic.
      if (durationMins != null) 'durationMins': durationMins,
    },
    decode: _one,
  );

  @override
  Future<ApiResult<DayAvailability>> availability({
    required String providerId,
    required String date,
  }) => _c.send(
    method: 'GET',
    path: '/v1/bookings/availability/$providerId',
    query: {'date': date},
    decode: (d) => DayAvailability.fromJson((d as Map).cast<String, dynamic>()),
  );

  static ProviderSchedule _schedule(Object? d) =>
      ProviderSchedule.fromJson((d as Map).cast<String, dynamic>());

  @override
  Future<ApiResult<ProviderSchedule>> schedule() =>
      _c.send(method: 'GET', path: '/v1/bookings/schedule', decode: _schedule);

  @override
  Future<ApiResult<ProviderSchedule>> setSchedule(
    Map<int, Set<AvailabilityBand>> byWeekday,
  ) => _c.send(
    method: 'PUT',
    path: '/v1/bookings/schedule',
    body: {
      // A weekday with NO bands is sent as an empty list rather than dropped,
      // and both mean the same thing to the server — but sending it keeps the
      // request a readable statement of the whole week rather than a set of
      // survivors, which is what makes a bad diff obvious in a log.
      //
      // Sorted so two identical schedules serialise identically; a Map's order
      // is insertion order, and a request that differs only in key order is a
      // needless difference to debug.
      'days': (byWeekday.keys.toList()..sort())
          .map(
            (weekday) => {
              'weekday': weekday,
              'bands': AvailabilityBand.values
                  .where((b) => byWeekday[weekday]!.contains(b))
                  .map((b) => b.wire)
                  .toList(),
            },
          )
          .toList(),
    },
    decode: _schedule,
  );

  @override
  Future<ApiResult<Paged<Booking>>> listMine({
    int page = 1,
    int limit = 20,
    BookingStatus? status,
  }) => _c.sendEnvelope(
    method: 'GET',
    path: '/v1/bookings',
    query: {
      'page': '${page < 1 ? 1 : page}',
      'limit': '${limit.clamp(1, _maxLimit)}',
      if (status != null) 'status': status.wire,
    },
    decode: Paged.decoder(Booking.fromJson),
  );

  @override
  Future<ApiResult<Booking>> byId(String id) =>
      _c.send(method: 'GET', path: '/v1/bookings/$id', decode: _one);

  /// Throws [ArgumentError] BEFORE the wire when neither price is given: the
  /// server's refine rejects an empty body, and a round trip to learn that is
  /// a round trip spent on a programming error.
  @override
  Future<ApiResult<Booking>> quote({
    required String id,
    int? quotedPence,
    int? finalPence,
    String? note,
  }) {
    if (quotedPence == null && finalPence == null) {
      throw ArgumentError('Provide quotedPence or finalPence');
    }
    final trimmed = note?.trim() ?? '';
    return _c.send(
      method: 'PATCH',
      path: '/v1/bookings/$id/quote',
      body: {
        if (quotedPence != null) 'quotedPence': quotedPence,
        if (finalPence != null) 'finalPence': finalPence,
        if (trimmed.isNotEmpty) 'note': trimmed,
      },
      decode: _one,
    );
  }

  /// Throws [ArgumentError] BEFORE the wire for the two statuses the server
  /// cannot accept here, because both are guaranteed 400s and a round trip
  /// would turn a programming error into a toast:
  ///   * PENDING is seeded by the create and is never a destination;
  ///   * CANCELLED has its own route, with a mandatory reason.
  ///
  /// Deliberately NOT `async`: throwing synchronously is what lets a caller
  /// prove no request was made at all.
  @override
  Future<ApiResult<Booking>> advance({
    required String id,
    required BookingStatus status,
    String? note,
  }) {
    if (status == BookingStatus.pending || status == BookingStatus.cancelled) {
      throw ArgumentError.value(
        status,
        'status',
        'Only CONFIRMED, IN_PROGRESS or COMPLETED are accepted here',
      );
    }
    final trimmed = note?.trim() ?? '';
    return _c.send(
      method: 'POST',
      path: '/v1/bookings/$id/status',
      body: {
        'status': status.wire,
        if (trimmed.isNotEmpty) 'note': trimmed,
      },
      decode: _one,
    );
  }

  @override
  Future<ApiResult<Booking>> cancel({
    required String id,
    required String note,
  }) => _c.send(
    method: 'POST',
    path: '/v1/bookings/$id/cancel',
    body: {'note': note.trim()},
    decode: _one,
  );
}

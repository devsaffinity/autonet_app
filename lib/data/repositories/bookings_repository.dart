import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/provider_schedule.dart';
import 'package:autonect/data/models/request_enums.dart';

/// `/v1/bookings`, for BOTH sides.
///
/// [listMine] serves whoever is signed in — the server branches on role, so a
/// buyer sees what they booked and a provider sees what they were booked for.
/// [advance] is the provider's alone and 403s for a buyer, but it lives here
/// rather than in a second repository because one app binary carries both
/// roles and the seam is the same route.
abstract class BookingsRepository {
  /// NO PRICE IS SENT. A buyer books a date and a service; the provider quotes
  /// after seeing the job, which is why `quotedPence` comes back null.
  ///
  /// [scheduledAt] must be a slot the availability endpoint returned — the
  /// server checks the instant lands on its grid, read on a London clock, and
  /// 400s anything else. Echo the slot's value; do not rebuild it.
  ///
  /// A 409 means somebody took the slot first. That is a real outcome, not an
  /// error to retry: re-read availability and let the buyer pick again.
  Future<ApiResult<Booking>> create({
    required String electricianId,
    required BookingServiceType serviceType,
    required Region region,
    required DateTime scheduledAt,
    String? description,
    String? regNumber,
    String? location,
    int? durationMins,
  });

  /// Which slots are free on one day. [date] is `YYYY-MM-DD`.
  Future<ApiResult<DayAvailability>> availability({
    required String providerId,
    required String date,
  });

  /// PROVIDER ONLY — the caller's own weekly working pattern. A buyer gets 403;
  /// they see its effect through [availability] and never the pattern itself.
  Future<ApiResult<ProviderSchedule>> schedule();

  /// PROVIDER ONLY — replace the whole week.
  ///
  /// SENT WHOLE, never patched a day at a time: a schedule is one statement,
  /// and a partial update invites a client that adds Monday morning without
  /// noticing it never removed Tuesday's. An omitted weekday means 'not
  /// working that day'.
  ///
  /// Sending nothing at all is 'I work nothing', which the server stores as no
  /// rows — and no rows is how it records 'never set', so the provider reads
  /// as fully available again rather than fully closed. Offer that as clearing
  /// the schedule, not as blocking the week.
  Future<ApiResult<ProviderSchedule>> setSchedule(
    Map<int, Set<AvailabilityBand>> byWeekday,
  );

  Future<ApiResult<Paged<Booking>>> listMine({
    int page = 1,
    int limit = 20,
    BookingStatus? status,
  });

  Future<ApiResult<Booking>> byId(String id);

  /// [note] is MANDATORY — the server requires a reason, and only PENDING or
  /// CONFIRMED can be cancelled. Past that the provider has travelled and
  /// started, and it is a dispute rather than a state change.
  Future<ApiResult<Booking>> cancel({required String id, required String note});

  /// PROVIDER ONLY — the price for a job.
  ///
  /// [quotedPence] is the estimate, settable once the provider has taken the
  /// work on; [finalPence] is what it came to and is only accepted on a
  /// COMPLETED booking. Both are kept, because a buyer is owed the difference
  /// between what they were told and what they were charged.
  ///
  /// Integer pence — no floats anywhere near money.
  Future<ApiResult<Booking>> quote({
    required String id,
    int? quotedPence,
    int? finalPence,
    String? note,
  });

  /// PROVIDER ONLY — a buyer calling this gets 403.
  ///
  /// Forward-only: PENDING -> CONFIRMED -> IN_PROGRESS -> COMPLETED. Skipping
  /// a step is a 409, because 'the job is done' has to mean somebody accepted
  /// it and turned up first. Declining is [cancel], not this: a decline is a
  /// cancellation with a reason, and the server treats it that way.
  Future<ApiResult<Booking>> advance({
    required String id,
    required BookingStatus status,
    String? note,
  });
}

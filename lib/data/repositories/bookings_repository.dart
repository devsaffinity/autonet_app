import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';

/// The buyer half of `/v1/bookings`.
///
/// `POST /v1/bookings/{id}/status` is deliberately absent: it is the
/// PROVIDER's forward-only machine, so a buyer client carrying it could only
/// ever earn a 403 — the same reason ReviewsRepository omits the reply route.
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
  });

  /// Which slots are free on one day. [date] is `YYYY-MM-DD`.
  Future<ApiResult<DayAvailability>> availability({
    required String providerId,
    required String date,
  });

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
}

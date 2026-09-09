import 'package:autonect/controller/base/paged_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:get/get.dart';

/// The PROVIDER's side of `GET /v1/bookings` — the work they were booked for.
///
/// The server branches on the caller's role, so this hits the same route the
/// buyer's My Bookings does and gets the other half of the data. Its own
/// controller rather than a flag on MyBookingsController: the two screens
/// filter differently, act differently, and can be on screen in the same app
/// session for a user who is both.
class ProviderBookingsController extends PagedController<Booking> {
  ProviderBookingsController(
    this._repo, {
    this.initialFilter,
    super.toast,
    super.showBusy,
    super.hideBusy,
  }) : filter = Rxn<BookingStatus>(initialFilter);

  final BookingsRepository _repo;

  /// What this instance opens on. The requests screen wants PENDING; the
  /// bookings screen wants everything.
  final BookingStatus? initialFilter;

  final Rxn<BookingStatus> filter;

  /// Registered per TAG, so the requests screen and the bookings screen can
  /// both exist without one resetting the other's filter — `ensure()` with a
  /// single instance would hand the second screen the first one's rows.
  static ProviderBookingsController ensure({BookingStatus? initialFilter}) {
    final tag = initialFilter?.wire ?? 'all';
    return Get.isRegistered<ProviderBookingsController>(tag: tag)
        ? Get.find<ProviderBookingsController>(tag: tag)
        : Get.put(
            ProviderBookingsController(
              Get.find<BookingsRepository>(),
              initialFilter: initialFilter,
            ),
            tag: tag,
          );
  }

  Future<void> setFilter(BookingStatus? status) {
    if (filter.value == status) return Future<void>.value();
    filter.value = status;
    return refreshForFilter();
  }

  /// Accept, start, or complete — the forward-only machine.
  ///
  /// Re-reads page one rather than patching the row: advancing can move a
  /// booking OUT of the current filter, and a CONFIRMED booking left sitting
  /// under the Pending tab is the screen lying about what it is showing.
  Future<bool> advance(Booking booking, BookingStatus status, {String? note}) async {
    var ok = false;
    await run<Booking, void>(
      null,
      () => _repo.advance(id: booking.id, status: status, note: note),
      (r) {
        switch (r) {
          case Err():
            break;
          case Ok():
            ok = true;
        }
      },
    );
    if (ok) await refreshFirst();
    return ok;
  }

  /// Declining is a CANCELLATION with a reason, not a status advance — which
  /// is exactly how the server models it, so the client must not invent a
  /// separate verb for it.
  Future<bool> decline(Booking booking, String reason) async {
    var ok = false;
    await run<Booking, void>(
      null,
      () => _repo.cancel(id: booking.id, note: reason),
      (r) {
        switch (r) {
          case Err():
            break;
          case Ok():
            ok = true;
        }
      },
    );
    if (ok) await refreshFirst();
    return ok;
  }

  /// The next step this booking can take, or null when it is finished.
  ///
  /// Mirrors PROVIDER_FORWARD_TRANSITIONS on the server so the UI offers one
  /// button rather than a menu of things that would 409.
  static BookingStatus? nextStep(BookingStatus? current) => switch (current) {
    BookingStatus.pending => BookingStatus.confirmed,
    BookingStatus.confirmed => BookingStatus.inProgress,
    BookingStatus.inProgress => BookingStatus.completed,
    _ => null,
  };

  /// What that button should say.
  static String? nextStepLabel(BookingStatus? current) => switch (current) {
    BookingStatus.pending => 'Accept request',
    BookingStatus.confirmed => 'Start job',
    BookingStatus.inProgress => 'Mark completed',
    _ => null,
  };

  @override
  Future<ApiResult<Paged<Booking>>> fetchPage(int page) =>
      _repo.listMine(page: page, status: filter.value);

  @override
  String idOf(Booking item) => item.id;
}

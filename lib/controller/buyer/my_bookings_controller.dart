import 'package:autonect/controller/base/paged_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:get/get.dart';

/// `GET /v1/bookings` — the buyer's own callouts, newest slot first.
class MyBookingsController extends PagedController<Booking> {
  MyBookingsController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final BookingsRepository _repo;

  static MyBookingsController ensure() =>
      Get.isRegistered<MyBookingsController>()
      ? Get.find<MyBookingsController>()
      : Get.put(MyBookingsController(Get.find<BookingsRepository>()));

  /// null is the 'All' chip; the repository then omits the key entirely.
  final Rxn<BookingStatus> filter = Rxn<BookingStatus>();

  /// IN_PROGRESS is absent on purpose: it is a state a booking passes through
  /// in an afternoon, and a filter chip that is empty almost every day is
  /// noise. The rows still render it.
  static const List<SelectOption<BookingStatus?>> filterOptions = [
    SelectOption<BookingStatus?>(null, 'All'),
    SelectOption<BookingStatus?>(BookingStatus.pending, 'Pending'),
    SelectOption<BookingStatus?>(BookingStatus.confirmed, 'Confirmed'),
    SelectOption<BookingStatus?>(BookingStatus.completed, 'Completed'),
    SelectOption<BookingStatus?>(BookingStatus.cancelled, 'Cancelled'),
  ];

  Future<void> setFilter(BookingStatus? status) {
    if (filter.value == status) return Future<void>.value();
    filter.value = status;
    return refreshForFilter();
  }

  /// Cancels, then re-reads page one.
  ///
  /// Not an in-place row edit: cancelling can move a booking OUT of the
  /// current filter, and patching the row would leave a Cancelled booking
  /// sitting under the Confirmed chip.
  Future<bool> cancel(Booking booking, String note) async {
    var ok = false;
    await run<Booking, void>(
      null,
      () => _repo.cancel(id: booking.id, note: note),
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

  @override
  Future<ApiResult<Paged<Booking>>> fetchPage(int page) =>
      _repo.listMine(page: page, status: filter.value);

  @override
  String idOf(Booking item) => item.id;
}

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// `YYYY-MM-DD` for the availability query, built from a LOCAL date.
///
/// Not `toIso8601String().substring(0, 10)`, which converts to UTC first and
/// therefore names yesterday for anyone booking after midnight in a positive
/// offset. The user picked a square on a calendar; that square is what travels.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// The New Booking screen: pick a day, pick a slot, say what is wrong.
///
/// Deliberately NOT persisted the way the part-request draft is. That wizard
/// spans three screens and a DVLA lookup, so losing it hurts; this is one
/// screen, and a restored booking draft could hold a slot that somebody else
/// has since taken.
class NewBookingController extends ApiController {
  NewBookingController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final BookingsRepository _repo;

  static NewBookingController ensure() =>
      Get.isRegistered<NewBookingController>()
      ? Get.find<NewBookingController>()
      : Get.put(NewBookingController(Get.find<BookingsRepository>()));

  static const StateSlot _availabilityRead = StateSlot('bookingAvailability');

  /// The day whose slots are shown.
  final Rx<DateTime> selectedDay = DateTime.now().obs;

  /// The chosen slot, held WHOLE rather than as a time string: its
  /// `scheduledAt` is echoed back to the server unchanged, and rebuilding
  /// that instant client-side is how the two ends disagree about what '09:00'
  /// meant in July.
  final Rxn<BookingSlot> selectedSlot = Rxn<BookingSlot>();

  final Rx<ViewState<List<BookingSlot>>> slots =
      Rx<ViewState<List<BookingSlot>>>(const Loading());

  final Rxn<BookingServiceType> serviceType = Rxn<BookingServiceType>();

  /// The booking that came back, so the confirmation screen renders the
  /// server's row rather than what we hoped we sent.
  final Rxn<Booking> created = Rxn<Booking>();

  String? _providerId;
  Region? _region;

  /// The provider's own premises, shown as the Service Location and sent with
  /// the booking so it is recorded on the row rather than only on screen.
  String? providerLocation;

  /// Seeds from the provider being booked. [services] decides the default
  /// callout — the first one they offer, which is what the profile's CTA
  /// named, so the two screens agree.
  void start(ServiceProvider provider) {
    _providerId = provider.id;
    _region = provider.region;
    providerLocation = provider.location;
    serviceType.value = provider.services.isEmpty ? null : provider.services.first;
    selectedSlot.value = null;
    created.value = null;
    // Today, so a buyer who wants the soonest slot does not have to navigate.
    selectedDay.value = DateTime.now();
    loadSlots();
  }

  Future<void> selectDay(DateTime day) {
    selectedDay.value = day;
    // A slot chosen on another day is meaningless now, and leaving it set
    // would let Confirm submit an instant the buyer can no longer see.
    selectedSlot.value = null;
    return loadSlots();
  }

  Future<void> loadSlots() {
    final id = _providerId;
    if (id == null) return Future<void>.value();
    slots.value = const Loading();
    return runRead(
      _availabilityRead,
      () => _repo.availability(providerId: id, date: isoDate(selectedDay.value)),
      (r) {
        switch (r) {
          case Err(:final error):
            slots.value = Failed<List<BookingSlot>>(error);
          case Ok(:final value):
            slots.value = value.slots.isEmpty
                ? const Empty<List<BookingSlot>>(
                    'No slots that day',
                    'Try another date.',
                  )
                : Data<List<BookingSlot>>(value.slots);
        }
      },
    );
  }

  bool get canSubmit =>
      _providerId != null &&
      _region != null &&
      serviceType.value != null &&
      selectedSlot.value != null;

  /// Returns the created booking, or null when it failed.
  ///
  /// Goes through [run], not [runRead]: this is a WRITE, and a double tap
  /// must be dropped rather than superseded — two bookings are not the same
  /// mistake as two reads.
  Future<Booking?> submit({String? description, String? regNumber}) async {
    if (!canSubmit) return null;
    Booking? result;
    await run<Booking, void>(
      null,
      () => _repo.create(
        electricianId: _providerId!,
        serviceType: serviceType.value!,
        region: _region!,
        scheduledAt: selectedSlot.value!.scheduledAt,
        description: description,
        regNumber: regNumber,
        location: providerLocation,
        durationMins: serviceType.value!.typicalMinutes,
      ),
      (r) {
        switch (r) {
          case Err():
            // The toast already told them. A 409 here means the slot went to
            // somebody else while the form was open, so the slots are re-read
            // rather than left showing one that is gone.
            loadSlots();
          case Ok(:final value):
            created.value = value;
            result = value;
        }
      },
    );
    return result;
  }
}

import 'dart:typed_data';

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_receipt.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/services/receipt_pdf.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

/// Hands a finished PDF to the platform — the share sheet, from which the
/// customer can save it to Files, print it, or send it on.
typedef ReceiptSharer =
    Future<void> Function(Uint8List bytes, String filename);

Future<void> _platformShare(Uint8List bytes, String filename) =>
    Printing.sharePdf(bytes: bytes, filename: filename);

/// Produce a booking's receipt as a PDF and offer it to the customer.
///
/// THREE STEPS, and each can fail on its own: ask the server for the receipt,
/// render it, hand it to the platform. The server answer is the only one that
/// can say NO for a reason worth reading — the job is not finished, or no
/// price was recorded — so those reach the customer in the server's words.
///
/// [share] is injectable for the same reason every repository here is an
/// interface: a test must run without a platform channel.
class ReceiptController extends ApiController {
  ReceiptController(
    this._repo, {
    ReceiptSharer? share,
    super.toast,
    super.showBusy,
    super.hideBusy,
  }) : _share = share ?? _platformShare;

  final BookingsRepository _repo;
  final ReceiptSharer _share;

  static ReceiptController ensure() => Get.isRegistered<ReceiptController>()
      ? Get.find<ReceiptController>()
      : Get.put(ReceiptController(Get.find<BookingsRepository>()));

  /// The booking whose receipt is being produced, so a card can show a
  /// spinner on ITS button without greying out every other card's.
  final RxnString working = RxnString();

  /// The last receipt produced, kept so a test — or a future 'share again'
  /// — does not need a second round trip.
  final Rxn<BookingReceipt> last = Rxn<BookingReceipt>();

  /// Returns true when the customer was shown the receipt.
  Future<bool> open(Booking booking) async {
    // Checked before the network: the button should already be disabled for a
    // booking that cannot have one, so reaching here means a stale screen.
    // Saying why beats a round trip that can only 409.
    if (!booking.canHaveReceipt) {
      toast(
        booking.status?.wire == 'COMPLETED'
            ? 'A receipt is available once your provider records the price.'
            : 'A receipt is available once the job is completed.',
      );
      return false;
    }
    if (working.value != null) return false; // one at a time; a double tap does nothing

    working.value = booking.id;
    try {
      final result = await _repo.receipt(booking.id);
      switch (result) {
        case Err(:final error):
          // userMessageFor shows a 409's server message as written, which is
          // the useful one here: "not completed" or "no price recorded".
          toast(userMessageFor(error));
          return false;
        case Ok(:final value):
          last.value = value;
          final bytes = await ReceiptPdf.build(value);
          await _share(bytes, ReceiptPdf.fileName(value));
          return true;
      }
    } catch (_) {
      // Rendering or the platform share failed after the server said yes. The
      // receipt still exists server-side and the next tap will fetch the same
      // one, so this is safe to retry.
      toast('Could not open the receipt. Please try again.');
      return false;
    } finally {
      working.value = null;
    }
  }
}

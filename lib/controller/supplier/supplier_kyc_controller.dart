import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/blob_uploader.dart';
import 'package:autonect/data/models/kyc_status.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/repositories/kyc_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/services/document_picker_service.dart';
import 'package:get/get.dart';

/// The KYC step: three documents, each picked, uploaded and confirmed.
///
/// Upload is THREE round trips per document — ticket, PUT to S3, confirm — and
/// only the last one tells the server the file is real. A failure between the
/// second and third leaves an object in the bucket that no row calls uploaded,
/// which is why the screen always re-renders from the server's answer rather
/// than from what it just did.
class SupplierKycController extends ApiController {
  SupplierKycController(
    this._repo,
    this._uploader,
    this._picker, {
    super.toast,
    super.showBusy,
    super.hideBusy,
  });

  static SupplierKycController ensure() =>
      Get.isRegistered<SupplierKycController>()
      ? Get.find<SupplierKycController>()
      : Get.put(
          SupplierKycController(
            Get.find<KycRepository>(),
            Get.find<BlobUploader>(),
            Get.find<DocumentPickerService>(),
          ),
        );

  final KycRepository _repo;
  final BlobUploader _uploader;
  final DocumentPickerService _picker;

  static const StateSlot _statusRead = StateSlot('kycStatus');

  final Rx<ViewState<KycState>> state = Rx<ViewState<KycState>>(
    const Loading(),
  );

  /// Which document is mid-upload, so only THAT card shows a spinner. A single
  /// global busy flag would blank all three.
  final Rxn<KycDocType> uploading = Rxn<KycDocType>();

  /// Which document has the system file sheet open.
  ///
  /// SEPARATE from [uploading] on purpose. The picker await used to sit outside
  /// any latch at all, so two taps in the ~300ms before the sheet appears both
  /// called into file_picker, whose Android delegate answers the second with
  /// `already_active` — an uncaught async error, swallowed in release. Reusing
  /// [uploading] for it would fix that but make the card claim an upload is in
  /// flight for as long as the sheet is open, then snap back on cancel.
  final Rxn<KycDocType> picking = Rxn<KycDocType>();

  /// Any document operation in flight. One at a time across ALL cards: the
  /// backend deletes the previous row inside the ticket call, so overlapping
  /// operations on the same type can leave a row pointing at nothing.
  bool get isLatched => uploading.value != null || picking.value != null;

  KycState? get current => switch (state.value) {
    Data<KycState>(:final value) => value,
    _ => null,
  };

  bool get isComplete => current?.isComplete ?? false;

  Future<void> load() => runRead(_statusRead, _repo.status, (r) {
    switch (r) {
      case Err(:final error):
        state.value = Failed<KycState>(error);
      case Ok(:final value):
        state.value = Data<KycState>(value);
    }
  });

  /// Pick → ticket → PUT → confirm.
  ///
  /// Every early return leaves [uploading] cleared, which is why the whole body
  /// sits in a try/finally: an exception on any of the three calls would
  /// otherwise strand that card in a permanent spinner with no way back.
  Future<void> pickAndUpload(KycDocType type) async {
    if (isLatched) {
      // Never a bare return: every caller is a control the user just tapped,
      // and silence reads as a broken button.
      toast('Wait for the current document to finish.');
      return;
    }

    final DocumentPickResult picked;
    picking.value = type;
    try {
      picked = await _picker.pickDocument();
    } finally {
      picking.value = null;
    }

    final doc = picked.document;
    if (doc == null) {
      // Backing out of the system sheet is not an error.
      if (!picked.isCancelled) toast(_pickFailureMessage(picked.failure!));
      return;
    }

    // Re-checked AFTER the pick, not just before it: a remove() on this or
    // another card can start and finish while the sheet is open, and uploading
    // on top of it races a DELETE against an INSERT.
    if (uploading.value != null) {
      toast('Wait for the current document to finish.');
      return;
    }

    uploading.value = type;
    // A failure from a previous attempt must not sit under a new one.
    clearErrors();
    try {
      final UploadTicket ticket;
      switch (await _repo.createUploadTicket(
        KycUploadRequest(
          type: type,
          contentType: doc.contentType,
          sizeBytes: doc.sizeBytes,
          fileName: doc.fileName,
        ),
      )) {
        // EVERY failure arm re-reads. The ticket call DELETES the previous
        // document and its S3 object before a single byte moves, so a failure
        // after it means the card is now showing a file the server no longer
        // has — and `isComplete` would keep Next enabled over the hole.
        // load() goes through runRead, which does not clearErrors, so the
        // message set by absorb survives the reload.
        case Err(:final error):
          absorb(error);
          await load();
          return;
        case Ok(:final value):
          ticket = value;
      }

      switch (await _uploader.put(
        url: ticket.url,
        bytes: doc.bytes,
        contentType: doc.contentType,
      )) {
        case Err(:final error):
          absorb(error);
          await load();
          return;
        case Ok():
          break;
      }

      // The ONLY call that makes the upload count. Its answer replaces the
      // whole screen state, so a document the server rejected on re-read never
      // renders as uploaded.
      switch (await _repo.confirmUpload(ticket.key)) {
        case Err(:final error):
          absorb(error);
          await load();
        case Ok(:final value):
          state.value = Data<KycState>(value);
      }
    } finally {
      uploading.value = null;
    }
  }

  Future<void> remove(KycDocType type) async {
    if (isLatched) {
      toast('Wait for the current document to finish.');
      return;
    }
    uploading.value = type;
    clearErrors();
    try {
      switch (await _repo.removeDocument(type)) {
        case Err(:final error):
          absorb(error);
          await load();
        case Ok(:final value):
          state.value = Data<KycState>(value);
      }
    } finally {
      uploading.value = null;
    }
  }

  String _pickFailureMessage(DocumentPickFailure f) => switch (f) {
    DocumentPickFailure.tooLarge => 'That file is over the 10 MB limit.',
    DocumentPickFailure.unsupportedType =>
      'Documents must be a PDF, JPEG or PNG.',
    DocumentPickFailure.unreadable => 'That file could not be read.',
    DocumentPickFailure.cancelled => '',
  };
}


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
  SupplierKycController(this._repo, this._uploader, this._picker);

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
    if (uploading.value != null) return;

    final picked = await _picker.pickDocument();
    final doc = picked.document;
    if (doc == null) {
      // Backing out of the system sheet is not an error.
      if (!picked.isCancelled) toast(_pickFailureMessage(picked.failure!));
      return;
    }

    uploading.value = type;
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
        case Err(:final error):
          absorb(error);
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
          return;
        case Ok():
          break;
      }

      // The ONLY call that makes the upload count. Its answer replaces the
      // whole screen state, so a document the server rejected on re-read never
      // renders as uploaded.
      final confirmed = await _repo.confirmUpload(ticket.key);
      switch (confirmed) {
        case Err(:final error):
          absorb(error);
        case Ok(:final value):
          state.value = Data<KycState>(value);
      }
    } finally {
      uploading.value = null;
    }
  }

  Future<void> remove(KycDocType type) async {
    if (uploading.value != null) return;
    uploading.value = type;
    try {
      final r = await _repo.removeDocument(type);
      switch (r) {
        case Err(:final error):
          absorb(error);
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


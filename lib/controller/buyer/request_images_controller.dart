import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/blob_uploader.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/requests_repository.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/pending_image.dart';
import 'package:autonect/services/image_picker_service.dart';
import 'package:get/get.dart';

/// The wizard's image tray. A PLAIN class owned by NewRequestController, not a
/// GetxController: it needs no lifecycle of its own, and staying off GetX is
/// what lets every upload path be unit-tested with no Get container at all.
class RequestImagesController {
  RequestImagesController({
    required RequestsRepository requests,
    required BlobUploader uploader,
    required ImagePickerService picker,
    this.onChanged,
  }) : _requests = requests,
       _uploader = uploader,
       _picker = picker;

  final RequestsRepository _requests;
  final BlobUploader _uploader;
  final ImagePickerService _picker;

  /// Persists the owning draft. Called on every terminal per-image transition,
  /// because the s3Key it writes is the one thing that cannot be recreated.
  final void Function()? onChanged;

  final RxList<PendingImage> slots = <PendingImage>[].obs;
  final RxnString rejectionMessage = RxnString();

  bool _uploading = false;
  int _nextLocalId = 0;

  List<String> get readyKeys => [
    for (final s in slots)
      if (s.status == ImageUploadStatus.uploaded) ?s.s3Key,
  ];

  int get pendingCount => slots
      .where((s) => s.status != ImageUploadStatus.uploaded)
      .length;

  /// Re-points the tray at a restored draft's slots so the two never diverge.
  void adopt(List<PendingImage> existing) {
    slots.assignAll(existing);
    _nextLocalId = slots.length;
  }

  Future<void> addFromPicker() async {
    final remaining = kMaxRequestImages - slots.length;
    // Returning BEFORE the picker is what makes a sixth photo cost nothing:
    // no sheet, no read, no ticket.
    if (remaining <= 0) return;
    rejectionMessage.value = null;
    final picked = await _picker.pick(remaining: remaining);
    var rejected = 0;
    for (final p in picked) {
      if (slots.length >= kMaxRequestImages) break;
      // ImagePickerService is a seam, so this is the last place the server's
      // two hard rules can be enforced before a ticket is minted against them.
      if (p.sizeBytes > kMaxImageBytes ||
          !kImageMimeTypes.contains(p.contentType)) {
        rejected++;
        continue;
      }
      slots.add(
        PendingImage(
          localId: 'img${_nextLocalId++}',
          path: p.path,
          sizeBytes: p.sizeBytes,
          contentType: p.contentType,
          bytes: p.bytes,
        ),
      );
    }
    if (rejected > 0) {
      rejectionMessage.value =
          'Skipped $rejected photo(s): use JPG, PNG or WebP under 5 MB.';
    }
    onChanged?.call();
  }

  /// SEQUENTIAL, one image at a time. Five concurrent PUTs on a weak connection
  /// contend and fail together; in series image 5 still succeeds after image 4
  /// failed, and the progress the tray shows is the truth.
  Future<void> uploadAll() async {
    if (_uploading) return;
    _uploading = true;
    try {
      for (final img in slots.toList(growable: false)) {
        if (img.status == ImageUploadStatus.uploaded) continue;
        await _uploadOne(img);
      }
    } finally {
      _uploading = false;
    }
  }

  /// Mints a FRESH ticket and therefore a fresh key. Replaying the old one is a
  /// P2002 on `RequestImage.s3Key @unique` -> 409 'Resource already exists'.
  Future<void> retry(String localId) async {
    if (_uploading) return;
    final img = _find(localId);
    if (img == null || img.status == ImageUploadStatus.uploaded) return;
    _uploading = true;
    try {
      img.s3Key = null;
      await _uploadOne(img);
    } finally {
      _uploading = false;
    }
  }

  void remove(String localId) {
    slots.removeWhere((s) => s.localId == localId);
    onChanged?.call();
  }

  PendingImage? _find(String localId) {
    for (final s in slots) {
      if (s.localId == localId) return s;
    }
    return null;
  }

  Future<void> _uploadOne(PendingImage img) async {
    final bytes = img.bytes;
    if (bytes == null) {
      _fail(img, 'That photo is no longer available on this device.');
      return;
    }
    img.status = ImageUploadStatus.uploading;
    img.errorMessage = null;
    slots.refresh();
    // Minted here rather than at wizard start: the presigned URL lives about
    // 300 seconds, which a buyer spends easily on step 2 alone.
    final ticket = await _requests.createImageUploadTicket(img.contentType);
    switch (ticket) {
      case Err(:final error):
        _fail(img, userMessageFor(error));
      case Ok(:final value):
        final put = await _uploader.put(
          url: value.url,
          bytes: bytes,
          contentType: img.contentType,
        );
        switch (put) {
          case Err(:final error):
            _fail(img, userMessageFor(error));
          case Ok():
            img.status = ImageUploadStatus.uploaded;
            img.s3Key = value.key;
            img.errorMessage = null;
            slots.refresh();
            onChanged?.call();
        }
    }
  }

  /// Failure is per image and never aborts the run: submit is not gated on
  /// uploads, so 3-of-4 uploaded still ships.
  void _fail(PendingImage img, String message) {
    img.status = ImageUploadStatus.failed;
    img.errorMessage = message;
    slots.refresh();
    onChanged?.call();
  }
}

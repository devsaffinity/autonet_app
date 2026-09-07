import 'package:file_picker/file_picker.dart';

/// The maximum a KYC document may be, mirroring the server's
/// `UPLOAD.DOCUMENT_MAX_BYTES`.
///
/// Enforced here as well as server-side because the server only learns the real
/// size AFTER the bytes have crossed the network — rejecting a 40 MB scan
/// locally saves the provider an upload that was always going to fail.
const int kMaxDocumentBytes = 10 * 1024 * 1024;

/// One document the provider chose, validated against everything the server
/// checks.
class PickedDocument {
  const PickedDocument({
    required this.bytes,
    required this.contentType,
    required this.sizeBytes,
    required this.fileName,
  });

  final List<int> bytes;

  /// EXACTLY one of `application/pdf`, `image/jpeg`, `image/png`. The server's
  /// allowlist is a case-sensitive zod enum, so 'image/jpg' or 'IMAGE/PNG' is
  /// a 400.
  final String contentType;
  final int sizeBytes;

  /// Display only — it never becomes part of the S3 key, which the server
  /// generates.
  final String fileName;
}

/// Why a pick produced no document. The KYC screen shows one document at a
/// time, so unlike the multi-image tray it can and should say what went wrong.
enum DocumentPickFailure {
  /// The provider backed out of the system sheet. Not an error; say nothing.
  cancelled,

  /// Right kind of file, too big.
  tooLarge,

  /// Not a PDF, JPEG or PNG.
  unsupportedType,

  /// The platform handed back a name but no readable bytes.
  unreadable,
}

/// Exactly one of [document] or [failure] is non-null.
class DocumentPickResult {
  const DocumentPickResult.picked(this.document) : failure = null;
  const DocumentPickResult.failed(this.failure) : document = null;

  final PickedDocument? document;
  final DocumentPickFailure? failure;

  bool get isCancelled => failure == DocumentPickFailure.cancelled;
}

/// The seam controllers and their tests depend on; only the implementation
/// below knows the picker plugin exists.
abstract class DocumentPickerService {
  Future<DocumentPickResult> pickDocument();
}

/// THE ONLY file in the app permitted to import package:file_picker, mirroring
/// the SessionStore/shared_preferences and ImagePickerService fences.
class DeviceDocumentPickerService implements DocumentPickerService {
  const DeviceDocumentPickerService();

  /// From the file extension, never an OS-reported MIME. Android content
  /// providers report 'image/jpg' and sometimes
  /// 'application/octet-stream' for a PDF, both of which the server rejects.
  static const Map<String, String> _mimeByExtension = {
    'pdf': 'application/pdf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
  };

  @override
  Future<DocumentPickResult> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _mimeByExtension.keys.toList(),
      // The bytes are PUT straight to S3 and never touched as a File, and on
      // web there is no path at all.
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null) {
      return const DocumentPickResult.failed(DocumentPickFailure.cancelled);
    }

    // allowedExtensions is advisory on some platforms — Android's document UI
    // will hand back whatever the provider offers — so re-check rather than
    // trusting the filter.
    final type = _mimeByExtension[_extensionOf(file.name)];
    if (type == null) {
      return const DocumentPickResult.failed(
        DocumentPickFailure.unsupportedType,
      );
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return const DocumentPickResult.failed(DocumentPickFailure.unreadable);
    }
    if (bytes.length > kMaxDocumentBytes) {
      return const DocumentPickResult.failed(DocumentPickFailure.tooLarge);
    }

    return DocumentPickResult.picked(
      PickedDocument(
        bytes: bytes,
        contentType: type,
        sizeBytes: bytes.length,
        fileName: file.name,
      ),
    );
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

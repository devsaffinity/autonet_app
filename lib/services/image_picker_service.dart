import 'package:autonect/data/models/request_enums.dart' show kMaxImageBytes;
import 'package:image_picker/image_picker.dart';

/// One image the buyer chose, already validated against everything the server
/// checks plus the one thing it does not (size).
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.contentType,
    required this.sizeBytes,
    required this.path,
  });

  final List<int> bytes;

  /// EXACTLY one of `image/jpeg`, `image/png`, `image/webp`. The server's
  /// allowlist is case-sensitive and untrimmed, so 'image/jpg' is a 400.
  final String contentType;
  final int sizeBytes;
  final String path;
}

/// The seam controllers and their tests depend on; only the implementation
/// below knows the picker plugin exists.
abstract class ImagePickerService {
  /// [remaining] is how many slots are still free, so the sheet can never hand
  /// back a sixth photo for a five-photo request.
  Future<List<PickedImage>> pick({required int remaining});
}

/// THE ONLY file in the app permitted to import package:image_picker,
/// mirroring the SessionStore/shared_preferences fence.
class DeviceImagePickerService implements ImagePickerService {
  DeviceImagePickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// From the file extension, never an OS-reported MIME: the value must be one
  /// of three exact strings, and some Android providers report 'image/jpg'.
  static const Map<String, String> _mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// Unusable files are dropped silently: the contract is "the images you can
  /// send", and a per-file reason would need a second shape across this seam.
  @override
  Future<List<PickedImage>> pick({required int remaining}) async {
    if (remaining <= 0) return const [];
    // limit: 1 is rejected by the multi-image options on some plugin versions,
    // so the last free slot goes through the single-image path.
    final files = remaining == 1
        ? <XFile>[?await _picker.pickImage(source: ImageSource.gallery)]
        : await _picker.pickMultiImage(limit: remaining);

    final out = <PickedImage>[];
    for (final f in files) {
      if (out.length >= remaining) break;
      final type = _mimeByExtension[_extensionOf(f.path)];
      if (type == null) continue;
      final bytes = await f.readAsBytes();
      // The server hands IMAGE_MAX_BYTES to the signer but only writes it as S3
      // metadata, so this is the only place the 5 MiB cap is enforced at all.
      if (bytes.length > kMaxImageBytes) continue;
      out.add(
        PickedImage(
          bytes: bytes,
          contentType: type,
          sizeBytes: bytes.length,
          path: f.path,
        ),
      );
    }
    return out;
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
  }
}

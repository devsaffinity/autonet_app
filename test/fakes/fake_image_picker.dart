import 'package:autonect/services/image_picker_service.dart';

/// Hands back exactly what a test scripted, INCLUDING files the real device
/// picker would have filtered out. That is the point: the tray is the last
/// place the server's size and MIME rules can be enforced, and a fake that
/// pre-filtered would make that check untestable.
class FakeImagePickerService implements ImagePickerService {
  final List<PickedImage> next = [];
  int calls = 0;
  int? lastRemaining;

  @override
  Future<List<PickedImage>> pick({required int remaining}) async {
    calls++;
    lastRemaining = remaining;
    return List<PickedImage>.from(next);
  }

  /// A 1 KB JPEG unless overridden.
  static PickedImage image({
    String path = 'a.jpg',
    String contentType = 'image/jpeg',
    int sizeBytes = 1024,
  }) => PickedImage(
    bytes: List<int>.filled(4, 7),
    contentType: contentType,
    sizeBytes: sizeBytes,
    path: path,
  );
}

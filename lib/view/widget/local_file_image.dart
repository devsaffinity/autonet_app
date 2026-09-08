library;

/// Renders an image from a LOCAL FILE PATH, on the platforms that have files.
///
/// This exists so nothing else in `lib/` imports `dart:io`. That import does not
/// compile for web at all, and it had spread here for one reason: the wizard's
/// photo strip paints a restored draft from disk.
///
/// `PendingImage.bytes` is deliberately not persisted (up to 5 MB an image), so
/// after the OS reclaims the wizard the only thing left is the path — which is
/// why this cannot simply become `Image.memory` everywhere. Freshly picked
/// images DO carry bytes and should use those; this is the restore path.
///
/// On web the stub renders a placeholder: a browser has no path to re-read, and
/// the draft's blob URL does not survive a reload either.
export 'package:autonect/view/widget/local_file_image_stub.dart'
    if (dart.library.io) 'package:autonect/view/widget/local_file_image_io.dart';

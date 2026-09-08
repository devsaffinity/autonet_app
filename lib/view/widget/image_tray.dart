import 'dart:typed_data';

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/data/models/request_enums.dart' show kMaxRequestImages;
import 'package:autonect/domain/pending_image.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

const double _tile = 88;

/// The wizard's photo strip. Callbacks only — it holds no repository, does no
/// upload and knows nothing about S3; the controller owns all of that and
/// hands this widget the current [PendingImage] list to paint.
///
/// CALLERS: [images] is read in THIS widget's `build`, NOT in the `Obx` closure
/// that constructed the tray. Pass an `RxList` here bare and it subscribes to
/// nothing — there is no `.value` to spot, so the tray simply stops repainting:
/// the second photo never appears, an X leaves its tile, and no upload spinner
/// ever spins. READ the collection inside the Obx closure and pass the plain
/// snapshot down — `slots.toList(growable: false)`. Same rule as `StateView`'s
/// builder, and it applies to any reactive collection handed to any child.
class ImageTray extends StatelessWidget {
  const ImageTray({
    super.key, required this.images, required this.onAdd,
    required this.onRemove, required this.onRetry,
  });

  final List<PendingImage> images;
  final VoidCallback onAdd;

  /// Both keyed by [PendingImage.localId], never by list index: removing a
  /// tile while another uploads would shift every index after it.
  final ValueChanged<String> onRemove, onRetry;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSizes.s8,
    runSpacing: AppSizes.s8,
    children: [
      for (final image in images)
        _Tile(image: image, onRemove: onRemove, onRetry: onRetry),
      if (images.length < kMaxRequestImages)
        _AddTile(onTap: onAdd, remaining: kMaxRequestImages - images.length),
    ],
  );
}

/// A translucent cover for the in-flight and failed states. A function rather
/// than a widget class: it has no identity worth giving the element tree.
Widget _scrim(Widget child) => DecoratedBox(
  decoration: BoxDecoration(
    color: kBlackColor.withValues(alpha: .45),
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
  ),
  child: Center(child: child),
);

class _Tile extends StatelessWidget {
  const _Tile({required this.image, required this.onRemove,
      required this.onRetry});

  final PendingImage image;
  final ValueChanged<String> onRemove, onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _tile,
    height: _tile,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          // Freshly picked images carry their bytes, which renders identically
          // on every platform. A RESTORED draft does not — bytes are too large
          // to persist — so that path falls back to the file, which only exists
          // where there is a filesystem.
          child: image.bytes != null
              ? Image.memory(
                  Uint8List.fromList(image.bytes!),
                  height: _tile,
                  width: _tile,
                  fit: BoxFit.cover,
                  // The picker validates the EXTENSION, not the contents, so a
                  // renamed or truncated file reaches here as bytes no decoder
                  // accepts. Image.memory THROWS on those where Image.file
                  // failed quietly, so without this a single bad photo takes
                  // out the whole tray.
                  errorBuilder: (_, _, _) => const _BrokenTile(),
                )
              : CommonImageView(
                  filePath: image.path, height: _tile, width: _tile),
        ),
        if (image.status == ImageUploadStatus.uploading)
          _scrim(const DiscreteCircleLoading(size: AppSizes.s24)),
        if (image.status == ImageUploadStatus.failed)
          _scrim(GestureDetector(
            onTap: () => onRetry(image.localId),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh_rounded, color: kWhiteColor,
                    size: AppSizes.s20),
                MyText(text: 'Retry', size: AppTextScale.caption,
                    color: kWhiteColor),
              ],
            ),
          )),
        Positioned(
          top: AppSizes.s4,
          right: AppSizes.s4,
          child: GestureDetector(
            onTap: () => onRemove(image.localId),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.s4),
              decoration: const BoxDecoration(
                  color: kBlackColor, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: AppSizes.s12,
                  color: kWhiteColor),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Absent entirely at 5 rather than greyed: the backend rejects a sixth image,
/// and a disabled tile still reads as an available action.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap, required this.remaining});

  final VoidCallback onTap;
  final int remaining;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: _tile,
      height: _tile,
      decoration: BoxDecoration(
        color: kMutedSurfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: kTertiaryColor, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo_outlined, color: kGreyTextColor,
              size: AppSizes.s20),
          MyText(text: '$remaining left', size: AppTextScale.caption,
              color: kGreyTextColor, paddingTop: AppSizes.s4),
        ],
      ),
    ),
  );
}

/// What a tile shows when its bytes are not a decodable image.
///
/// Deliberately not an error state the buyer has to act on: the upload itself
/// is unaffected — the server validates what actually lands — and the tray
/// already has a Retry affordance for real failures.
class _BrokenTile extends StatelessWidget {
  const _BrokenTile();

  @override
  Widget build(BuildContext context) => Container(
    height: _tile,
    width: _tile,
    color: kMutedSurfaceColor,
    child: const Icon(Icons.broken_image_outlined,
        color: kGreyTextColor, size: AppSizes.s24),
  );
}

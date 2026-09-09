import 'dart:typed_data';

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/data/models/request_enums.dart'
    show kMaxImageBytes, kMaxRequestImages;
import 'package:autonect/domain/pending_image.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

const double _tile = 88;

/// The pale disc behind the upload glyph.
const double _badge = 48;

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Absent entirely at 5 rather than greyed: the backend rejects a sixth
      // image, and a disabled drop zone still reads as an available action.
      if (images.length < kMaxRequestImages) _UploadZone(onTap: onAdd),
      if (images.isNotEmpty) ...[
        const SizedBox(height: AppSizes.s12),
        Wrap(
          spacing: AppSizes.s8,
          runSpacing: AppSizes.s8,
          children: [
            for (final image in images)
              _Tile(image: image, onRemove: onRemove, onRetry: onRetry),
          ],
        ),
      ],
    ],
  );
}

/// The comp's upload affordance: one full-width card, not a grid of add tiles.
///
/// The comp draws only the empty state, so picked photos keep their own tiles
/// BELOW this card rather than inside it — a tile is the only place the
/// per-photo upload spinner, the Retry target and the remove X can live, and
/// none of those has anywhere to go in a single card.
class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.onTap});

  final VoidCallback onTap;

  /// Read off the constant the picker actually enforces, so the promise on the
  /// card cannot drift from the rule that rejects the file.
  static final String _limit = '${kMaxImageBytes ~/ (1024 * 1024)}MB';

  @override
  Widget build(BuildContext context) => MyRippleEffect(
    radius: AppSizes.radiusSm,
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSizes.s24, horizontal: AppSizes.s16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: kFieldBorderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _badge,
            height: _badge,
            decoration: const BoxDecoration(
                color: kLightOrangeColor, shape: BoxShape.circle),
            child: const Icon(Icons.file_upload_outlined,
                color: kSecondaryColor, size: AppSizes.s20),
          ),
          MyText(text: 'Click to Upload', size: AppTextScale.body,
              color: kGreyTextColor, paddingTop: AppSizes.s12),
          MyText(text: 'Upload images of the part or problem area',
              size: AppTextScale.label, color: kGreyTextColor,
              textAlign: TextAlign.center, paddingTop: AppSizes.s4),
          MyText(text: '(PNG, JPG up to $_limit)', size: AppTextScale.label,
              color: kGreyTextColor, textAlign: TextAlign.center),
        ],
      ),
    ),
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

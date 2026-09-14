import 'package:autonect/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:autonect/view/widget/local_file_image.dart';
import 'package:flutter_svg/svg.dart';

class CommonImageView extends StatelessWidget {
  // ignore_for_file: must_be_immutable
  String? url;
  String? imagePath;
  String? svgPath;
  /// A LOCAL FILE PATH, not a File: dart:io does not compile for web, and
  /// this widget is on every screen. Rendering goes through local_file_image,
  /// which is the only place in lib/ that still touches the filesystem.
  String? filePath;
  double? height;
  double? width;
  double? radius;
  final BoxFit fit;
  final String placeHolder;
  final Color? imageColor;

  /// A STABLE identity for the network cache, when [url] is not one.
  ///
  /// Presigned S3 urls change on every read, so leaving the cache keyed on the
  /// url means the same photo is re-fetched every time and an entry held past
  /// its expiry serves a 403. Pass the S3 object key.
  final String? cacheKey;

  /// Optional fallback widget to render when network load fails or URL is invalid.
  final Widget? errorWidget;

  CommonImageView({
    this.imageColor,
    this.cacheKey,
    this.url,
    this.imagePath,
    this.svgPath,
    this.filePath,
    this.height,
    this.width,
    this.radius = 0.0,
    this.fit = BoxFit.cover,
    this.placeHolder = 'assets/images/no_image_found.png',
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return _buildImageView(context);
  }

  /// Pixels to decode to, from the logical [width] and this screen's density.
  ///
  /// Without it Flutter decodes the file at its FULL source resolution however
  /// small the slot is: assets/images/profile_image.jpg is 3456x5184, which is
  /// ~68MB of RGBA in memory to fill a 56px circle. Capping the decode is the
  /// difference between that and ~90KB.
  ///
  /// Null when the caller gave no width — decoding to an unknown box is worse
  /// than not capping, since it would resample to the wrong size.
  int? _decodeWidth(BuildContext context) {
    final w = width;
    if (w == null || w <= 0 || !w.isFinite) return null;
    return (w * MediaQuery.devicePixelRatioOf(context)).round();
  }

  Widget _buildImageView(BuildContext context) {
    if (svgPath != null && svgPath!.isNotEmpty) {
      return Container(
        height: height,
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius!),
          child: SvgPicture.asset(
            svgPath!,
            height: height,
            width: width,
            fit: fit,
            // Without this an SVG silently ignores imageColor while a PNG in
            // the same slot honours it — so swapping a glyph from .png to .svg
            // drops its tint with no error and no warning.
            colorFilter: imageColor == null
                ? null
                : ColorFilter.mode(imageColor!, BlendMode.srcIn),
          ),
        ),
      );
    } else if (filePath != null && filePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius!),
        child: localFileImage(
          path: filePath!,
          height: height,
          width: width,
          fit: fit,
          cacheWidth: _decodeWidth(context),
        ),
      );
    } else if (url != null &&
        url!.isNotEmpty &&
        (url!.startsWith('http://') || url!.startsWith('https://'))) {
      final Widget fallbackWidget = errorWidget ??
          (placeHolder.isNotEmpty && placeHolder != 'assets/images/no_image_found.png'
              ? Image.asset(placeHolder, height: height, width: width, fit: fit)
              : Container(
                  height: height,
                  width: width,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(radius ?? 0.0),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person,
                    size: (width != null ? width! * 0.5 : 24),
                    color: Colors.grey.shade400,
                  ),
                ));
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius!),
        child: CachedNetworkImage(
          height: height,
          width: width,
          fit: fit,
          memCacheWidth: _decodeWidth(context),
          imageUrl: url!,
          // Without this the cache is keyed on the URL. Every presigned S3 GET
          // in this app carries a fresh signature and expiry, so the same photo
          // looks like a new image on every read: re-downloaded each time, and
          // any entry held from a previous read serves a 403 once it expires.
          // Callers pass the stable object key instead.
          cacheKey: cacheKey,
          placeholder: (context, url) => Container(
            height: 23,
            width: 23,
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: kSecondaryColor,
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => fallbackWidget,
        ),
      );
    } else if (url != null && url!.isNotEmpty) {
      final Widget fallbackWidget = errorWidget ??
          (placeHolder.isNotEmpty && placeHolder != 'assets/images/no_image_found.png'
              ? Image.asset(placeHolder, height: height, width: width, fit: fit)
              : Container(
                  height: height,
                  width: width,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(radius ?? 0.0),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person,
                    size: (width != null ? width! * 0.5 : 24),
                    color: Colors.grey.shade400,
                  ),
                ));
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius!),
        child: fallbackWidget,
      );
    } else if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius!),
        child: Image.asset(
          color: imageColor,
          imagePath!,
          height: height,
          width: width,
          fit: fit,
          cacheWidth: _decodeWidth(context),
        ),
      );
    }
    return SizedBox();
  }
}

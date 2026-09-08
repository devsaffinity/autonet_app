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

  CommonImageView({
    this.imageColor,
    this.url,
    this.imagePath,
    this.svgPath,
    this.filePath,
    this.height,
    this.width,
    this.radius = 0.0,
    this.fit = BoxFit.cover,
    this.placeHolder = 'assets/images/no_image_found.png',
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
    } else if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius!),
        child: CachedNetworkImage(
          height: height,
          width: width,
          fit: fit,
          memCacheWidth: _decodeWidth(context),
          imageUrl: url!,
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
          errorWidget: (context, url, error) =>
              Image.asset(placeHolder, height: height, width: width, fit: fit),
        ),
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

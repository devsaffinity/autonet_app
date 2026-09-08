import 'package:flutter/material.dart';

/// Web fallback for [localFileImage].
///
/// A browser cannot re-read a path, and a picked file's blob URL does not
/// survive a reload — so a restored draft has nothing to paint here. Renders the
/// same placeholder a missing file gets on mobile rather than throwing.
Widget localFileImage({
  required String path,
  double? height,
  double? width,
  BoxFit fit = BoxFit.cover,
  int? cacheWidth,
}) => Container(
  height: height,
  width: width,
  color: const Color(0xffF7F7F8),
  child: const Icon(Icons.image_outlined, color: Color(0xff949494)),
);

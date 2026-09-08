import 'dart:io';

import 'package:flutter/material.dart';

/// THE ONLY file in `lib/` permitted to import dart:io.
///
/// Selected by the conditional export in local_file_image.dart when the platform
/// has a filesystem, so every other caller stays web-compatible.
Widget localFileImage({
  required String path,
  double? height,
  double? width,
  BoxFit fit = BoxFit.cover,
  int? cacheWidth,
}) => Image.file(
  File(path),
  height: height,
  width: width,
  fit: fit,
  cacheWidth: cacheWidth,
  // A restored draft can point at a file the OS has since reclaimed. Without
  // this the tile throws instead of degrading.
  errorBuilder: (_, _, _) => _missing(height, width),
);

Widget _missing(double? height, double? width) => Container(
  height: height,
  width: width,
  color: const Color(0xffF7F7F8),
  child: const Icon(Icons.broken_image_outlined, color: Color(0xff949494)),
);

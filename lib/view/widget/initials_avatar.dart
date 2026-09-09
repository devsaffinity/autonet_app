import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Initials on a muted tile, for a person or business with no photo.
///
/// It replaces `Assets.imagesProfileImage` as the fallback. That asset is a
/// real photograph of a real person, and rendering it for every provider who
/// has not uploaded anything put the SAME stranger's face on every card —
/// which reads as a broken image at best and as a false claim about who the
/// business is at worst. Initials are unmistakably a placeholder, so nobody
/// mistakes them for a photo of the provider.
///
/// Not a random colour per name: a deterministic tint would look decorative
/// and invite the reader to hunt for meaning in it. One muted surface across
/// every placeholder makes "no photo yet" a single, quiet visual state.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    required this.size,
    this.radius = AppSizes.radiusMd,
  });

  final String name;
  final double size;
  final double radius;

  /// First letters of the first two words — 'Jack Brennan' -> 'JB',
  /// 'Abc Garage' -> 'AG', 'Cher' -> 'C'.
  ///
  /// Runes, not code units, so a name starting with an emoji or a non-BMP
  /// character yields one whole character rather than half a surrogate pair.
  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2);
    final letters = words
        .map((w) => String.fromCharCode(w.runes.first))
        .join()
        .toUpperCase();
    return letters;
  }

  @override
  Widget build(BuildContext context) {
    final initials = initialsOf(name);
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kMutedSurfaceColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      // A name that is entirely punctuation or whitespace yields no letters.
      // The glyph is the floor, so the tile is never blank.
      child: initials.isEmpty
          ? Icon(Icons.storefront_outlined,
              size: size * 0.44, color: kGreyTextColor)
          : MyText(
              text: initials,
              // Proportional to the tile: this widget is used at 56, 64 and 96
              // and a fixed size would look lost in the largest and clipped in
              // the smallest.
              size: size * 0.36,
              weight: AppWeights.bold,
              color: kSecondaryColor,
            ),
    );
  }
}

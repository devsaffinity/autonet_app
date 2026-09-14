import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// A form label, plus the asterisk that marks a field the request cannot be
/// submitted without.
///
/// A widget rather than a ' *' appended to each label string, for two reasons.
/// The marker has to be RED where the label is not — inside the label's own
/// colour an asterisk reads as punctuation — and a label that carries its
/// marker in the string cannot be translated without the translator carrying it
/// too. It is also the one place to change if the convention ever moves.
///
/// [text] is rendered as given: callers that translate do so before passing it.
class FieldLabel extends StatelessWidget {
  const FieldLabel({
    super.key, required this.text, this.isRequired = false, this.size,
    this.weight, this.color, this.paddingBottom, this.paddingTop,
    this.letterSpacing,
  });

  final String text;

  /// Draws the asterisk. False by default everywhere, so a field only claims to
  /// be mandatory where someone has checked that the API agrees — an asterisk
  /// on an optional field is the same lie as a missing one on a required field,
  /// and costs the buyer a form they cannot complete.
  final bool isRequired;

  /// All null by default so a caller that passes nothing renders exactly what a
  /// bare [MyText] would, and no existing label moves.
  final double? size, paddingBottom, paddingTop, letterSpacing;
  final FontWeight? weight;
  final Color? color;

  /// Shrink-wraps, and neither child is flexible.
  ///
  /// Both matter: a label is routinely placed inside ANOTHER Row — the photo
  /// section pairs one with its remaining-slots count — where it is handed
  /// unbounded width, and a flex child under an unbounded constraint is a hard
  /// layout assertion, not a degraded layout. Labels were never flexible before
  /// this widget existed either, so nothing regresses; they are short, fixed
  /// strings rather than data.
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MyText(
        text: text,
        size: size,
        weight: weight,
        color: color,
        paddingTop: paddingTop ?? 0,
        paddingBottom: paddingBottom ?? 0,
        letterSpacing: letterSpacing,
      ),
      if (isRequired)
        MyText(
          text: ' *',
          size: size,
          weight: weight,
          color: kRedColor,
          paddingTop: paddingTop ?? 0,
          paddingBottom: paddingBottom ?? 0,
        ),
    ],
  );
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyButton extends StatefulWidget {
  // NOT const: 37 existing call sites are outside this partition and a const
  // constructor would make prefer_const_constructors fire in all of them.
  // ignore: prefer_const_constructors_in_immutables
  MyButton({
    super.key,
    this.onTap,
    required this.buttonText,
    this.height = 48,
    this.backgroundColor = kSecondaryColor,
    this.fontColor = kWhiteColor,
    this.fontSize = 16,
    this.outlineColor = kTransperentColor,
    this.radius = 100,
    this.icon,
    this.iconData,
    this.svgIconColor,
    this.haveSvg = false,
    this.isGradient = false,
    this.mBottom = 0,
    this.mTop = 0,
    this.iconSize,
    this.fontWeight = FontWeight.w600,
    this.enabled = true,
    this.loading = false,
    this.oneShot = false,
  });

  final String buttonText;
  final VoidCallback? onTap;
  final double? height;
  final double radius;
  final double fontSize;
  final Color outlineColor;
  final Color backgroundColor, fontColor;
  final Color? svgIconColor;
  final String? icon;

  /// A MATERIAL glyph before the label, as an alternative to [icon] plus
  /// [haveSvg], which take an SVG asset path.
  ///
  /// Both slots exist because both sources do: the buttons carrying a brand
  /// mark point at an asset, and the ones carrying a plain affordance —
  /// chat, calendar, download — have no asset drawn for them and should not
  /// need one commissioned. It takes [fontColor], so an outlined button's
  /// glyph and its label can never drift apart.
  final IconData? iconData;

  final bool haveSvg;
  final bool isGradient;
  final double? iconSize;
  final double mTop, mBottom;
  final FontWeight fontWeight;

  /// Off for a form that has not validated yet.
  final bool enabled;

  /// In flight. Closes the double-submit hazard on every existing call site:
  /// a second tap while a POST is open would create a second part request.
  final bool loading;

  /// Fires AT MOST ONCE, for the tap that cannot be taken back: a confirm that
  /// pops with a result, a sheet CTA that navigates.
  ///
  /// [loading] and [enabled] cannot cover this. Both are read at BUILD time,
  /// and two taps inside one frame reach the callback the last build handed
  /// the InkWell — nothing has rebuilt in between — so both fire. A callback
  /// that pops SYNCHRONOUSLY is saved by the route it pops, which stops taking
  /// pointers the moment it starts leaving; one that signs out, spends credits
  /// or pops only after an `await` has nothing between it and happening twice.
  final bool oneShot;

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> {
  /// A one-shot button that has been tapped. State, not a widget field: the
  /// widget is rebuilt on every frame of the pop animation and a field would
  /// re-arm with it.
  bool _spent = false;

  bool get _inert => !widget.enabled || widget.loading || _spent;

  void _tap() {
    // The guard lives HERE as well as in build(), because it is precisely the
    // taps that arrive with no build between them that this is for.
    if (_spent) return;
    // Before the callback, never after: onTap pops this route, and a setState
    // on a defunct State throws.
    if (widget.oneShot) setState(() => _spent = true);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor;
    return Container(
      margin: EdgeInsets.only(top: widget.mTop, bottom: widget.mBottom),
      height: widget.height,
      decoration: BoxDecoration(
        color: _inert ? backgroundColor.withValues(alpha: .45) : backgroundColor,
        border: Border.all(color: widget.outlineColor),
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: widget.isGradient
            ? const LinearGradient(
                begin: AlignmentGeometry.topCenter,
                end: AlignmentGeometry.bottomCenter,
                colors: [kSecondaryColor, kTertiaryColor],
              )
            : null,
      ),
      child: Material(
        color: kTransperentColor,
        child: InkWell(
          onTap: _inert || widget.onTap == null ? null : _tap,
          splashColor: kPrimaryColor.withValues(alpha: 0.1),
          highlightColor: kTertiaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          child: widget.loading
              ? const Center(child: DiscreteCircleLoading(size: 20))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.haveSvg == true)
                      CommonImageView(
                        svgPath: widget.icon,
                        width: widget.iconSize,
                      ),
                    if (widget.iconData case final glyph?) ...[
                      Icon(glyph,
                          size: widget.iconSize ?? AppSizes.s20,
                          color: widget.fontColor),
                      const SizedBox(width: AppSizes.s8),
                    ],
                    Flexible(
                      child: MyText(
                        paddingLeft: (widget.haveSvg == true) ? 10 : 0,
                        text: widget.buttonText,
                        size: widget.fontSize,
                        color: widget.fontColor,
                        weight: widget.fontWeight,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class NavButton extends StatelessWidget {
  final String buttonText;

  /// Null renders the button DISABLED — dimmed as well as inert. MyButton dims
  /// only for `enabled: false`; a bare null onTap would look tappable and do
  /// nothing.
  final VoidCallback? onTap;

  // Non-const for the same reason as MyButton above: its call sites are not
  // in this partition.
  // ignore: prefer_const_constructors_in_immutables
  NavButton({
    super.key,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyButton(
            mBottom: 12,
            onTap: onTap,
            enabled: onTap != null,
            buttonText: buttonText,
          ),
        ],
      ),
    );
  }
}

class MyBackButton extends StatelessWidget {
  const MyBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: MyRippleEffect(
        radius: 100,
        onTap: () => Get.back(),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
      ),
    );
  }
}

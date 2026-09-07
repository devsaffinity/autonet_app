import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:flutter/material.dart';

// One bar, three role shells. Geometry below is deliberate, not taste:
//
//   _kPillHeight 64        touch strip; every tab fills it top to bottom
//   _kFabSize 56           Material's minimum comfortable FAB
//   _kFabProtrusion 28     exactly half the FAB, so it straddles the pill edge
//   _kBarHeight            pill + protrusion — see the hit-test note below
//
// THE HIT-TEST TRAP: a child painted outside its parent's bounds does not
// receive taps. `RenderBox.hitTest` rejects any position outside `size` before
// it ever consults children, so a FAB pushed above the pill with
// `Stack(clipBehavior: Clip.none)` + a negative offset renders perfectly and
// then swallows every tap on its protruding half. `Clip.none` governs PAINTING
// only; it has no bearing on hit-testing.
//
// The fix is to give the Stack room rather than to fight it: this widget is
// `_kBarHeight` tall (pill + protrusion), the pill is aligned to the bottom of
// that box, and the FAB to the top-centre. The FAB then sits entirely INSIDE
// its parent, so hit-testing works with no custom RenderBox, no
// HitTestBehavior override and nothing to regress. The empty strip beside the
// FAB is not `IgnorePointer`-wrapped — it simply has no child, so taps fall
// through to the page underneath, which is what you want above a floating bar.
//
// Rejected: Scaffold.floatingActionButton + centerDocked + BottomAppBar. It
// owns the notch for free but hands FAB placement to Scaffold, which every role
// shell would then have to opt out of, and BottomAppBar cannot float inset from
// the screen edges the way this pill does.

const double _kPillHeight = 64;
const double _kFabSize = 56;
const double _kFabProtrusion = _kFabSize / 2;
const double _kBarHeight = _kPillHeight + _kFabProtrusion;

/// Horizontal room reserved for the FAB inside the pill: the button itself
/// plus a gutter each side, so a glyph never crowds the orange circle.
const double _kFabGutter = 8;
const double _kFabSlot = _kFabSize + (_kFabGutter * 2);

const double _kIconSize = 24;
const double _kSideInset = 16;

// ── Bottom Nav Bar Widget ─────────────────────────────────────────────────────

class RoleNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Opt-in centre button. Null on the supplier and electrician shells, which
  /// keep the plain evenly-spaced bar they already had — passing nothing must
  /// stay a no-op, which is why this is nullable rather than a bool + fields.
  ///
  /// When set, [items] is split down the middle around it, so an EVEN count is
  /// required (asserted in [build]); 4 is what the buyer shell uses.
  final NavCenterAction? centerAction;

  const RoleNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerAction,
  });

  @override
  Widget build(BuildContext context) {
    final fab = centerAction;
    assert(
      fab == null || items.length.isEven,
      'a centre action splits the bar in half - give it an even tab count, '
      'not ${items.length}',
    );

    return SafeArea(
      top: false,
      child: Padding(
        // Bottom inset is 20 on top of SafeArea's gesture-bar inset: the pill
        // floats clear of the home indicator rather than sitting on it.
        padding: const EdgeInsets.fromLTRB(_kSideInset, 8, _kSideInset, 20),
        child: SizedBox(
          // Only claim the protrusion when something occupies it. Reserving it
          // unconditionally would hand the supplier and electrician shells a
          // 28dp transparent strip and shrink their page bodies by that much —
          // an opt-in feature is not allowed to cost the shells that decline
          // it. Role is fixed for a session, so a per-role bar height can never
          // change under a user mid-flight.
          height: fab == null ? _kPillHeight : _kBarHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _pill(fab != null),
              if (fab != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: _CenterFab(action: fab),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(bool hasFab) => Container(
    height: _kPillHeight,
    decoration: BoxDecoration(
      color: kPrimaryColor,
      borderRadius: BorderRadius.circular(_kPillHeight / 2),
      boxShadow: [
        BoxShadow(
          color: kGreyTextColor.withValues(alpha: 0.4),
          blurRadius: 7,
          offset: const Offset(0, 0),
        ),
      ],
    ),
    child: Row(children: _tabs(hasFab)),
  );

  List<Widget> _tabs(bool hasFab) {
    final tabs = <Widget>[
      for (var i = 0; i < items.length; i++)
        Expanded(
          child: _NavTabItem(
            item: items[i],
            isSelected: i == currentIndex,
            onTap: () => onTap(i),
          ),
        ),
    ];
    if (!hasFab) return tabs;
    // The gap is a fixed width, not an Expanded: the FAB is a fixed 56 and the
    // hole under it must not breathe with the screen or the two stop lining up.
    return [
      ...tabs.sublist(0, tabs.length ~/ 2),
      const SizedBox(width: _kFabSlot),
      ...tabs.sublist(tabs.length ~/ 2),
    ];
  }
}

// ── Centre FAB ────────────────────────────────────────────────────────────────

class _CenterFab extends StatelessWidget {
  final NavCenterAction action;

  const _CenterFab({required this.action});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.semanticLabel,
      child: SizedBox(
        height: _kFabSize,
        width: _kFabSize,
        child: Material(
          color: kSecondaryColor,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: kSecondaryColor.withValues(alpha: 0.4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: action.onTap,
            // Excluded because the Semantics above already announces this as a
            // button with a label; without this the reader says it twice.
            child: ExcludeSemantics(
              child: Icon(action.icon, color: kWhiteColor, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Tab Item ──────────────────────────────────────────────────────────────

class _NavTabItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The bar renders glyphs only — no captions — so the label is invisible to
    // a sighted user and the ONLY thing a screen reader has to go on.
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          // Full pill height, so the target is the whole column and not just
          // the 24px glyph. Narrowest case is a 4-tab bar with a FAB on a
          // 320dp screen: (320 - 32 side - 72 slot) / 4 = 54dp. Over the 48dp
          // floor with room to spare.
          height: _kPillHeight,
          child: Center(
            child: CommonImageView(
              radius: 100,
              imagePath: isSelected ? item.iconFill : item.iconOutline,
              height: _kIconSize,
              width: _kIconSize,
              // The avatar tab is a photo, not a glyph, so it crops instead of
              // letterboxing. This used to be `index == 4`, which hard-coded
              // the tab position.
              fit: item.isAvatar ? BoxFit.cover : BoxFit.contain,
              // Tint is what makes selection visible. The previous cue was a
              // kWhiteColor 15% chip painted on kPrimaryColor — and
              // kPrimaryColor IS #FFFFFF, so the selected tab was white on
              // white and no tab ever looked active. Never re-introduce a
              // white-on-white state here.
              //
              // Safe on these assets: every nav glyph is a 96x96 RGBA PNG, so
              // Image.asset's default srcIn blend recolours the strokes and
              // leaves the transparent ground alone. An avatar PHOTO must not
              // be tinted or srcIn floods it to a flat disc.
              imageColor: item.isAvatar
                  ? null
                  : (isSelected ? kSecondaryColor : kGreyTextColor),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class NavItem {
  final String label;
  final String iconFill;
  final String iconOutline;

  /// True for the profile tab, whose icon is a user photo and must crop.
  final bool isAvatar;

  const NavItem({
    required this.label,
    required this.iconFill,
    required this.iconOutline,
    this.isAvatar = false,
  });
}

/// The centre button on a shell that opts into one.
class NavCenterAction {
  final IconData icon;
  final VoidCallback onTap;

  /// Spoken by screen readers. The button is a bare glyph, so without this it
  /// announces as an unlabelled button.
  final String semanticLabel;

  const NavCenterAction({
    required this.onTap,
    required this.semanticLabel,
    this.icon = Icons.add,
  });
}

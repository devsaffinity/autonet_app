import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/role_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two bugs live in this widget's history and both are silent — they render
/// perfectly and simply do not work. These tests exist to keep them dead:
///
///   1. A FAB that protrudes above its parent's bounds paints fine and eats
///      every tap on the protruding half, because `RenderBox.hitTest` rejects
///      positions outside `size` before it looks at children.
///   2. A selected tab cued with `kWhiteColor` on a `kPrimaryColor` bar, which
///      is white on white.
///
/// Neither shows up in a screenshot diff, so neither can be caught by eye.

const _items = [
  NavItem(
    label: 'Home',
    iconFill: Assets.imagesEHomeFill,
    iconOutline: Assets.imagesEHomeOutline,
  ),
  NavItem(
    label: 'Requests',
    iconFill: Assets.imagesECalenderFill,
    iconOutline: Assets.imagesECalenderOutline,
  ),
  NavItem(
    label: 'Orders',
    iconFill: Assets.imagesESettingFill,
    iconOutline: Assets.imagesESettingOutline,
  ),
  NavItem(
    label: 'Chat',
    iconFill: Assets.imagesEChatFill,
    iconOutline: Assets.imagesEChatOutline,
  ),
];

Widget _host({
  NavCenterAction? centerAction,
  int currentIndex = 0,
  ValueChanged<int>? onTap,
  List<NavItem> items = _items,
  Size surface = const Size(360, 720),
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: surface),
    child: Scaffold(
      bottomNavigationBar: RoleNavBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap ?? (_) {},
        centerAction: centerAction,
      ),
    ),
  ),
);

void main() {
  group('centre FAB', () {
    testWidgets('the half protruding ABOVE the pill still receives taps', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          centerAction: NavCenterAction(
            semanticLabel: 'New part request',
            onTap: () => taps++,
          ),
        ),
      );

      final fabRect = tester.getRect(find.bySemanticsLabel('New part request'));

      // The pill's top edge sits _kFabProtrusion (28) below the FAB's top, so
      // anything above that line is in the overhang — the exact region the
      // naive Stack + Clip.none + negative-offset build renders and then
      // ignores. Tapping 6px in is unambiguously inside it.
      final overhang = Offset(fabRect.center.dx, fabRect.top + 6);
      expect(
        overhang.dy,
        lessThan(fabRect.top + 28),
        reason: 'test must aim at the overhang, not the part over the pill',
      );

      await tester.tapAt(overhang);
      await tester.pump();

      expect(
        taps,
        1,
        reason: 'the overhang swallowed the tap - the FAB has escaped its '
            "parent's bounds again",
      );
    });

    testWidgets('is absent when no centre action is given', (tester) async {
      // The supplier and electrician shells pass nothing and must be untouched.
      await tester.pumpWidget(_host());

      expect(find.bySemanticsLabel('New part request'), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('does not report itself as a selected tab', (tester) async {
      await tester.pumpWidget(
        _host(
          centerAction: NavCenterAction(
            semanticLabel: 'New part request',
            onTap: () {},
          ),
        ),
      );

      // It pushes a route; it is not a destination. If it ever acquires a
      // selected state the bar will show two active items at once.
      expect(
        tester.getSemantics(find.bySemanticsLabel('New part request')),
        isSemantics(isButton: true, isSelected: false),
      );
    });

    testWidgets('tapping a tab beside the FAB reports the right index', (
      tester,
    ) async {
      // The gap shifts every tab right of centre by a fixed 72px. An off-by-one
      // in the sublist split would only show up here.
      final tapped = <int>[];
      await tester.pumpWidget(
        _host(
          onTap: tapped.add,
          centerAction: NavCenterAction(
            semanticLabel: 'New part request',
            onTap: () {},
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Orders'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Chat'));
      await tester.pump();

      expect(tapped, [2, 3]);
    });
  });

  group('selected state', () {
    testWidgets('selected tab is orange and unselected is grey', (
      tester,
    ) async {
      await tester.pumpWidget(_host(currentIndex: 1));

      final glyphs = tester
          .widgetList<CommonImageView>(find.byType(CommonImageView))
          .toList();

      expect(glyphs, hasLength(4));
      expect(
        glyphs[1].imageColor,
        kSecondaryColor,
        reason: 'the selected tab must be tinted, not chipped',
      );
      expect(glyphs[0].imageColor, kGreyTextColor);
      expect(
        glyphs.map((g) => g.imageColor),
        isNot(contains(kWhiteColor)),
        reason: 'kWhiteColor on a kPrimaryColor bar is white on white',
      );
    });

    testWidgets('an avatar tab is never tinted', (tester) async {
      // srcIn on a photo floods it to a flat disc.
      await tester.pumpWidget(
        _host(
          currentIndex: 0,
          items: const [
            NavItem(
              label: 'Profile',
              iconFill: Assets.imagesProfileImage,
              iconOutline: Assets.imagesProfileImage,
              isAvatar: true,
            ),
          ],
        ),
      );

      final avatar = tester.widget<CommonImageView>(
        find.byType(CommonImageView),
      );
      expect(avatar.imageColor, isNull);
    });
  });

  group('layout safety', () {
    testWidgets('no overflow at 320dp with a FAB', (tester) async {
      // 320dp is the narrowest phone still in the wild. Four tabs, 32 of side
      // inset and a 72 FAB slot leaves 54dp each - over the 48dp floor.
      await tester.pumpWidget(
        _host(
          surface: const Size(320, 640),
          centerAction: NavCenterAction(
            semanticLabel: 'New part request',
            onTap: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final home = tester.getRect(find.bySemanticsLabel('Home'));
      expect(home.width, greaterThanOrEqualTo(48));
      expect(home.height, greaterThanOrEqualTo(48));
    });

    testWidgets('a bar with no FAB claims no height for one', (tester) async {
      // The opt-in must be free for the shells that decline it. Reserving the
      // 28dp overhang unconditionally silently shrank the supplier and
      // electrician page bodies - it renders as empty space, so nothing about
      // those screens looks wrong while every one of them is 28dp shorter.
      await tester.pumpWidget(_host());
      final plain = tester.getSize(find.byType(RoleNavBar)).height;

      await tester.pumpWidget(
        _host(
          centerAction: NavCenterAction(
            semanticLabel: 'New part request',
            onTap: () {},
          ),
        ),
      );
      final withFab = tester.getSize(find.byType(RoleNavBar)).height;

      expect(
        withFab - plain,
        28,
        reason: 'only the shell that opts in should pay for the overhang',
      );
    });

    testWidgets('survives the keyboard being open', (tester) async {
      // resizeToAvoidBottomInset lifts the whole bar above the keyboard; the
      // 92dp bar plus a 300dp inset on a short surface is the tightest squeeze
      // the layout ever sees.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 560),
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: Scaffold(
              bottomNavigationBar: RoleNavBar(
                items: _items,
                currentIndex: 0,
                onTap: (_) {},
                centerAction: NavCenterAction(
                  semanticLabel: 'New part request',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('every tab carries a label for screen readers', (tester) async {
      // The bar renders glyphs only - with no Semantics label there is nothing
      // for a reader to announce.
      await tester.pumpWidget(_host());

      for (final item in _items) {
        expect(
          find.bySemanticsLabel(item.label),
          findsOneWidget,
          reason: '${item.label} is unreachable by screen reader',
        );
      }
    });
  });
}

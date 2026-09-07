import 'package:autonect/view/widget/role_nav_bar.dart';
import 'package:flutter/material.dart';

/// One shell backs all three roles. The assert is what makes the index-4
/// duplicate-screen bug (Profile rendering a second HomePage) structurally
/// impossible to reintroduce.
class RoleShell extends StatefulWidget {
  final List<NavItem> items;
  final List<Widget> screens;
  final int initialIndex;

  /// Optional centre button, forwarded straight to [RoleNavBar]. Null keeps the
  /// plain bar, so the supplier and electrician shells are unaffected by the
  /// buyer opting in.
  ///
  /// Deliberately NOT part of [screens]: the centre action pushes a route on
  /// top of the shell, it is not a tab. Adding it to the tab list would break
  /// the items/screens assert below and give it a selected state it must never
  /// have.
  final NavCenterAction? centerAction;

  const RoleShell({
    super.key,
    required this.items,
    required this.screens,
    this.initialIndex = 0,
    this.centerAction,
  });
  // The tab/screen count assert lives in RoleShellState.initState, NOT in this
  // constructor: an assert in a `const` constructor is evaluated at compile
  // time, and `List.length` is not a constant expression, so `const
  // RoleShell(...)` would not compile. Keeping the constructor const is what
  // stops the three shells silently degrading to non-const.

  /// Lets a descendant switch tabs: RoleShell.maybeOf(context)?.goTo(1);
  /// Nullable on purpose: these screens are also pushed standalone via Get.to,
  /// where there is no shell ancestor. Never use a bang operator here.
  static RoleShellState? maybeOf(BuildContext c) =>
      c.findAncestorStateOfType<RoleShellState>();

  @override
  State<RoleShell> createState() => RoleShellState();
}

class RoleShellState extends State<RoleShell> {
  late int index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    // Trips the first time a mis-specified shell is built in debug — this is
    // what makes the old index-4 duplicate-screen bug impossible to keep.
    assert(
      widget.items.length == widget.screens.length,
      'every tab needs its own screen - no reusing index 0 at index 4',
    );
  }

  void goTo(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: widget.screens),
      // Deliberately NOT extendBody: true. The pill floats with a transparent
      // margin, so extending the body under it looks tidier — but every
      // scrollable in every role would then need its own bottom padding or its
      // last row hides behind the bar. Not worth it for the margin.
      bottomNavigationBar: RoleNavBar(
        items: widget.items,
        currentIndex: index,
        onTap: goTo,
        centerAction: widget.centerAction,
      ),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/view/screens/buyer/notifications/notifications_page.dart';
import 'package:autonect/view/screens/buyer/services/my_booking.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/profile_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Buyer profile — PUSHED from the avatar in `BuyerHomePage`'s header, and one
/// of the app's logout paths.
///
/// No longer a tab: the design gave the fifth tab slot to the centre FAB. That
/// makes this a routed page, so it now carries a back button — without one the
/// buyer would be stranded on a screen with no nav bar under it.
///
/// The identity block reads `TokenStore.user`, which the session already holds
/// in memory: `GET /v1/me` is phase-2 `profile` scope and this screen needs no
/// network and no repository of its own to stop lying about who is signed in.
class BuyerProfilePage extends StatelessWidget {
  /// Pops back to the shell and switches to the Requests tab.
  ///
  /// Supplied by the pusher because THIS page can no longer find the shell
  /// itself: it is routed on top of the shell, so `RoleShell.maybeOf(context)`
  /// returns null here and the old `?.goTo(1)` was a silently dead tile. The
  /// caller is inside the shell and can capture it; we cannot.
  ///
  /// Null when the page is opened with no shell behind it, in which case the
  /// tile is omitted rather than shown doing nothing.
  final VoidCallback? onOpenRequests;

  const BuyerProfilePage({super.key, this.onOpenRequests});

  @override
  Widget build(BuildContext context) {
    final user = Get.find<TokenStore>().user;
    final email = user?.email;
    return Scaffold(
      appBar: GeneralAppBar(title: "Profile", hasBackButton: true),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Identity block
            Center(
              child: Column(
                children: [
                  const _AvatarEditor(),
                  MyText(
                    paddingTop: 12,
                    // `name` is nullable on the wire; email is not, but the
                    // whole user is absent until a session exists.
                    text: user?.name ?? 'Autonect buyer',
                    size: 18,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                  if (email != null)
                    MyText(
                      paddingTop: 2,
                      text: email,
                      size: 13,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ProfileMenuTile(
              icon: Icons.event_note_outlined,
              label: 'My Bookings',
              onTap: () => Get.to(() => const MyBookingsPage()),
            ),
            // Omitted, not disabled, when there is no shell to go back to: a
            // tile that navigates nowhere is worse than an absent one.
            if (onOpenRequests != null)
              ProfileMenuTile(
                icon: Icons.receipt_long_outlined,
                label: 'My Requests',
                onTap: onOpenRequests!,
              ),
            ProfileMenuTile(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              // Opens the real centre. It used to snackbar "You have no new
              // notifications" unconditionally — which was a claim the app had
              // never checked, and was wrong the moment an offer arrived.
              onTap: () => Get.to(() => const NotificationsPage()),
            ),
            ProfileMenuTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              isDestructive: true,
              onTap: () => RoleController.to.signOut(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// The profile photo, and the control that changes it.
///
/// Its own widget so only THIS subtree rebuilds while an upload runs — the
/// identity block around it has no reason to flicker.
class _AvatarEditor extends StatefulWidget {
  const _AvatarEditor();

  @override
  State<_AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<_AvatarEditor> {
  final _c = ProfileController.ensure();

  @override
  void initState() {
    super.initState();
    // The presigned avatarUrl is short-lived, so it is re-read on every visit
    // rather than trusted from a previous one.
    _c.load();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Change profile photo',
    child: InkWell(
      onTap: _c.changeAvatar,
      customBorder: const CircleBorder(),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 106,
          width: 106,
          child: Obx(() {
            final url = _c.avatarUrl;
            final busy = _c.uploadingAvatar.value;
            return Stack(
              children: [
                Center(
                  child: ClipOval(
                    child: SizedBox(
                      height: 90,
                      width: 90,
                      // A presigned URL when the user has uploaded one, the
                      // shipped asset otherwise — NOT an empty circle, which
                      // reads as a failed load rather than "no photo yet".
                      child: url != null && url.isNotEmpty
                          ? CommonImageView(
                              url: url, height: 90, width: 90,
                              fit: BoxFit.cover)
                          : CommonImageView(
                              imagePath: Assets.imagesProfileImage,
                              height: 90, width: 90, fit: BoxFit.cover),
                    ),
                  ),
                ),
                if (busy)
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        height: AppSizes.s24,
                        width: AppSizes.s24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kSecondaryColor),
                      ),
                    ),
                  ),
                // The affordance. Without it a tappable circle is invisible as
                // a control — nobody taps their own photo on spec.
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.s8),
                    decoration: BoxDecoration(
                      color: kSecondaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryColor, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: AppSizes.s16, color: kWhiteColor),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    ),
  );
}

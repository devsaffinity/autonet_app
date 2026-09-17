import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/buyer/notifications_controller.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/view/screens/buyer/notifications/notifications_page.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_round_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GeneralAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Color? appBarColor, backIconColor;
  final List<Widget>? action;
  bool hasBackButton;
  bool centerdTitle;
  GeneralAppBar({
    super.key,
    this.title,
    this.appBarColor,
    this.backIconColor,

    this.hasBackButton = true,
    this.centerdTitle = true,
    this.action,
  });

  Size get preferredSize => Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appBarColor ?? kTransperentColor,
      surfaceTintColor: appBarColor ?? kTransperentColor,
      automaticallyImplyLeading: false,
      leadingWidth: hasBackButton ? 45 : 0,
      leading: Visibility(
        visible: hasBackButton,
        child: Row(
          children: [
            SizedBox(width: 20),
            MyRippleEffect(
              // width: 37,
              // height: 37,
              onTap: () {
                Get.back();
              },
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kBlackColor,
                size: 16,
              ),
            ),
          ],
        ),
      ),
      title: MyText(text: title ?? '', size: 16, weight: FontWeight.w600),
      actions: action,
      centerTitle: centerdTitle,
    );
  }
}

class FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  const FilterButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MyRoundButton(
      width: 37,
      height: 37,
      borderColor: kTransperentColor,
      color: kQuaternaryColor,
      onTap: onTap,
      child: Icon(Icons.tune_rounded, color: kWhiteColor, size: 22),
    );
  }
}

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final profile = ProfileController.ensure();
    final notifications = NotificationsController.ensure();

    return AppBar(
      backgroundColor: kTransperentColor,
      surfaceTintColor: kTransperentColor,
      automaticallyImplyLeading: false,
      leadingWidth: Get.width,
      leading: Padding(
        padding: AppSizes.HORIZONTAL,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() {
              final me = profile.me;
              final avatar = me?.avatarUrl;
              final name = me?.name ?? 'User';
              return ClipOval(
                child: SizedBox(
                  height: 46,
                  width: 46,
                  child: (avatar != null && avatar.isNotEmpty)
                      ? CommonImageView(
                          url: avatar,
                          cacheKey: me?.id,
                          height: 46,
                          width: 46,
                          radius: 100,
                          fit: BoxFit.cover,
                          errorWidget: InitialsAvatar(
                            name: name,
                            size: 46,
                            radius: 100,
                          ),
                        )
                      : InitialsAvatar(name: name, size: 46, radius: 100),
                ),
              );
            }),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(() {
                final name = profile.me?.name ?? 'User';
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: 'Hello',
                      size: 14,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                    ),
                    MyText(
                      text: name,
                      size: 16,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                      maxLines: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }),
            ),
            Obx(() {
              final unread = notifications.unread.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  MyRoundButton(
                    borderColor: kGreyTextColor.withValues(alpha: .2),
                    onTap: () async {
                      await Get.to(() => const NotificationsPage());
                      notifications.refreshUnread();
                    },
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: kBlackColor,
                      size: 22,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 9,
                        width: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xffD94D2F),
                          shape: BoxShape.circle,
                          border: Border.all(color: kPrimaryColor, width: 1.5),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ContractorHomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ContractorHomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final profile = ProfileController.ensure();
    final notifications = NotificationsController.ensure();

    return AppBar(
      backgroundColor: kTransperentColor,
      surfaceTintColor: kTransperentColor,
      automaticallyImplyLeading: false,
      leadingWidth: Get.width,
      leading: Padding(
        padding: AppSizes.HORIZONTAL,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() {
              final me = profile.me;
              final avatar = me?.avatarUrl;
              final name = me?.name ?? 'User';
              return ClipOval(
                child: SizedBox(
                  height: 46,
                  width: 46,
                  child: (avatar != null && avatar.isNotEmpty)
                      ? CommonImageView(
                          url: avatar,
                          cacheKey: me?.id,
                          height: 46,
                          width: 46,
                          radius: 100,
                          fit: BoxFit.cover,
                          errorWidget: InitialsAvatar(
                            name: name,
                            size: 46,
                            radius: 100,
                          ),
                        )
                      : InitialsAvatar(name: name, size: 46, radius: 100),
                ),
              );
            }),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(() {
                final name = profile.me?.name ?? 'User';
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: 'Hello',
                      size: 14,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                    ),
                    MyText(
                      text: name,
                      size: 16,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                      maxLines: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }),
            ),
            Obx(() {
              final unread = notifications.unread.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  MyRoundButton(
                    borderColor: kGreyTextColor.withValues(alpha: .2),
                    onTap: () async {
                      await Get.to(() => const NotificationsPage());
                      notifications.refreshUnread();
                    },
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: kBlackColor,
                      size: 22,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 9,
                        width: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xffD94D2F),
                          shape: BoxShape.circle,
                          border: Border.all(color: kPrimaryColor, width: 1.5),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: kSecondaryColor,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: CommonImageView(
                url: 'https://cdn-icons-png.flaticon.com/128/4140/4140048.png',
                height: 46,
                width: 46,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MyText(
              text: 'Good Morning, Mike',
              size: 18,
              weight: FontWeight.w600,
              color: kBlackColor,
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: kBlackColor,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 16,
//                 ),
//                 child: Row(
//                   children: [
                    
//                     const SizedBox(width: 12),
                   
//                     Container(
//                       height: 44,
//                       width: 44,
//                       decoration: BoxDecoration(
//                         color: kWhiteColor,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.06),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: const Icon(
//                         Icons.notifications_none_rounded,
//                         color: kBlackColor,
//                         size: 22,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
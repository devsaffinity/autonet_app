import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/buyer/notifications_controller.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/view/screens/buyer/notifications/notifications_page.dart';
import 'package:autonect/view/screens/supplier/profile/profile.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Avatar + greeting + ACCEPTING LEADS / PAUSED toggle + notification bell.
class SupplierHomeTopBar extends StatefulWidget {
  const SupplierHomeTopBar({super.key});

  @override
  State<SupplierHomeTopBar> createState() => _SupplierHomeTopBarState();
}

class _SupplierHomeTopBarState extends State<SupplierHomeTopBar> {
  late final ProfileController _profile;
  late final NotificationsController _notifications;
  bool _accepting = true;

  @override
  void initState() {
    super.initState();
    _profile = ProfileController.ensure();
    _profile.load();
    _notifications = NotificationsController.ensure();
    _notifications.refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Obx(() {
          final me = _profile.me;
          final avatar = me?.avatarUrl;
          final business =
              me?.supplierProfile?.businessName ?? me?.name ?? 'Supplier';
          return Semantics(
            button: true,
            label: 'Profile',
            child: InkWell(
              onTap: () async {
                final shell = RoleShell.maybeOf(context);
                if (shell != null) {
                  shell.goTo(4);
                } else {
                  await Get.to(() => const SupplierProfilePage());
                }
                _profile.load();
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(.3),
                decoration: AppStyling().myDecoration(
                  color: kSecondaryColor,
                  borderColor: kSecondaryColor,
                  radius: 100,
                ),
                child: ClipOval(
                  child: (avatar != null && avatar.isNotEmpty)
                      ? CommonImageView(
                          url: avatar,
                          cacheKey: me?.id,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: InitialsAvatar(
                            name: business,
                            size: 44,
                            radius: 100,
                          ),
                        )
                      : InitialsAvatar(name: business, size: 44, radius: 100),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Expanded(
          child: Obx(() {
            final me = _profile.me;
            final business =
                me?.supplierProfile?.businessName ?? me?.name ?? 'Supplier';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Good morning,',
                  size: 14,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
                MyText(
                  text: business,
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
        MyRippleEffect(
          onTap: () => setState(() => _accepting = !_accepting),
          radius: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: AppStyling().myDecoration(
              color: kSecondaryColor.withValues(alpha: .1),
              radius: 100,
              borderColor: kTransperentColor,
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accepting ? const Color(0xff34C759) : kGreyTextColor,
                  ),
                ),
                const SizedBox(width: 5),
                MyText(
                  text: _accepting ? 'ACCEPTING LEADS' : 'PAUSED',
                  size: 12,
                  weight: FontWeight.w600,
                  color: kBlackColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Obx(() {
          final unread = _notifications.unread.value;
          return MyRippleEffect(
            onTap: () async {
              await Get.to(() => const NotificationsPage());
              _notifications.refreshUnread();
            },
            radius: 20,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kGreyTextColor.withValues(alpha: .2),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: kBlackColor,
                      size: 20,
                    ),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: -2,
                    top: -2,
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
            ),
          );
        }),
      ],
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _profile = ProfileController.ensure();
    _profile.load();
    _notifications = NotificationsController.ensure();
    _notifications.refreshUnread();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
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
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kSecondaryColor,
                    width: 2,
                  ),
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
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() {
            final me = _profile.me;
            final business =
                me?.supplierProfile?.businessName ?? me?.name ?? 'Supplier';
            final isVerified = me?.supplierProfile?.approved == true;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                MyText(
                  text: _greeting(),
                  size: 13,
                  weight: FontWeight.w400,
                  color: const Color(0xFF757575),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: MyText(
                        text: business,
                        size: 16,
                        weight: FontWeight.w700,
                        color: kBlackColor,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: Color(0xFF2196F3),
                      ),
                    ],
                  ],
                ),
              ],
            );
          }),
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
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
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
                if (unread > 0)
                  Positioned(
                    right: 2,
                    top: 2,
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

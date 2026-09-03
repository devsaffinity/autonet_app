import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_round_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

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

  Size get preferredSize => Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
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
            CommonImageView(
              imagePath: Assets.imagesProfileImage,
              height: 46,
              width: 46,
              radius: 100,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
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
                    text: 'Alex Carter',
                    size: 16,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                ],
              ),
            ),
            MyRoundButton(
              borderColor: kGreyTextColor.withValues(alpha: .2),
              onTap: () {
                // Get.to(() => NotificationPage());
              },
              child: CommonImageView(
                height: 20,
                // imagePath: Assets.imagesNotificationIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractorHomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ContractorHomeAppBar({super.key});

  Size get preferredSize => Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
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
            CommonImageView(
              imagePath: Assets.imagesProfileImage,
              height: 46,
              width: 46,
              radius: 100,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
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
                    text: 'Alex Carter',
                    size: 16,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                ],
              ),
            ),
            MyRoundButton(
              borderColor: kGreyTextColor.withValues(alpha: .2),
              onTap: () {
                // Get.to(() => NotificationPage());
              },
              child: CommonImageView(
                height: 20,
                // imagePath: Assets.imagesNotificationIcon,
              ),
            ),
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
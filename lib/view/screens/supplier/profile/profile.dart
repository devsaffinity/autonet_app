import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/screens/supplier/dash_board/manage_catalog.dart';
import 'package:autonect/view/screens/supplier/dash_board/supplier_credits.dart';
import 'package:autonect/view/screens/supplier/profile/edit_supplier_profile.dart';
import 'package:autonect/view/screens/supplier/profile/supplier_access_tier_page.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/controller/buyer/notifications_controller.dart';
import 'package:autonect/view/screens/buyer/notifications/notifications_page.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Supplier account screen — and the supplier's only logout path.
class SupplierProfilePage extends StatefulWidget {
  const SupplierProfilePage({super.key});

  @override
  State<SupplierProfilePage> createState() => _SupplierProfilePageState();
}

class _SupplierProfilePageState extends State<SupplierProfilePage> {
  final ProfileController _profile = ProfileController.ensure();
  final NotificationsController _notifications = NotificationsController.ensure();

  @override
  void initState() {
    super.initState();
    _profile.load();
    _notifications.refreshUnread();
  }

  Color _kycColor(String status) {
    switch (status) {
      case 'APPROVED':
        return const Color(0xff34C759);
      case 'REJECTED':
        return kRedColor;
      default:
        return kSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(hasBackButton: false, title: 'Profile'),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final me = _profile.me;
              final sp = me?.supplierProfile;
              final business =
                  sp?.businessName ?? me?.name ?? 'Supplier';
              final avatar = me?.avatarUrl;
              final kycStatus =
                  sp?.kycStatus?.wire ?? 'SUBMITTED';
              final ratingAvg = sp?.ratingAvg ?? 0.0;
              final ratingCount = sp?.ratingCount ?? 0;
              final isVerified = sp?.approved == true;
              final ratingStr =
                  ratingCount > 0 ? ratingAvg.toStringAsFixed(1) : 'New';
              final ratingSub = ratingCount > 0
                  ? ' ($ratingCount ${ratingCount == 1 ? 'review' : 'reviews'})'
                  : (isVerified ? ' (Verified)' : '');

              return SupplierCard(
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Change profile photo',
                      child: InkWell(
                        onTap: _profile.changeAvatar,
                        customBorder: const CircleBorder(),
                        child: ExcludeSemantics(
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              children: [
                                Center(
                                  child: (avatar != null && avatar.isNotEmpty)
                                      ? CommonImageView(
                                          url: avatar,
                                          cacheKey: me?.id,
                                          height: 56,
                                          width: 56,
                                          radius: 100,
                                          fit: BoxFit.cover,
                                          errorWidget: CommonImageView(
                                            imagePath:
                                                Assets.imagesProfileImage,
                                            height: 56,
                                            width: 56,
                                            radius: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : CommonImageView(
                                          imagePath: Assets.imagesProfileImage,
                                          height: 56,
                                          width: 56,
                                          radius: 100,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                if (_profile.uploadingAvatar.value)
                                  const Positioned.fill(
                                    child: Center(
                                      child: SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: kSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: kSecondaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: kWhiteColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 10,
                                      color: kWhiteColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: MyText(
                                  text: business,
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: kBlackColor,
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: 'Edit Profile',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () async {
                                    await Get.to(() => const EditSupplierProfilePage());
                                    _profile.load();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kSecondaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 12,
                                          color: kSecondaryColor,
                                        ),
                                        SizedBox(width: 4),
                                        MyText(
                                          text: 'Edit',
                                          size: 11,
                                          weight: FontWeight.w700,
                                          color: kSecondaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              MyText(
                                text: ratingStr,
                                size: 14,
                                weight: FontWeight.w600,
                                color: kBlackColor,
                              ),
                              if (ratingSub.isNotEmpty)
                                MyText(
                                  text: ratingSub,
                                  size: 12,
                                  weight: FontWeight.w400,
                                  color: kGreyTextColor,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SupplierStatusBadge(
                            label: 'KYC $kycStatus',
                            color: _kycColor(kycStatus),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            SupplierMenuTile(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () async {
                await Get.to(() => const EditSupplierProfilePage());
                _profile.load();
              },
            ),
            SupplierMenuTile(
              icon: Icons.workspace_premium_outlined,
              label: 'Subscription & Plans',
              onTap: () async {
                await Get.to(() => const SupplierAccessTierPage());
                _profile.load();
              },
            ),
            SupplierMenuTile(
              icon: Icons.storefront_outlined,
              label: 'Business Profile',
              onTap: () async {
                await Get.to(() => const EditSupplierProfilePage());
                _profile.load();
              },
            ),
            SupplierMenuTile(
              icon: Icons.bolt_rounded,
              label: 'Credits',
              onTap: () => Get.to(() => const SupplierCreditsPage()),
            ),
            SupplierMenuTile(
              icon: Icons.inventory_2_outlined,
              label: 'Catalogue',
              onTap: () => Get.to(() => const ManageCatalogPage()),
            ),
            Obx(() {
              final unread = _notifications.unread.value;
              return SupplierMenuTile(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                trailingText: unread > 0
                    ? (unread > 99 ? '99+ new' : '$unread new')
                    : null,
                onTap: () async {
                  await Get.to(() => const NotificationsPage());
                  _notifications.refreshUnread();
                },
              );
            }),
            SupplierMenuTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              color: kRedColor,
              onTap: () => RoleController.to.signOut(),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

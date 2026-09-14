import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/screens/supplier/dash_board/manage_catalog.dart';
import 'package:autonect/view/screens/supplier/dash_board/supplier_credits.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Supplier account screen — and the supplier's only logout path.
class SupplierProfilePage extends StatelessWidget {
  const SupplierProfilePage({super.key});

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
    final ProfileController profile = ProfileController.ensure();

    return Scaffold(
      appBar: GeneralAppBar(hasBackButton: false, title: 'Profile'),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final me = profile.me;
              final business =
                  me?.supplierProfile?.businessName ?? me?.name ?? 'Supplier';
              final avatar = me?.avatarUrl;
              final kycStatus =
                  me?.supplierProfile?.kycStatus?.wire ?? 'SUBMITTED';

              return SupplierCard(
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Change profile photo',
                      child: InkWell(
                        onTap: profile.changeAvatar,
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
                                        )
                                      : InitialsAvatar(
                                          name: business,
                                          size: 56,
                                          radius: 100,
                                        ),
                                ),
                                if (profile.uploadingAvatar.value)
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
                          MyText(
                            text: business,
                            size: 16,
                            weight: FontWeight.w700,
                            color: kBlackColor,
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
                                text: '4.8',
                                size: 14,
                                weight: FontWeight.w600,
                                color: kBlackColor,
                              ),
                              MyText(
                                text: ' (Verified Supplier)',
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
              icon: Icons.bolt_rounded,
              label: 'Credits',
              onTap: () => Get.to(() => const SupplierCreditsPage()),
            ),
            SupplierMenuTile(
              icon: Icons.inventory_2_outlined,
              label: 'Catalogue',
              onTap: () => Get.to(() => const ManageCatalogPage()),
            ),
            SupplierMenuTile(
              icon: Icons.verified_user_outlined,
              label: 'KYC documents',
              onTap: () => Get.to(() => const SupplierRegistrationPage()),
            ),
            SupplierMenuTile(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () => Get.bottomSheet(
                MyBSheet(
                  btnText: 'Close',
                  onTap: Get.back,
                  body: Column(
                    children: [
                      MyText(
                        paddingTop: 10,
                        paddingBottom: 24,
                        text: 'No notifications yet',
                        size: 16,
                        weight: FontWeight.w600,
                        color: kGreyTextColor,
                      ),
                    ],
                  ),
                ),
                isScrollControlled: true,
              ),
            ),
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

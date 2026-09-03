import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/screens/supplier/dash_board/manage_catalog.dart';
import 'package:autonect/view/screens/supplier/dash_board/supplier_credits.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Supplier account screen — and the supplier's only logout path.
class SupplierProfilePage extends StatelessWidget {
  const SupplierProfilePage({super.key});

  /// SupplierProfile.kycStatus. PENDING and SUBMITTED read as in-flight,
  /// APPROVED as green, REJECTED as kRedColor.
  static const String _kycStatus = 'SUBMITTED';

  Color get _kycColor {
    switch (_kycStatus) {
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
            SupplierCard(
              child: Row(
                children: [
                  CommonImageView(
                    imagePath: Assets.imagesProfileImage,
                    height: 56,
                    width: 56,
                    radius: 100,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: 'AutoParts Hub',
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
                              text: ' (234 reviews)',
                              size: 12,
                              weight: FontWeight.w400,
                              color: kGreyTextColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SupplierStatusBadge(
                          label: 'KYC $_kycStatus',
                          color: _kycColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

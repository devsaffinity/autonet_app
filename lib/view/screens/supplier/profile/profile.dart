import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/view/screens/supplier/dash_board/manage_catalog.dart';
import 'package:autonect/view/screens/supplier/dash_board/supplier_credits.dart';
import 'package:autonect/view/screens/supplier/profile/supplier_access_tier_page.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/controller/buyer/notifications_controller.dart';
import 'package:autonect/view/screens/buyer/notifications/notifications_page.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_button.dart';
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
              onTap: () => _showEditBusinessDialog(context),
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
            SupplierMenuTile(
              icon: Icons.verified_user_outlined,
              label: 'KYC documents',
              onTap: () => Get.to(() => const SupplierRegistrationPage()),
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

  void _showEditBusinessDialog(BuildContext context) {
    final me = _profile.me;
    final sp = me?.supplierProfile;
    final nameCtrl = TextEditingController(
      text: sp?.businessName ?? me?.name ?? '',
    );
    final addrCtrl = TextEditingController(text: sp?.address ?? '');
    final specCtrl = TextEditingController(text: sp?.specialization ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kPrimaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const MyText(
                          text: 'Edit Business Profile',
                          size: 18,
                          weight: FontWeight.w700,
                          color: kBlackColor,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: kGreyTextColor),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const MyText(
                      text: 'Trading / Business Name',
                      size: 12,
                      weight: FontWeight.w600,
                      color: kGreyTextColor,
                      paddingBottom: 6,
                    ),
                    MyTextField(
                      controller: nameCtrl,
                      hintText: 'e.g. Apex Auto Spares Ltd',
                    ),
                    const SizedBox(height: 16),
                    const MyText(
                      text: 'Registered Address',
                      size: 12,
                      weight: FontWeight.w600,
                      color: kGreyTextColor,
                      paddingBottom: 6,
                    ),
                    MyTextField(
                      controller: addrCtrl,
                      hintText: 'e.g. 100 Great Suffolk St, London SE1 0BE',
                    ),
                    const SizedBox(height: 16),
                    const MyText(
                      text: 'Specialization / Description',
                      size: 12,
                      weight: FontWeight.w600,
                      color: kGreyTextColor,
                      paddingBottom: 6,
                    ),
                    MyTextField(
                      controller: specCtrl,
                      hintText:
                          'e.g. German OEM parts, brake systems, transmissions',
                    ),
                    const SizedBox(height: 24),
                    MyButton(
                      buttonText: isSaving ? 'Saving...' : 'Save Changes',
                      onTap: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final addr = addrCtrl.text.trim();
                              if (name.isEmpty) {
                                displayToast(msg: 'Business name is required');
                                return;
                              }
                              if (addr.isEmpty) {
                                displayToast(msg: 'Address is required');
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                final repo = Get.find<ProfileRepository>();
                                final draft = SupplierBusinessDraft(
                                  businessName: name,
                                  address: addr,
                                  regionsServed:
                                      sp?.regionsServed.isNotEmpty == true
                                          ? sp!.regionsServed
                                          : [Region.london],
                                  categoryIds:
                                      sp?.categories.isNotEmpty == true
                                          ? sp!.categories
                                              .map((c) => c.id)
                                              .toList()
                                          : [],
                                  brands: sp?.brands ?? [],
                                  specialization:
                                      specCtrl.text.trim().isNotEmpty
                                          ? specCtrl.text.trim()
                                          : null,
                                );

                                final res =
                                    await repo.registerSupplierBusiness(draft);
                                if (res case Ok()) {
                                  await _profile.updateProfileDetails(name: name);
                                  displayToast(
                                    msg: 'Business profile updated successfully',
                                  );
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  await _profile.load();
                                } else if (res case Err(:final error)) {
                                  displayToast(msg: error.message);
                                }
                              } finally {
                                if (ctx.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

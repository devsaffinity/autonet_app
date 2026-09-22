import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/catalog_controller.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/field_label.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-featured, production-ready Edit Profile screen for the Supplier / Seller role.
///
/// Manages both personal contact details (`PUT /v1/me/profile`) and
/// business registration specifications (`POST /v1/supplier/business`),
/// including operating regions, vehicle brands, and part categories.
class EditSupplierProfilePage extends StatefulWidget {
  const EditSupplierProfilePage({super.key});

  @override
  State<EditSupplierProfilePage> createState() => _EditSupplierProfilePageState();
}

class _EditSupplierProfilePageState extends State<EditSupplierProfilePage> {
  final ProfileController _profile = ProfileController.ensure();
  late final CatalogController _catalog;

  // Account / Contact controllers
  final TextEditingController _contactNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();

  // Business Profile controllers
  final TextEditingController _businessNameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _specializationCtrl = TextEditingController();

  // Multi-select state
  final Set<Region> _selectedRegions = <Region>{};
  final Set<String> _selectedBrands = <String>{};
  final Set<String> _selectedCategoryIds = <String>{};
  final List<String> _availableBrands = [
    'Audi',
    'BMW',
    'Ford',
    'Mercedes-Benz',
    'Nissan',
    'Peugeot',
    'Porsche',
    'Toyota',
    'Vauxhall',
    'Volkswagen',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _catalog = CatalogController.ensure();
    _catalog.load();
    _loadAndSeed();
  }

  Future<void> _loadAndSeed() async {
    // 1. Initial pre-seed from existing cache / memory
    _seedFields();

    // 2. Fetch fresh profile from server
    await _profile.load();

    // 3. Re-seed with fresh data if still mounted
    if (mounted) {
      _seedFields();
    }
  }

  void _seedFields() {
    final me = _profile.me;
    final tokenUser =
        Get.isRegistered<TokenStore>() ? Get.find<TokenStore>().user : null;

    final phone = (me?.effectivePhone != null && me!.effectivePhone!.isNotEmpty)
        ? me!.effectivePhone!
        : (tokenUser?.phone ?? '');
    final name = (me?.name != null && me!.name!.isNotEmpty)
        ? me!.name!
        : (tokenUser?.name ?? '');

    if (name.isNotEmpty) {
      _contactNameCtrl.text = name;
    }
    if (phone.isNotEmpty) {
      _phoneCtrl.text = phone;
    }
    if (me?.location != null && me!.location!.isNotEmpty) {
      _locationCtrl.text = me!.location!;
    }

    final sp = me?.supplierProfile;
    if (sp?.businessName != null && sp!.businessName.isNotEmpty) {
      _businessNameCtrl.text = sp.businessName;
    } else if (_businessNameCtrl.text.isEmpty && name.isNotEmpty) {
      _businessNameCtrl.text = name;
    }

    if (sp?.address != null && sp!.address.isNotEmpty) {
      _addressCtrl.text = sp.address;
    }
    if (sp?.specialization != null && sp!.specialization!.isNotEmpty) {
      _specializationCtrl.text = sp.specialization!;
    }

    // Regions
    if (sp?.regionsServed != null && sp!.regionsServed.isNotEmpty) {
      _selectedRegions.clear();
      _selectedRegions.addAll(sp.regionsServed);
    } else if (_selectedRegions.isEmpty) {
      _selectedRegions.add(Region.london);
    }

    // Brands
    if (sp?.brands != null && sp!.brands.isNotEmpty) {
      _selectedBrands.clear();
      _selectedBrands.addAll(sp.brands);
      for (final b in sp.brands) {
        if (!_availableBrands.contains(b)) {
          _availableBrands.add(b);
        }
      }
    }

    // Categories
    if (sp?.categories != null && sp!.categories.isNotEmpty) {
      _selectedCategoryIds.clear();
      _selectedCategoryIds.addAll(sp.categories.map((c) => c.id));
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _contactNameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _specializationCtrl.dispose();
    super.dispose();
  }

  void _showAddBrandDialog() {
    final newBrandCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPrimaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const MyText(
          text: 'Add Custom Brand',
          size: 16,
          weight: FontWeight.w700,
          color: kBlackColor,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MyText(
              text: 'Enter the vehicle brand or manufacturer name:',
              size: 13,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              paddingBottom: 10,
            ),
            MyTextField(
              controller: newBrandCtrl,
              hintText: 'e.g. Land Rover, Volvo, Ferrari',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const MyText(
              text: 'Cancel',
              size: 14,
              weight: FontWeight.w600,
              color: kGreyTextColor,
            ),
          ),
          TextButton(
            onPressed: () {
              final brand = newBrandCtrl.text.trim();
              if (brand.isNotEmpty) {
                setState(() {
                  if (!_availableBrands.contains(brand)) {
                    _availableBrands.add(brand);
                  }
                  _selectedBrands.add(brand);
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const MyText(
              text: 'Add',
              size: 14,
              weight: FontWeight.w700,
              color: kSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final businessName = _businessNameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final contactName = _contactNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final specialization = _specializationCtrl.text.trim();

    if (businessName.isEmpty) {
      displayToast(msg: 'Trading / Business name is required');
      return;
    }
    if (address.isEmpty) {
      displayToast(msg: 'Business address is required');
      return;
    }
    if (_selectedRegions.isEmpty) {
      displayToast(msg: 'Please select at least one operating region');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = Get.find<ProfileRepository>();
      final me = _profile.me;
      final tokenUser =
          Get.isRegistered<TokenStore>() ? Get.find<TokenStore>().user : null;
      final currentPhone = me?.effectivePhone ?? (tokenUser?.phone ?? '');
      final currentName = me?.name ?? (tokenUser?.name ?? '');
      final currentLocation = me?.location ?? '';

      final contactChanged = contactName.isNotEmpty && contactName != currentName;
      final locationChanged = location != currentLocation;
      final phoneChanged = phone != currentPhone;

      bool contactUpdated = false;
      if (contactChanged || locationChanged || phoneChanged) {
        final ok = await _profile.updateProfileDetails(
          name: contactName.isNotEmpty
              ? contactName
              : (currentName.isNotEmpty ? currentName : businessName),
          location: location.isNotEmpty ? location : null,
          contact: phone.isNotEmpty ? phone : null,
        );
        if (!ok) {
          displayToast(msg: 'Failed to update contact details');
          return;
        }
        contactUpdated = true;
      }

      // Check if business profile needs update
      final sp = me?.supplierProfile;
      final effectiveCategoryIds = _selectedCategoryIds.isNotEmpty
          ? _selectedCategoryIds.toList()
          : (sp?.categories.map((c) => c.id).toList() ?? []);

      final businessNameChanged = businessName != (sp?.businessName ?? '');
      final addressChanged = address != (sp?.address ?? '');
      final specChanged = specialization != (sp?.specialization ?? '');
      final regionsChanged = sp == null ||
          !setEquals(_selectedRegions, sp.regionsServed.toSet());
      final brandsChanged = sp == null ||
          !setEquals(_selectedBrands, sp.brands.toSet());
      final categoriesChanged = sp == null ||
          !setEquals(
              _selectedCategoryIds, sp.categories.map((c) => c.id).toSet());

      final needsBusinessUpdate = sp == null ||
          businessNameChanged ||
          addressChanged ||
          specChanged ||
          regionsChanged ||
          brandsChanged ||
          categoriesChanged;

      if (needsBusinessUpdate) {
        if (effectiveCategoryIds.isEmpty) {
          displayToast(msg: 'Please select at least one part category supplied');
          return;
        }

        final draft = SupplierBusinessDraft(
          businessName: businessName,
          address: address,
          regionsServed: _selectedRegions.toList(),
          categoryIds: effectiveCategoryIds,
          brands: _selectedBrands.toList(),
          specialization: specialization.isNotEmpty ? specialization : null,
        );

        final res = await repo.registerSupplierBusiness(draft);
        if (res case Ok()) {
          await _profile.load();
          displayToast(msg: 'Seller profile updated successfully');
          if (mounted) {
            Get.back(result: true);
          }
        } else if (res case Err(:final error)) {
          displayToast(msg: error.message);
        }
      } else {
        // Business profile wasn't modified, but personal/contact details were updated
        await _profile.load();
        displayToast(
          msg: contactUpdated
              ? 'Profile updated successfully'
              : 'No changes to save',
        );
        if (mounted) {
          Get.back(result: true);
        }
      }
    } catch (e) {
      displayToast(msg: 'Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Edit Profile'),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar Photo Header ─────────────────────────
            _buildAvatarSection(),
            const SizedBox(height: 20),

            // ── Business Details Section ────────────────────
            _buildBusinessInfoSection(),
            const SizedBox(height: 18),

            // ── Personal / Contact Person Section ───────────
            _buildContactInfoSection(),
            const SizedBox(height: 18),

            // ── Regions Served Section ──────────────────────
            _buildRegionsSection(),
            const SizedBox(height: 18),

            // ── Car Brands Supported Section ────────────────
            _buildBrandsSection(),
            const SizedBox(height: 18),

            // ── Part Categories Section ─────────────────────
            _buildCategoriesSection(),
            const SizedBox(height: 28),

            // ── Save Changes CTA Button ─────────────────────
            MyButton(
              buttonText: _isSaving ? 'Saving Changes...' : 'Save Profile Changes',
              height: 48,
              fontSize: 15,
              onTap: _isSaving ? null : _saveProfile,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Obx(() {
      final me = _profile.me;
      final avatar = me?.avatarUrl;

      return Center(
        child: Column(
          children: [
            Semantics(
              button: true,
              label: 'Change profile photo',
              child: InkWell(
                onTap: _profile.changeAvatar,
                customBorder: const CircleBorder(),
                child: ExcludeSemantics(
                  child: SizedBox(
                    width: 86,
                    height: 86,
                    child: Stack(
                      children: [
                        Center(
                          child: (avatar != null && avatar.isNotEmpty)
                              ? CommonImageView(
                                  url: avatar,
                                  cacheKey: me?.id,
                                  height: 80,
                                  width: 80,
                                  radius: 100,
                                  fit: BoxFit.cover,
                                  errorWidget: CommonImageView(
                                    imagePath: Assets.imagesProfileImage,
                                    height: 80,
                                    width: 80,
                                    radius: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : CommonImageView(
                                  imagePath: Assets.imagesProfileImage,
                                  height: 80,
                                  width: 80,
                                  radius: 100,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        if (_profile.uploadingAvatar.value)
                          const Positioned.fill(
                            child: Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: kSecondaryColor,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: kSecondaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kWhiteColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 13,
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
            const SizedBox(height: 8),
            const MyText(
              text: 'Tap to change company logo or avatar',
              size: 12,
              weight: FontWeight.w500,
              color: kGreyTextColor,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBusinessInfoSection() {
    return SupplierCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kSecondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(width: 10),
              const MyText(
                text: 'Business Information',
                size: 15,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const FieldLabel(
            text: 'Trading / Business Name',
            isRequired: true,
            size: 12,
            weight: FontWeight.w600,
            color: kGreyTextColor,
            paddingBottom: 6,
          ),
          MyTextField(
            controller: _businessNameCtrl,
            hintText: 'e.g. Apex Auto Spares Ltd',
          ),
          const SizedBox(height: 14),
          const FieldLabel(
            text: 'Registered Business Address',
            isRequired: true,
            size: 12,
            weight: FontWeight.w600,
            color: kGreyTextColor,
            paddingBottom: 6,
          ),
          MyTextField(
            controller: _addressCtrl,
            hintText: 'e.g. 100 Great Suffolk St, London SE1 0BE',
          ),
          const SizedBox(height: 14),
          const FieldLabel(
            text: 'Specialization & Description',
            size: 12,
            weight: FontWeight.w600,
            color: kGreyTextColor,
            paddingBottom: 6,
          ),
          MyTextField(
            controller: _specializationCtrl,
            maxLines: 3,
            hintText:
                'e.g. Specialist in German OEM automotive spares, braking systems and engine components.',
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    final me = _profile.me;

    return SupplierCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kSecondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(width: 10),
              const MyText(
                text: 'Account & Contact Details',
                size: 15,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const FieldLabel(
            text: 'Primary Contact Person',
            size: 12,
            weight: FontWeight.w600,
            color: kGreyTextColor,
            paddingBottom: 6,
          ),
          MyTextField(
            controller: _contactNameCtrl,
            hintText: 'e.g. John Doe',
          ),
          const SizedBox(height: 14),
          const FieldLabel(
            text: 'Contact Phone Number',
            size: 12,
            weight: FontWeight.w600,
            color: kGreyTextColor,
            paddingBottom: 6,
          ),
          MyTextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            hintText: 'e.g. +44 7911 123456',
          ),
          const SizedBox(height: 14),
          const FieldLabel(
            text: 'Location / City',
            size: 12,
            weight: FontWeight.w600,
            color: kGreyTextColor,
            paddingBottom: 6,
          ),
          MyTextField(
            controller: _locationCtrl,
            hintText: 'e.g. London, United Kingdom',
          ),
          if (me?.email != null) ...[
            const SizedBox(height: 14),
            const FieldLabel(
              text: 'Email Address (Registered)',
              size: 12,
              weight: FontWeight.w600,
              color: kGreyTextColor,
              paddingBottom: 6,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: MyText(
                text: me!.email,
                size: 14,
                weight: FontWeight.w500,
                color: const Color(0xFF777777),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegionsSection() {
    return SupplierCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: FieldLabel(
                  text: 'Operating Regions',
                  isRequired: true,
                  size: 15,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
              ),
              MyText(
                text: '${_selectedRegions.length} selected',
                size: 12,
                weight: FontWeight.w600,
                color: kSecondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const MyText(
            text: 'Select the regions where you can deliver parts and services:',
            size: 12,
            weight: FontWeight.w400,
            color: kGreyTextColor,
            paddingBottom: 12,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Region.values.map((region) {
              final isSelected = _selectedRegions.contains(region);
              return FilterChip(
                label: Text(region.label),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: kLightOrangeColor,
                backgroundColor: kPrimaryColor,
                side: BorderSide(
                  color: isSelected ? kSecondaryColor : const Color(0xFFDDDDDD),
                  width: isSelected ? 1.5 : 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? kSecondaryColor : kBlackColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedRegions.add(region);
                    } else {
                      if (_selectedRegions.length > 1) {
                        _selectedRegions.remove(region);
                      } else {
                        displayToast(msg: 'At least one operating region is required');
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsSection() {
    return SupplierCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: MyText(
                  text: 'Brands Supported',
                  size: 15,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
              ),
              MyRippleEffect(
                radius: 6,
                onTap: _showAddBrandDialog,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 14,
                        color: kSecondaryColor,
                      ),
                      SizedBox(width: 4),
                      MyText(
                        text: 'Add Brand',
                        size: 12,
                        weight: FontWeight.w700,
                        color: kSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const MyText(
            text: 'Select or add manufacturer brands you supply parts for:',
            size: 12,
            weight: FontWeight.w400,
            color: kGreyTextColor,
            paddingBottom: 12,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableBrands.map((brand) {
              final isSelected = _selectedBrands.contains(brand);
              return FilterChip(
                label: Text(brand),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: kLightOrangeColor,
                backgroundColor: kPrimaryColor,
                side: BorderSide(
                  color: isSelected ? kSecondaryColor : const Color(0xFFDDDDDD),
                  width: isSelected ? 1.5 : 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? kSecondaryColor : kBlackColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedBrands.add(brand);
                    } else {
                      _selectedBrands.remove(brand);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Obx(() {
      final categoriesState = _catalog.categories.value;
      final categories = switch (categoriesState) {
        Data(:final value) => value,
        _ => const <dynamic>[],
      };

      if (categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return SupplierCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: MyText(
                    text: 'Part Categories Supplied',
                    size: 15,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                  ),
                ),
                MyText(
                  text: '${_selectedCategoryIds.length} selected',
                  size: 12,
                  weight: FontWeight.w600,
                  color: kSecondaryColor,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const MyText(
              text: 'Choose which part categories your business supplies:',
              size: 12,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              paddingBottom: 12,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final id = cat.id as String;
                final name = cat.name as String;
                final isSelected = _selectedCategoryIds.contains(id);

                return FilterChip(
                  label: Text(name),
                  selected: isSelected,
                  showCheckmark: false,
                  selectedColor: kLightOrangeColor,
                  backgroundColor: kPrimaryColor,
                  side: BorderSide(
                    color: isSelected ? kSecondaryColor : const Color(0xFFDDDDDD),
                    width: isSelected ? 1.5 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? kSecondaryColor : kBlackColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategoryIds.add(id);
                      } else {
                        _selectedCategoryIds.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}

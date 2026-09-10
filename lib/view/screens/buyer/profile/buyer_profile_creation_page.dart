import 'dart:typed_data';

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_fonts.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/services/image_picker_service.dart';
import 'package:autonect/view/screens/buyer/profile/profile.dart';
import 'package:autonect/view/widget/animation_widget.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Buyer profile creation and editing screen.
///
/// Dual-purpose:
/// 1. [isInitialSetup] == true: Shown immediately after signup/OTP verification
///    so the buyer can complete their profile (photo, name, location, contact)
///    before entering the app. Tapping "Next" saves to the server and routes
///    to the buyer home shell.
/// 2. [isInitialSetup] == false: Opened from the Home header avatar or the
///    Profile/Settings page to update profile information.
class BuyerProfileCreationPage extends StatefulWidget {
  const BuyerProfileCreationPage({
    super.key,
    this.isInitialSetup = false,
    this.onComplete,
  });

  final bool isInitialSetup;
  final VoidCallback? onComplete;

  @override
  State<BuyerProfileCreationPage> createState() =>
      _BuyerProfileCreationPageState();
}

class _BuyerProfileCreationPageState extends State<BuyerProfileCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  final ProfileController _profile = ProfileController.ensure();
  final ImagePickerService _picker = Get.find<ImagePickerService>();

  PickedImage? _pickedImage;
  String? _imageError;
  bool _seeded = false;

  /// Max avatar size in bytes (2MB) matching design requirement.
  static const int _maxAvatarSizeBytes = 2 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _loadAndPrefill();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAndPrefill() async {
    // Read from TokenStore immediately so the form doesn't appear empty while
    // the network read finishes.
    if (Get.isRegistered<TokenStore>()) {
      final user = Get.find<TokenStore>().user;
      if (user?.name != null && user!.name!.isNotEmpty) {
        _nameCtrl.text = user.name!;
      }
    }

    await _profile.load();
    if (!mounted) return;

    final me = _profile.me;
    if (me != null && !_seeded) {
      if (me.name != null && me.name!.isNotEmpty) {
        _nameCtrl.text = me.name!;
      }
      if (me.location != null && me.location!.isNotEmpty) {
        _locationCtrl.text = me.location!;
      }
      if (me.phone != null && me.phone!.isNotEmpty) {
        _contactCtrl.text = me.phone!;
      }
      _seeded = true;
    }
    setState(() {});
  }

  Future<void> _pickImage() async {
    setState(() => _imageError = null);
    final picked = await _picker.pick(remaining: 1);
    final image = picked.firstOrNull;
    if (image == null) return;

    if (image.sizeBytes > _maxAvatarSizeBytes) {
      setState(() {
        _imageError = 'Image must be under 2MB';
      });
      _profile.toast('Image must be under 2MB');
      return;
    }

    setState(() {
      _pickedImage = image;
      _imageError = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final contact = _contactCtrl.text.trim();

    final success = await _profile.updateProfileDetails(
      name: name,
      location: location.isNotEmpty ? location : null,
      contact: contact.isNotEmpty ? contact : null,
      newAvatar: _pickedImage,
    );

    if (!mounted || !success) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    if (widget.isInitialSetup) {
      // Completed setup after signup: route to buyer shell.
      await RoleController.to.syncProviderAccess();
      Get.offAllNamed(RoleController.to.landingRoute);
    } else {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: _buildTopBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s20,
            vertical: AppSizes.s12,
          ),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                const SizedBox(height: AppSizes.s32),
                _buildProfileImageSection(),
                const SizedBox(height: AppSizes.s24),
                _buildFormFields(),
                const SizedBox(height: AppSizes.s24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: _buildBottomButton(),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      backgroundColor: kWhiteColor,
      elevation: 0,
      leading: !widget.isInitialSetup
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: kBlackColor,
              onPressed: () => Get.back(),
              tooltip: 'Back',
            )
          : const SizedBox.shrink(),
      actions: [
        if (!widget.isInitialSetup)
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24),
            color: kBlackColor,
            onPressed: () => Get.to(() => const BuyerProfilePage()),
            tooltip: 'Settings',
          ),
      ],
    );
  }

  Widget _buildTitle() {
    return Center(
      child: MyText(
        text: 'Profile Creation',
        size: 24,
        weight: FontWeight.w700,
        color: kSecondaryColor,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Profile Image',
          size: 14,
          weight: FontWeight.w600,
          color: kBlackColor,
          paddingBottom: 12,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatarPreview(),
            const SizedBox(width: AppSizes.s20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kSecondaryColor,
                    side: const BorderSide(color: kSecondaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s24,
                      vertical: AppSizes.s8,
                    ),
                  ),
                  child: MyText(
                    text: 'Upload',
                    size: 14,
                    weight: FontWeight.w600,
                    color: kSecondaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                MyText(
                  text: 'Image must be under 2MB',
                  size: 12,
                  weight: FontWeight.w400,
                  color: _imageError != null ? kRedColor : kGreyTextColor,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarPreview() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kWhiteColor,
        border: Border.all(color: kFieldBorderColor, width: 1.5),
      ),
      child: ClipOval(
        child: _buildAvatarContent(),
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_pickedImage != null) {
      return Image.memory(
        Uint8List.fromList(_pickedImage!.bytes),
        width: 90,
        height: 90,
        fit: BoxFit.cover,
      );
    }

    final avatarUrl = _profile.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CommonImageView(
        url: avatarUrl,
        cacheKey: _profile.me?.id,
        height: 90,
        width: 90,
        fit: BoxFit.cover,
      );
    }

    return const Center(
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: kGreyTextColor,
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyTextField(
          labelText: 'Name',
          hintText: 'Enter your full name',
          controller: _nameCtrl,
          radius: AppSizes.radiusSm,
          borderColor: kFieldBorderColor,
          marginBottom: AppSizes.s16,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        MyTextField(
          labelText: 'Location',
          hintText: 'West Lincon Road, Virginia',
          controller: _locationCtrl,
          radius: AppSizes.radiusSm,
          borderColor: kFieldBorderColor,
          marginBottom: AppSizes.s16,
          suffix: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.location_on_outlined,
              color: kSecondaryColor,
              size: 22,
            ),
          ),
        ),
        MyTextField(
          labelText: 'Contact',
          hintText: '+44 75 9876643',
          controller: _contactCtrl,
          radius: AppSizes.radiusSm,
          borderColor: kFieldBorderColor,
          keyboardType: TextInputType.phone,
          marginBottom: AppSizes.s16,
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.only(
        left: AppSizes.s20,
        right: AppSizes.s20,
        bottom: AppSizes.s32,
        top: AppSizes.s12,
      ),
      child: Obx(() {
        final busy = _profile.savingProfile.value;
        return MyButton(
          buttonText: busy ? 'Saving…' : (widget.isInitialSetup ? 'Next' : 'Save'),
          onTap: busy ? null : _submit,
          backgroundColor: busy
              ? kSecondaryColor.withValues(alpha: .6)
              : kSecondaryColor,
        );
      }),
    );
  }
}

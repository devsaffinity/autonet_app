import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/controller/electrician/electrician_registration_controller.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/enum_select_field.dart';
import 'package:autonect/view/widget/field_label.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A provider editing their own profile.
///
/// THE MISSING HALF OF REGISTRATION. The wizard writes a profile, but until now
/// nothing could change one — so a provider's headline and bio, the two fields
/// the buyer's directory card and profile screen actually render, stayed empty
/// forever unless a seed script filled them.
///
/// Same endpoint as registration: `POST /v1/electrician/registration` is an
/// UPSERT, so this is a re-submit rather than a new route, and it shares the
/// wizard's controller. That is also why the form pre-fills from the server —
/// the write REPLACES the row, so a field left blank here would be cleared.
class EditProviderProfilePage extends StatefulWidget {
  const EditProviderProfilePage({super.key});

  @override
  State<EditProviderProfilePage> createState() =>
      _EditProviderProfilePageState();
}

class _EditProviderProfilePageState extends State<EditProviderProfilePage> {
  final ProfileController _profile = ProfileController.ensure();
  final ElectricianRegistrationController c =
      ElectricianRegistrationController.ensure();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _headlineCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _vehiclesCtrl = TextEditingController();

  /// Guards against re-seeding the text fields on every rebuild, which would
  /// fight the cursor while somebody is typing.
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _profile.load();
    final provider = _profile.me?.electricianProfile;
    if (provider == null || !mounted) return;
    c.prefillFrom(provider);
    _nameCtrl.text = provider.fullName;
    _headlineCtrl.text = provider.headline ?? '';
    _bioCtrl.text = provider.bio ?? '';
    _phoneCtrl.text = provider.phone ?? '';
    _locationCtrl.text = provider.location ?? '';
    _vehiclesCtrl.text = provider.vehiclesServiced?.toString() ?? '';
    // setState, not a bare assignment: `_seeded` gates the Save button, and
    // the values above are plain TextEditingControllers that no Obx watches.
    // Without a rebuild the form fills in but Save stays disabled until some
    // unrelated frame happens to come along.
    setState(() => _seeded = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _vehiclesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await c.submit();
    if (saved == null || !mounted) return;
    // The approval state can move under an edit — an admin may have approved
    // or revoked in the meantime — so re-read rather than assume it held.
    await RoleController.to.syncProviderAccess();
    Get.back<void>(result: saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: GeneralAppBar(title: 'Edit Profile'),
      body: Obx(() {
        final state = _profile.profile.value;
        final error = c.formError.value;
        final busy = c.busy.value;
        final services = c.services.toSet();
        final brands = c.brands.toSet();
        final years = c.yearsExperience.value;
        final region = c.region.value;

        return StateView<MeProfile>(
          state: state,
          onRetry: _load,
          builder: (_, _) => SingleChildScrollView(
            padding: AppSizes.DEFAULT,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error != null) _errorBanner(error),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Semantics(
                      button: true,
                      label: 'Change profile photo',
                      child: InkWell(
                        onTap: _profile.changeAvatar,
                        customBorder: const CircleBorder(),
                        child: ExcludeSemantics(
                          child: SizedBox(
                            height: 96,
                            width: 96,
                            child: Obx(() {
                              final me = _profile.me;
                              final url = me?.avatarUrl;
                              final busy = _profile.uploadingAvatar.value;
                              final name = me?.electricianProfile?.fullName ??
                                  me?.name ??
                                  'Provider';

                              return Stack(
                                children: [
                                  Center(
                                    child: ClipOval(
                                      child: SizedBox(
                                        height: 88,
                                        width: 88,
                                        child: url != null && url.isNotEmpty
                                            ? CommonImageView(
                                                url: url,
                                                cacheKey: me?.id,
                                                height: 88,
                                                width: 88,
                                                fit: BoxFit.cover,
                                                errorWidget: InitialsAvatar(
                                                  name: name,
                                                  size: 88,
                                                  radius: 100,
                                                ),
                                              )
                                            : InitialsAvatar(
                                                name: name,
                                                size: 88,
                                                radius: 100,
                                              ),
                                      ),
                                    ),
                                  ),
                                  if (busy)
                                    const Positioned.fill(
                                      child: Center(
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: kSecondaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: kSecondaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: kPrimaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 14,
                                        color: kWhiteColor,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: GestureDetector(
                      onTap: _profile.changeAvatar,
                      child: MyText(
                        text: 'Change Profile Photo',
                        size: 13,
                        weight: FontWeight.w600,
                        color: kSecondaryColor,
                      ),
                    ),
                  ),
                ),
                _label('YOUR NAME'),
                MyTextField(
                  controller: _nameCtrl,
                  labelText: 'Full Name',
                  isRequired: true,
                  onChanged: (v) => c.fullName.value = v,
                ),
                MyTextField(
                  controller: _headlineCtrl,
                  labelText: 'Headline',
                  // The line under their name on the buyer's card. Saying what
                  // it is FOR is what stops it being left blank.
                  hintText: 'e.g. ECU Specialist',
                  onChanged: (v) => c.headline.value = v,
                ),
                MyTextField(
                  controller: _bioCtrl,
                  labelText: 'About your work',
                  hintText: 'What you do, and what you are known for.',
                  maxLines: 5,
                  radius: 16,
                  onChanged: (v) => c.bio.value = v,
                ),

                _label('CONTACT'),
                MyTextField(
                  controller: _phoneCtrl,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  hintText: '07700 900000',
                  onChanged: (v) => c.phone.value = v,
                ),
                MyTextField(
                  controller: _locationCtrl,
                  labelText: 'Location',
                  hintText: 'e.g. Camden, London',
                  onChanged: (v) => c.location.value = v,
                ),
                EnumSelectField<Region>(
                  title: 'Region',
                  hint: 'Select a region',
                  value: region,
                  options: [
                    for (final r in Region.values) SelectOption(r, r.label),
                  ],
                  onChanged: (r) => c.region.value = r,
                ),

                _label('WHAT YOU DO', isRequired: true),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in BookingServiceType.values)
                      _chip(
                        label: s.label,
                        selected: services.contains(s),
                        onTap: () => c.toggleService(s),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _label('BRANDS YOU WORK ON'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in _brandOptions)
                      _chip(
                        label: b,
                        selected: brands.contains(b),
                        onTap: () => c.toggleBrand(b),
                      ),
                  ],
                ),

                const SizedBox(height: 20),
                _label('EXPERIENCE'),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: years.toDouble(),
                        max: 25,
                        divisions: 25,
                        activeColor: kSecondaryColor,
                        inactiveColor: kTertiaryColor,
                        onChanged: (v) => c.setExperience(v.round()),
                      ),
                    ),
                    MyText(
                      text: '$years yrs',
                      size: 13,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                    ),
                  ],
                ),
                MyTextField(
                  controller: _vehiclesCtrl,
                  labelText: 'Vehicles serviced',
                  keyboardType: TextInputType.number,
                  hintText: 'Leave blank if you would rather not say',
                  // Blank means NULL, not zero: '0 vehicles serviced' on a
                  // profile card is worse than no counter at all.
                  onChanged: (v) =>
                      c.vehiclesServiced.value = int.tryParse(v.trim()),
                ),

                const SizedBox(height: 24),
                MyButton(
                  buttonText: 'Save profile',
                  enabled: _seeded && !busy,
                  loading: busy,
                  onTap: _save,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// The marques the registration wizard offers, kept in step with it.
  static const List<String> _brandOptions = [
    'BMW',
    'Audi',
    'Tesla',
    'Porsche',
    'Mercedes-Benz',
  ];

  Widget _label(String text, {bool isRequired = false}) => FieldLabel(
    text: text,
    isRequired: isRequired,
    size: 10,
    weight: FontWeight.w700,
    color: kSecondaryColor,
    letterSpacing: 1,
    paddingTop: 16,
    paddingBottom: 12,
  );

  Widget _errorBanner(String message) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: AppStyling().myDecoration(
      color: kLightOrangeColor,
      borderColor: kLightOrangeColor,
      radius: 12,
    ),
    child: MyText(
      text: message,
      size: 13,
      weight: FontWeight.w500,
      color: kBlackColor,
    ),
  );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => MyRippleEffect(
    onTap: onTap,
    radius: 100,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: AppStyling().myDecoration(
        color: selected ? kLightOrangeColor : kTertiaryColor,
        borderColor: selected ? kSecondaryColor : kTertiaryColor,
        radius: 100,
      ),
      child: MyText(
        text: label,
        size: 12,
        weight: FontWeight.w600,
        color: selected ? kSecondaryColor : kBlackColor,
      ),
    ),
  );
}

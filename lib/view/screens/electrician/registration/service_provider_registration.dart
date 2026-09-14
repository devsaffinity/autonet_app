import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/controller/electrician/availability_controller.dart';
import 'package:autonect/controller/electrician/electrician_registration_controller.dart';
import 'package:autonect/controller/supplier/supplier_kyc_controller.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/kyc_status.dart';
import 'package:autonect/data/models/provider_schedule.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/screens/supplier/widgets/access_tier.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/dashed_border.dart';
import 'package:autonect/view/widget/enum_select_field.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The 5-step Service Provider Registration wizard matching the Figma design:
/// 1. Basic Info (Service Provider Registration)
/// 2. Professional Details (Services)
/// 3. KYC
/// 4. Set Availability (Availability)
/// 5. Tier Selection (Access Tier)
class ServiceProviderRegistrationPage extends StatefulWidget {
  const ServiceProviderRegistrationPage({super.key});

  @override
  State<ServiceProviderRegistrationPage> createState() =>
      _ServiceProviderRegistrationPageState();
}

class _ServiceProviderRegistrationPageState
    extends State<ServiceProviderRegistrationPage> {
  final PageController _pageController = PageController();
  final ElectricianRegistrationController c =
      ElectricianRegistrationController.ensure();

  AvailabilityController? get _availCtrl {
    try {
      return AvailabilityController.ensure();
    } catch (_) {
      return null;
    }
  }

  SupplierKycController? get _kycCtrl {
    try {
      return SupplierKycController.ensure();
    } catch (_) {
      return null;
    }
  }

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();

  static const List<String> _stepTitles = [
    'Service Provider Registration',
    'Services',
    'KYC',
    'Availability',
    'Access Tier',
  ];

  static const List<String> _stepSubtitles = [
    'Basic Info',
    'Professional Details',
    'KYC',
    'Set Availability',
    'Tier Selection',
  ];

  int _currentStep = 0;

  // ── Services ──────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _serviceOptions = [
    {
      'label': 'ECU Coding',
      'icon': Icons.code,
      'type': BookingServiceType.ecuCoding,
    },
    {
      'label': 'Diagnostics',
      'icon': Icons.search,
      'type': BookingServiceType.diagnostic,
    },
    {
      'label': 'Wiring & Harness',
      'icon': Icons.cable,
      'type': BookingServiceType.repair,
    },
    {
      'label': 'Battery Calibration',
      'icon': Icons.battery_charging_full,
      'type': BookingServiceType.inspection,
    },
    {
      'label': 'Infotainment Retrofit',
      'icon': Icons.directions_car,
      'type': BookingServiceType.installation,
    },
    {
      'label': 'Performance Tuning',
      'icon': Icons.speed,
      'type': BookingServiceType.ecuCoding,
    },
  ];

  final Set<String> _selectedServiceLabels = {'ECU Coding'};

  // ── Brands ─────────────────────────────────────────────────────────────────
  final List<Map<String, String>> _brands = [
    {
      'label': 'BMW',
      'logo':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR74zviXeAq7WMnx06zhZD-M6X95EdONNq9BA&s',
    },
    {
      'label': 'Audi',
      'logo':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR74zviXeAq7WMnx06zhZD-M6X95EdONNq9BA&s',
    },
    {
      'label': 'Tesla',
      'logo':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR74zviXeAq7WMnx06zhZD-M6X95EdONNq9BA&s',
    },
    {
      'label': 'Porsche',
      'logo':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR74zviXeAq7WMnx06zhZD-M6X95EdONNq9BA&s',
    },
    {
      'label': 'Mercedes-Benz',
      'logo':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR74zviXeAq7WMnx06zhZD-M6X95EdONNq9BA&s',
    },
    {
      'label': 'Others',
      'logo': '',
    },
  ];

  // ── Step 3 KYC Upload State ────────────────────────────────────────────────
  String? _frontDocName;
  String? _licenseDocName;

  // ── Step 4 Availability State ──────────────────────────────────────────────
  final List<Map<String, dynamic>> _days = [
    {'short': 'MON', 'full': 'Monday', 'date': 22},
    {'short': 'TUE', 'full': 'Tuesday', 'date': 23},
    {'short': 'WED', 'full': 'Wednesday', 'date': 24},
    {'short': 'THU', 'full': 'Thursday', 'date': 25},
    {'short': 'FRI', 'full': 'Friday', 'date': 26},
    {'short': 'SAT', 'full': 'Saturday', 'date': 27},
    {'short': 'SUN', 'full': 'Sunday', 'date': 28},
  ];

  int _selectedDayIndex = 0;

  final Map<int, List<Map<String, String>>> _timeSlots = {
    0: [
      {'start': '08:00', 'end': '12:00'},
      {'start': '01:30', 'end': '06:00'},
    ],
  };

  List<Map<String, String>> get _currentSlots =>
      _timeSlots[_selectedDayIndex] ?? [];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = c.fullName.value;
    _phoneCtrl.text = c.phone.value;
    _locationCtrl.text = c.location.value;
    if (c.yearsExperience.value == 0) {
      c.setExperience(12);
    }
    // Seed services
    if (c.services.isEmpty) {
      c.services.add(BookingServiceType.ecuCoding);
    } else {
      for (final s in c.services) {
        for (final opt in _serviceOptions) {
          if (opt['type'] == s) {
            _selectedServiceLabels.add(opt['label'] as String);
          }
        }
      }
    }
    // Seed brands if empty
    if (c.brands.isEmpty) {
      c.toggleBrand('BMW');
    }
    // Pre-load KYC status if controller is available
    _kycCtrl?.load();
  }

  Future<void> _next() async {
    if (_currentStep == 0) {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        displayToast(msg: 'Please enter your full name');
        return;
      }
      final phone = _phoneCtrl.text.trim();
      if (phone.isNotEmpty && phone.length < 7) {
        displayToast(msg: 'Please enter a valid phone number (at least 7 digits)');
        return;
      }
      c.fullName.value = name;
      c.phone.value = phone;
      c.location.value = _locationCtrl.text.trim();
    } else if (_currentStep == 1) {
      if (c.services.isEmpty) {
        displayToast(msg: 'Pick at least one service you offer');
        return;
      }
      c.fullName.value = _nameCtrl.text.trim();
      c.phone.value = _phoneCtrl.text.trim();
      c.location.value = _locationCtrl.text.trim();

      // Ensure profile exists in PostgreSQL before moving to KYC step,
      // so S3 presigned tickets and document confirmations succeed.
      final profile = await c.submit();
      if (profile == null) {
        displayToast(msg: c.formError.value ?? 'Please check your information');
        return;
      }
      _kycCtrl?.load();
    }

    if (_currentStep < _stepTitles.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      if (_currentStep == 2) {
        _kycCtrl?.load();
      }
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  Future<void> _finish() async {
    _saveAvailabilitySchedule();

    final profile = await c.submit();
    if (profile == null) return;

    RoleController.to.completeProviderOnboarding();
    await RoleController.to.syncProviderAccess();
    Get.offAllNamed(RoleController.to.landingRoute);
  }

  void _saveAvailabilitySchedule() {
    try {
      final avail = _availCtrl;
      if (avail == null) return;
      for (int i = 0; i < 7; i++) {
        final weekday = i + 1; // 1 = Mon .. 7 = Sun
        final slots = _timeSlots[i];
        if (slots != null && slots.isNotEmpty) {
          final bands = <AvailabilityBand>{};
          for (final slot in slots) {
            final startH =
                int.tryParse(slot['start']?.split(':').first ?? '') ?? 8;
            final endH =
                int.tryParse(slot['end']?.split(':').first ?? '') ?? 17;
            if (startH < 12) bands.add(AvailabilityBand.morning);
            if (startH < 17 && endH >= 12) {
              bands.add(AvailabilityBand.afternoon);
            }
            if (endH >= 17) bands.add(AvailabilityBand.evening);
          }
          if (bands.isEmpty) bands.add(AvailabilityBand.morning);
          avail.draft[weekday] = bands;
        } else {
          avail.draft[weekday] = <AvailabilityBand>{};
        }
      }
      avail.save();
    } catch (_) {}
  }

  void _saveForLater() {
    displayToast(msg: 'Progress saved');
    if (_nameCtrl.text.trim().isNotEmpty) {
      c.fullName.value = _nameCtrl.text.trim();
      c.submit();
    }
    Get.back();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        surfaceTintColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: _back,
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: kBlackColor,
            size: 18,
          ),
        ),
        title: MyText(
          text: "Create Profile",
          size: 18,
          weight: FontWeight.w700,
          color: kBlackColor,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText(
                      text: "Step ${_currentStep + 1} Of ${_stepTitles.length}",
                      size: 12,
                      weight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                    MyText(
                      text: _stepSubtitles[_currentStep],
                      size: 12,
                      weight: FontWeight.w500,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(_stepTitles.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? kSecondaryColor
                              : kSecondaryColor.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
          _buildStep4(),
          _buildStep5(),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // STEP 1 — Basic Info (Service Provider Registration)
  // ───────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                MyText(
                  text: "Service Provider Registration",
                  size: 20,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                ),
                const SizedBox(height: 6),
                MyText(
                  text:
                      "Let's start with the essentials. Tell us who you are and where you'll be operating.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                ),
                MyTextField(
                  controller: _nameCtrl,
                  labelText: 'Full Name',
                  hintText: 'e.g. Jack Brennan',
                  onChanged: (v) => c.fullName.value = v,
                ),
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
                  suffix: const Icon(
                    Icons.location_on_outlined,
                    color: kSecondaryColor,
                    size: 20,
                  ),
                ),
                Obx(
                  () => EnumSelectField<Region>(
                    title: 'Region',
                    hint: 'Select a region',
                    value: c.region.value,
                    options: [
                      for (final r in Region.values) SelectOption(r, r.label),
                    ],
                    onChanged: (r) => c.region.value = r,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  width: double.infinity,
                  decoration: AppStyling().myDecoration(
                    color: kSecondaryColor.withValues(alpha: .08),
                    borderColor: kTransperentColor,
                    radius: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: kSecondaryColor,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(
                              paddingBottom: 4,
                              text: "Privacy First",
                              size: 13,
                              color: kBlackColor,
                              weight: FontWeight.w700,
                            ),
                            MyText(
                              text:
                                  "Your data is encrypted and used solely for identity verification in our partner ecosystem.",
                              size: 11,
                              weight: FontWeight.w400,
                              color: kGreyTextColor,
                              lineHeight: 1.4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _BottomButton(label: 'Continue', onTap: _next),
      ],
    );
  }

  // ───────────────────────────────────────────────
  // STEP 2 — Professional Details (Services)
  // ───────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: "Services",
                  size: 20,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                ),
                const SizedBox(height: 16),
                MyText(
                  text: "Services Offered",
                  size: 16,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                const SizedBox(height: 4),
                MyText(
                  text:
                      "Select all specialized services you provide in your workshop.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _serviceOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemBuilder: (_, i) {
                    final item = _serviceOptions[i];
                    final label = item['label'] as String;
                    final icon = item['icon'] as IconData;
                    final type = item['type'] as BookingServiceType;
                    final isSelected = _selectedServiceLabels.contains(label);

                    return MyRippleEffect(
                      radius: 10,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedServiceLabels.remove(label);
                            c.services.remove(type);
                          } else {
                            _selectedServiceLabels.add(label);
                            c.services.add(type);
                          }
                        });
                      },
                      child: Container(
                        decoration: AppStyling().myDecoration(
                          color: isSelected
                              ? kLightOrangeColor
                              : kTertiaryColor,
                          borderColor: isSelected
                              ? kSecondaryColor
                              : kTertiaryColor,
                          radius: 10,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: isSelected
                                  ? kSecondaryColor
                                  : kGreyTextColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: MyText(
                                text: label,
                                size: 12,
                                weight: FontWeight.w600,
                                color: isSelected
                                    ? kSecondaryColor
                                    : kBlackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                MyText(
                  text: "Years of Experience",
                  size: 16,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                const SizedBox(height: 4),
                MyText(
                  text:
                      "How long have you been operating in the automotive sector?",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
                const SizedBox(height: 10),
                _buildExperienceSlider(),
                const SizedBox(height: 24),
                MyText(
                  text: "Brands Supported",
                  size: 16,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                const SizedBox(height: 4),
                MyText(
                  text:
                      "Choose the manufacturers you are certified to work on.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _brands.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (_, i) {
                    final brand = _brands[i];
                    final label = brand['label']!;
                    final logo = brand['logo']!;
                    final isSelected = c.brands.contains(label);

                    return MyRippleEffect(
                      radius: 12,
                      onTap: () {
                        setState(() {
                          c.toggleBrand(label);
                        });
                      },
                      child: Container(
                        decoration: AppStyling().myDecoration(
                          color: kPrimaryColor,
                          thickness: 1.8,
                          borderColor: isSelected
                              ? kSecondaryColor
                              : kTertiaryColor,
                          radius: 12,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            logo.isNotEmpty
                                ? Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: kTertiaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CommonImageView(
                                        url: logo,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: kLightOrangeColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '•••',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: kSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 8),
                            MyText(
                              text: label,
                              size: 14,
                              weight: FontWeight.w700,
                              color: kBlackColor,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _BottomButton(label: 'Next', onTap: _next),
      ],
    );
  }

  Widget _buildExperienceSlider() {
    return Obx(() => Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: kSecondaryColor,
                inactiveTrackColor: kTertiaryColor,
                thumbColor: kSecondaryColor,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                trackHeight: 3,
              ),
              child: Slider(
                value: c.yearsExperience.value.toDouble(),
                min: 0,
                max: 25,
                divisions: 25,
                label: '${c.yearsExperience.value} yrs',
                onChanged: (v) => c.setExperience(v.round()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText(text: '0 YRS', size: 11, color: kGreyTextColor),
                  MyText(
                    text: '${c.yearsExperience.value} YEARS',
                    size: 11,
                    weight: FontWeight.w700,
                    color: kSecondaryColor,
                  ),
                  MyText(text: '25+ YRS', size: 11, color: kGreyTextColor),
                ],
              ),
            ),
          ],
        ));
  }

  // ───────────────────────────────────────────────
  // STEP 3 — KYC
  // ───────────────────────────────────────────────
  Widget _buildStep3() {
    final kyc = _kycCtrl;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: "KYC",
                  size: 20,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                ),
                const SizedBox(height: 6),
                MyText(
                  text:
                      "To ensure a secure environment for the Autonect network, please provide valid business documentation and personal identification.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  lineHeight: 1.4,
                ),
                const SizedBox(height: 20),

                // Error message banner if any
                if (kyc != null)
                  Obx(() {
                    final err = kyc.formError.value;
                    if (err == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kRedColor.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: kRedColor.withValues(alpha: .4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: kRedColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MyText(
                              text: err,
                              size: 11,
                              color: kRedColor,
                              weight: FontWeight.w500,
                              lineHeight: 1.3,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                // Section 1: Identity Document
                _buildKycHeader(
                  icon: Icons.badge_outlined,
                  title: "Identity Document (ID)",
                  subtitle: "Passport or National ID Card",
                ),
                const SizedBox(height: 14),

                if (kyc != null)
                  Obx(() {
                    final idDoc = kyc.current?.documentFor(KycDocType.id);
                    final isUploaded = idDoc?.uploaded ?? false;
                    final isBusy = kyc.uploading.value == KycDocType.id ||
                        kyc.picking.value == KycDocType.id;

                    return _buildUploadDashedBox(
                      label: isBusy
                          ? "Uploading ID document..."
                          : isUploaded
                              ? (idDoc?.fileName ?? "Identity Document Uploaded ✓")
                              : (_frontDocName ?? "Click to upload ID (Passport or Driver's License)"),
                      hint: isUploaded
                          ? (idDoc?.displaySize != null
                              ? "Size: ${idDoc!.displaySize} • Tap to replace"
                              : "Tap to replace document")
                          : "PDF, JPEG or PNG (Max 10MB)",
                      isUploaded: isUploaded || _frontDocName != null,
                      isLoading: isBusy,
                      isLarge: true,
                      onTap: () async {
                        await kyc.pickAndUpload(KycDocType.id);
                        if (kyc.current?.hasUploaded(KycDocType.id) ?? false) {
                          setState(() {
                            _frontDocName = "Identity Document Uploaded ✓";
                          });
                        }
                      },
                    );
                  })
                else
                  _buildUploadDashedBox(
                    label: _frontDocName ?? "Click to upload ID document",
                    hint: "PDF, JPEG or PNG (Max 10MB)",
                    isUploaded: _frontDocName != null,
                    isLarge: true,
                    onTap: () {},
                  ),

                const SizedBox(height: 14),

                // Info warning box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: kSecondaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MyText(
                          text:
                              "Ensure all four corners are visible and the image is not blurry or overexposed.",
                          size: 11,
                          color: kSecondaryColor,
                          weight: FontWeight.w500,
                          lineHeight: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Business License / Proof
                _buildKycHeader(
                  icon: Icons.description_outlined,
                  title: "Business License / Proof",
                  subtitle: "Tax certificate or Operating Permit",
                ),
                const SizedBox(height: 14),

                if (kyc != null)
                  Obx(() {
                    final licenseDoc =
                        kyc.current?.documentFor(KycDocType.license);
                    final isUploaded = licenseDoc?.uploaded ?? false;
                    final isBusy = kyc.uploading.value == KycDocType.license ||
                        kyc.picking.value == KycDocType.license;

                    return _buildUploadDashedBox(
                      label: isBusy
                          ? "Uploading Licence..."
                          : isUploaded
                              ? (licenseDoc?.fileName ?? "Business License Uploaded ✓")
                              : (_licenseDocName ?? "Click to upload document"),
                      hint: isUploaded
                          ? (licenseDoc?.displaySize != null
                              ? "Size: ${licenseDoc!.displaySize} • Tap to replace"
                              : "Tap to replace document")
                          : "PDF, JPEG or PNG (Max 10MB)",
                      isLarge: true,
                      isUploaded: isUploaded || _licenseDocName != null,
                      isLoading: isBusy,
                      onTap: () async {
                        await kyc.pickAndUpload(KycDocType.license);
                        if (kyc.current?.hasUploaded(KycDocType.license) ??
                            false) {
                          setState(() {
                            _licenseDocName = "Business License Uploaded ✓";
                          });
                        }
                      },
                    );
                  })
                else
                  _buildUploadDashedBox(
                    label: _licenseDocName ?? "Click to upload document",
                    hint: "PDF, JPEG or PNG (Max 10MB)",
                    isLarge: true,
                    isUploaded: _licenseDocName != null,
                    onTap: () {},
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          color: kPrimaryColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyButton(
                buttonText: 'Continue to Schedule',
                onTap: _next,
              ),
              const SizedBox(height: 10),
              MyButton(
                buttonText: 'Save for Later',
                backgroundColor: kPrimaryColor,
                outlineColor: kSecondaryColor,
                fontColor: kSecondaryColor,
                onTap: _saveForLater,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKycHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kSecondaryColor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kSecondaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              text: title,
              size: 15,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
            MyText(
              text: subtitle,
              size: 11,
              weight: FontWeight.w400,
              color: kGreyTextColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadDashedBox({
    required String label,
    String? hint,
    required bool isUploaded,
    bool isLoading = false,
    bool isLarge = false,
    required VoidCallback onTap,
  }) {
    return DashedBorder(
      radius: 12,
      color: isUploaded
          ? kSecondaryColor
          : kGreyTextColor.withValues(alpha: .4),
      strokeWidth: 1.2,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: isLarge ? 120 : 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUploaded
                ? kSecondaryColor.withValues(alpha: .06)
                : kPrimaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: kSecondaryColor,
                  ),
                )
              else
                Icon(
                  isUploaded
                      ? Icons.check_circle
                      : (isLarge
                          ? Icons.cloud_upload_outlined
                          : Icons.cloud_upload_outlined),
                  size: isLarge ? 32 : 24,
                  color: isUploaded ? kSecondaryColor : kSecondaryColor,
                ),
              const SizedBox(height: 6),
              MyText(
                text: label,
                size: 12,
                weight: FontWeight.w600,
                color: isUploaded ? kSecondaryColor : kBlackColor,
                textAlign: TextAlign.center,
              ),
              if (hint != null) ...[
                const SizedBox(height: 2),
                MyText(
                  text: hint,
                  size: 10,
                  weight: FontWeight.w400,
                  color: isUploaded
                      ? kSecondaryColor.withValues(alpha: .8)
                      : kGreyTextColor,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // STEP 4 — Set Availability
  // ───────────────────────────────────────────────
  Widget _buildStep4() {
    final dayData = _days[_selectedDayIndex];
    final dayFull = dayData['full'] as String;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: "Availability",
                  size: 20,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                ),
                const SizedBox(height: 6),
                MyText(
                  text:
                      "Set up your regular business hours so customers can book appointments with you seamlessly.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  lineHeight: 1.4,
                ),
                const SizedBox(height: 20),

                MyText(
                  text: "Weekly Operation",
                  size: 16,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                const SizedBox(height: 4),
                MyText(
                  text: "Select a day and pick a slot",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
                const SizedBox(height: 16),

                // Days selector
                _buildDaySelector(),
                const SizedBox(height: 24),

                // Active Time Slots header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText(
                      text: "Active Time Slots ($dayFull)",
                      size: 14,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                    ),
                    MyRippleEffect(
                      radius: 8,
                      onTap: _addSlot,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              color: kSecondaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            MyText(
                              text: "ADD SLOT",
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
                const SizedBox(height: 14),

                // Slot list
                if (_currentSlots.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppStyling().myDecoration(
                      color: kTertiaryColor,
                      borderColor: kTertiaryColor,
                      radius: 10,
                    ),
                    child: MyText(
                      text: "No slots added for this day. Tap + ADD SLOT to add.",
                      size: 12,
                      color: kGreyTextColor,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentSlots.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildSlotCard(i),
                  ),

                const SizedBox(height: 20),

                // Apply to all weekdays button
                MyButton(
                  buttonText: 'APPLY TO ALL WEEKDAYS',
                  backgroundColor: kPrimaryColor,
                  fontColor: kSecondaryColor,
                  outlineColor: kSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 46,
                  onTap: _applyToAllWeekdays,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _BottomButton(label: 'Continue', onTap: _next),
      ],
    );
  }

  Widget _buildDaySelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: _days.length,
      itemBuilder: (_, i) {
        final day = _days[i];
        final isSelected = _selectedDayIndex == i;
        final hasSlots =
            _timeSlots.containsKey(i) && _timeSlots[i]!.isNotEmpty;

        Color bgColor;
        Color textColor;
        Color borderColor;

        if (isSelected) {
          bgColor = kSecondaryColor;
          textColor = kWhiteColor;
          borderColor = kSecondaryColor;
        } else if (hasSlots) {
          bgColor = kLightOrangeColor;
          textColor = kSecondaryColor;
          borderColor = kLightOrangeColor;
        } else {
          bgColor = kTertiaryColor;
          textColor = kGreyTextColor;
          borderColor = kTertiaryColor;
        }

        return MyRippleEffect(
          onTap: () => setState(() => _selectedDayIndex = i),
          radius: 10,
          child: Container(
            decoration: AppStyling().myDecoration(
              color: bgColor,
              borderColor: borderColor,
              radius: 10,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyText(
                  text: day['short'] as String,
                  size: 11,
                  weight: FontWeight.w600,
                  color: textColor,
                ),
                const SizedBox(height: 4),
                MyText(
                  text: '${day['date']}',
                  size: 20,
                  weight: FontWeight.w700,
                  color: textColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotCard(int slotIndex) {
    final slot = _currentSlots[slotIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppStyling().myDecoration(
        color: kTertiaryColor,
        borderColor: kTertiaryColor,
        radius: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pickTime(slotIndex, isStart: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'START TIME',
                    size: 10,
                    weight: FontWeight.w500,
                    color: kGreyTextColor,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: kGreyTextColor.withValues(alpha: .2),
                      ),
                    ),
                    child: MyText(
                      text: slot['start'] ?? '08:00',
                      size: 13,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickTime(slotIndex, isStart: false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'END TIME',
                    size: 10,
                    weight: FontWeight.w500,
                    color: kGreyTextColor,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: kGreyTextColor.withValues(alpha: .2),
                      ),
                    ),
                    child: MyText(
                      text: slot['end'] ?? '12:00',
                      size: 13,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => _removeSlot(slotIndex),
            icon: const Icon(
              Icons.delete_outline,
              color: kRedColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _addSlot() {
    setState(() {
      _timeSlots.putIfAbsent(_selectedDayIndex, () => []);
      _timeSlots[_selectedDayIndex]!.add({'start': '09:00', 'end': '17:00'});
    });
  }

  void _removeSlot(int index) {
    setState(() {
      _timeSlots[_selectedDayIndex]?.removeAt(index);
    });
  }

  Future<void> _pickTime(int slotIndex, {required bool isStart}) async {
    final currentStr = isStart
        ? _timeSlots[_selectedDayIndex]![slotIndex]['start'] ?? '08:00'
        : _timeSlots[_selectedDayIndex]![slotIndex]['end'] ?? '17:00';
    final parts = currentStr.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: int.tryParse(parts.last) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kSecondaryColor,
            onPrimary: kWhiteColor,
            onSurface: kBlackColor,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        final formatted =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _timeSlots[_selectedDayIndex]![slotIndex]['start'] = formatted;
        } else {
          _timeSlots[_selectedDayIndex]![slotIndex]['end'] = formatted;
        }
      });
    }
  }

  void _applyToAllWeekdays() {
    final current = _currentSlots;
    setState(() {
      for (int i = 0; i < _days.length; i++) {
        _timeSlots[i] = current.map((s) => Map<String, String>.from(s)).toList();
      }
    });
    displayToast(msg: 'Time slots applied to all weekdays');
  }

  // ───────────────────────────────────────────────
  // STEP 5 — Access Tier
  // ───────────────────────────────────────────────
  Widget _buildStep5() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: "Access Tier",
                  size: 20,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                ),
                const SizedBox(height: 6),
                MyText(
                  text:
                      "Configure how you'd like to receive leads and manage your service portfolio on the Autonect network.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  lineHeight: 1.4,
                ),
                const SizedBox(height: 20),
                AccessTier(
                  onPlanSelected: (plan) {
                    displayToast(msg: 'Selected $plan tier');
                    _finish();
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          color: kPrimaryColor,
          child: MyButton(
            buttonText: 'Skip for Now',
            onTap: _finish,
          ),
        ),
      ],
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BottomButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: kPrimaryColor,
      child: MyButton(buttonText: label, onTap: onTap),
    );
  }
}


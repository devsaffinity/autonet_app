import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceProviderRegistrationPage extends StatefulWidget {
  const ServiceProviderRegistrationPage({super.key});

  @override
  State<ServiceProviderRegistrationPage> createState() =>
      _ServiceProviderRegistrationPageState();
}

class _ServiceProviderRegistrationPageState
    extends State<ServiceProviderRegistrationPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  void _next() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  /// End of the electrician KYC wizard. Until this runs, landingRoute (and the
  /// RoleGuard on every shell route) holds the provider on
  /// /electrician/onboarding, so the last step must not be a dead end.
  void _finish() {
    RoleController.to.completeProviderOnboarding();
    Get.offAllNamed(AppLinks.electricianShell);
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

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  // ── Services ──────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _services = [
    {'label': 'ECU Coding', 'icon': Icons.code},
    {'label': 'Diagnostics', 'icon': Icons.search},
    {'label': 'Wiring & Harness', 'icon': Icons.cable},
    {'label': 'Battery Calibration', 'icon': Icons.battery_charging_full},
    {'label': 'Infotainment Retrofit', 'icon': Icons.directions_car},
    {'label': 'Performance Tuning', 'icon': Icons.speed},
  ];
  final Set<String> _selectedServices = {'ECU Coding'};

  // ── Slider ─────────────────────────────────────────────────────────────────
  double _experience = 12;

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
      'logo':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR74zviXeAq7WMnx06zhZD-M6X95EdONNq9BA&s',
    },
  ];
  String _selectedBrand = 'BMW';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: Column(
          children: [
            MyText(
              text: _currentStep == 0
                  ? 'Service Provider Registration'
                  : (_currentStep == 1)
                  ? 'Services'
                  : (_currentStep == 2)
                  ? "KYC"
                  : (_currentStep == 3)
                  ? "Availability"
                  : "Access Tier",
              size: 18,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
          ],
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText(
                      text: "Step ${_currentStep + 1} of 5",
                      size: 12,
                      weight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                    MyText(
                      text: "Basic Info",
                      size: 12,
                      weight: FontWeight.w500,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
                SizedBox(height: 12),

                Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
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
  // STEP 1 — Registration + Vehicle Details
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
                MyText(
                  text:
                      "Let's start with the essentials. Tell us who you are and where you'll be operating.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),

                MyTextField(labelText: 'Full Name', hintText: 'e.g. Elon Musk'),
                MyTextField(
                  labelText: 'Phone Number',
                  hintText: '+1 (555) 000-0000',
                ),
                MyTextField(
                  labelText: 'Location',
                  hintText: 'e.g. New York, NY',
                ),

                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  width: Get.width,
                  decoration: AppStyling().myDecoration(
                    color: kSecondaryColor.withValues(alpha: .1),
                    borderColor: kTransperentColor,
                    radius: 9,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.safety_check_outlined, color: kSecondaryColor),

                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(
                              paddingBottom: 3,
                              text: "Privacy First",
                              size: 12,
                              color: kBlackColor,
                              weight: FontWeight.w600,
                            ),
                            MyText(
                              text:
                                  """Your data is encrypted and used solely for identity verification in our partner ecosystem.""",
                              size: 12,
                              weight: FontWeight.w400,
                              color: kGreyTextColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomButton(label: 'Continue', onTap: _next),
      ],
    );
  }

  // ───────────────────────────────────────────────
  // STEP 2 — Part Details + Upload
  // ───────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: "Services Offered",
                  size: 18,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                const SizedBox(height: 4),
                MyText(
                  text:
                      "Select all specialized services you provide in your workshop.",
                  size: 13,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _services.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.6,
                  ),
                  itemBuilder: (_, i) {
                    final service = _services[i];
                    final label = service['label'] as String;
                    final isSelected = _selectedServices.contains(label);

                    return MyRippleEffect(
                      radius: 10,
                      onTap: () => setState(() {
                        isSelected
                            ? _selectedServices.remove(label)
                            : _selectedServices.add(label);
                      }),
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
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              service['icon'] as IconData,
                              size: 20,
                              color: isSelected
                                  ? kSecondaryColor
                                  : kGreyTextColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: MyText(
                                text: label,
                                size: 13,
                                weight: FontWeight.w500,
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
                const SizedBox(height: 20),
                MyText(
                  text: "Years of Experience",
                  size: 18,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                const SizedBox(height: 4),
                MyText(
                  text:
                      "How long have you been operating in the automotive sector?",
                  size: 13,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),

                const SizedBox(height: 10),
                _buildExperienceSlider(),
                const SizedBox(height: 24),

                MyText(
                  text: "Brands Supported",
                  size: 18,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
                const SizedBox(height: 4),
                MyText(
                  text:
                      "Choose the manufacturers you are certified to work on.",
                  size: 13,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _brands.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (_, i) {
                    final brand = _brands[i];
                    final label = brand['label']!;
                    final logo = brand['logo']!;
                    final isSelected = _selectedBrand == label;

                    return MyRippleEffect(
                      radius: 12,
                      onTap: () => setState(() => _selectedBrand = label),
                      child: Container(
                        decoration: AppStyling().myDecoration(
                          color: kPrimaryColor,
                          thickness: 2,
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
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: kTertiaryColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: CommonImageView(
                                        url: logo,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: kLightOrangeColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '•••',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: kSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 10),
                            MyText(
                              text: label,
                              size: 16,
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
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
        _BottomButton(label: 'Next', onTap: _next),
      ],
    );
  }

  // ── Experience slider ───
  Widget _buildExperienceSlider() {
    return Column(
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
            value: _experience,
            min: 0,
            max: 25,
            onChanged: (v) => setState(() => _experience = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(text: '0 YRS', size: 11, color: kGreyTextColor),
              MyText(text: '12 YEARS', size: 11, color: kGreyTextColor),
              MyText(text: '25+ YRS', size: 11, color: kGreyTextColor),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────
  // STEP 3 — Review & Send Request
  // ───────────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text:
                      "To ensure a secure environment for the AutoVolt Velocity network, please provide valid business documentation and personal identification.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),
                const SizedBox(height: 20),

                // ── Identity Document (ID)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppStyling().myShadowStyle(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleRow(
                        icon: Assets.imagesKycA,
                        title: "Identity Document (ID)",
                        subTitle: "Passport or National ID Card",
                      ),
                      SizedBox(height: 15),
                      CommonImageView(svgPath: Assets.imagesFrontButton),
                      SizedBox(height: 10),
                      CommonImageView(svgPath: Assets.imagesBackButton),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(12),
                        width: Get.width,
                        decoration: AppStyling().myDecoration(
                          color: kSecondaryColor.withValues(alpha: .1),
                          borderColor: kTransperentColor,
                          radius: 9,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_sharp,
                              color: kSecondaryColor,
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: MyText(
                                text:
                                    """Your data is encrypted and used solely for identity verification in our partner ecosystem.""",
                                size: 12,
                                weight: FontWeight.w400,
                                color: kBlackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppStyling().myShadowStyle(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleRow(
                        icon: Assets.imagesKycB,
                        title: "Business License / Proof",
                        subTitle: "Tax certificate or Operating Permit",
                      ),
                      SizedBox(height: 15),
                      CommonImageView(svgPath: Assets.imagesUploadDocButton),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                MyButton(
                  fontWeight: FontWeight.w700,
                  buttonText: 'Continue to Schedule',
                  onTap: _next,
                ),
                const SizedBox(height: 10),
                MyButton(
                  fontWeight: FontWeight.w700,
                  fontColor: kBlackColor,
                  outlineColor: kSecondaryColor,
                  backgroundColor: kWhiteColor,
                  buttonText: 'Save for Later',
                  onTap: _next,
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────
  // STEP 4
  // ───────────────────────────────────────────────
  Widget _buildStep4() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text:
                      "To ensure a secure environment for the AutoVolt Velocity network, please provide valid business documentation and personal identification.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppStyling().myShadowStyle(),
                  child: _Availability(),
                ),

                const SizedBox(height: 30),
                MyButton(
                  fontWeight: FontWeight.w700,
                  buttonText: 'Continue',
                  onTap: _next,
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────
  // STEP 4
  // ───────────────────────────────────────────────
  Widget _buildStep5() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text:
                      "Configure how you'd like to receive leads and manage your service portfolio on the AutoVolt network.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),

                AccessTier(onPlanSelected: (_) => _finish()),

                const SizedBox(height: 30),
                MyButton(
                  fontWeight: FontWeight.w700,
                  buttonText: 'Skip for Now',
                  onTap: _finish,
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String icon, title, subTitle;
  const _TitleRow({
    required this.icon,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonImageView(svgPath: icon),

        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              text: title,
              size: 18,
              weight: FontWeight.w700,
              paddingBottom: 1,
            ),
            MyText(
              text: subTitle,
              size: 12,
              weight: FontWeight.w400,
              color: kGreyTextColor,
            ),
          ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Usage in your main code:
//   body: _Availability()
// ─────────────────────────────────────────────────────────────────────────────

class _Availability extends StatefulWidget {
  const _Availability();

  @override
  State<_Availability> createState() => __AvailabilityState();
}

class __AvailabilityState extends State<_Availability> {
  // ── Days ───────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _days = [
    {'short': 'MON', 'date': 22},
    {'short': 'TUE', 'date': 23},
    {'short': 'WED', 'date': 24},
    {'short': 'THU', 'date': 25},
    {'short': 'FRI', 'date': 26},
    {'short': 'SAT', 'date': 27},
    {'short': 'SUN', 'date': 28},
  ];

  int _selectedDayIndex = 0;

  // ── Time Slots — keyed by day index ───────────────────────────────────────
  // Each slot: { 'start': '08:00', 'end': '12:00' }
  final Map<int, List<Map<String, String>>> _timeSlots = {
    0: [
      {'start': '08:00', 'end': '12:00'},
      {'start': '01:30', 'end': '06:00'},
    ],
  };

  List<Map<String, String>> get _currentSlots =>
      _timeSlots[_selectedDayIndex] ?? [];

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _addSlot() {
    setState(() {
      _timeSlots.putIfAbsent(_selectedDayIndex, () => []);
      _timeSlots[_selectedDayIndex]!.add({'start': '09:00', 'end': '17:00'});
    });
  }

  void _removeSlot(int slotIndex) {
    setState(() {
      _timeSlots[_selectedDayIndex]?.removeAt(slotIndex);
    });
  }

  void _applyToAllWeekdays() {
    final currentSlots = List<Map<String, String>>.from(
      _currentSlots.map((s) => Map<String, String>.from(s)),
    );
    setState(() {
      // Weekdays = MON(0) TUE(1) WED(2) THU(3) FRI(4)
      for (int i = 0; i <= 4; i++) {
        _timeSlots[i] = List<Map<String, String>>.from(
          currentSlots.map((s) => Map<String, String>.from(s)),
        );
      }
    });
  }

  Future<void> _pickTime(
    BuildContext context,
    int slotIndex,
    bool isStart,
  ) async {
    final currentStr = isStart
        ? _currentSlots[slotIndex]['start']!
        : _currentSlots[slotIndex]['end']!;

    final parts = currentStr.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
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

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──────────────────────────────────────────────────────────
          MyText(
            text: 'Weekly Operation',
            size: 18,
            weight: FontWeight.w700,
            color: kBlackColor,
          ),

          MyText(
            text: 'Select a day and pick a slot',
            size: 12,
            weight: FontWeight.w400,
            color: kGreyTextColor,
          ),
          const SizedBox(height: 20),

          // ── Day Selector ───────────────────────────────────────────────────
          _buildDaySelector(),
          const SizedBox(height: 28),

          // ── Active Time Slots Header ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text:
                    'Active Time Slots (${_days[_selectedDayIndex]['short']}${_days[_selectedDayIndex]['short'] == 'MON'
                        ? 'day'
                        : _days[_selectedDayIndex]['short'] == 'TUE'
                        ? 'sday'
                        : _days[_selectedDayIndex]['short'] == 'WED'
                        ? 'nesday'
                        : _days[_selectedDayIndex]['short'] == 'THU'
                        ? 'rsday'
                        : _days[_selectedDayIndex]['short'] == 'FRI'
                        ? 'day'
                        : _days[_selectedDayIndex]['short'] == 'SAT'
                        ? 'urday'
                        : 'day'})',
                size: 15,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
              MyRippleEffect(
                onTap: _addSlot,
                radius: 8,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: kSecondaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      MyText(
                        text: 'ADD SLOT',
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
          const SizedBox(height: 16),

          // ── Time Slot Cards ────────────────────────────────────────────────
          if (_currentSlots.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: AppStyling().myDecoration(
                color: kTertiaryColor,
                borderColor: kTertiaryColor,
              ),
              child: MyText(
                text: 'No slots added. Tap + ADD SLOT to add.',
                size: 13,
                color: kGreyTextColor,
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentSlots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _buildTimeSlotCard(i),
            ),

          const SizedBox(height: 28),

          // ── Apply to All Weekdays ──────────────────────────────────────────
          MyButton(
            buttonText: 'APPLY TO ALL WEEKDAYS',
            backgroundColor: kPrimaryColor,
            fontColor: kSecondaryColor,
            outlineColor: kSecondaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 48,
            icon: 'assets/images/copy_icon.png', // replace with your asset
            haveSvg: false,
            onTap: _applyToAllWeekdays,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Day Selector Grid ──────────────────────────────────────────────────────
  Widget _buildDaySelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: _days.length,
      itemBuilder: (_, i) {
        final day = _days[i];
        final isSelected = _selectedDayIndex == i;
        final hasSlots = _timeSlots.containsKey(i) && _timeSlots[i]!.isNotEmpty;

        // Color logic
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
                  text: day['short'],
                  size: 11,
                  weight: FontWeight.w600,
                  color: textColor,
                ),
                const SizedBox(height: 4),
                MyText(
                  text: '${day['date']}',
                  size: 22,
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

  // ── Time Slot Card ────────
  Widget _buildTimeSlotCard(int slotIndex) {
    final slot = _currentSlots[slotIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: AppStyling().myDecoration(
        color: kTertiaryColor,
        borderColor: kTertiaryColor,
        radius: 12,
      ),
      child: Row(
        children: [
          // START TIME
          Expanded(
            child: _timeField(
              label: 'START TIME',
              value: slot['start']!,
              onTap: () => _pickTime(context, slotIndex, true),
            ),
          ),
          const SizedBox(width: 12),
          // END TIME
          Expanded(
            child: _timeField(
              label: 'END TIME',
              value: slot['end']!,
              onTap: () => _pickTime(context, slotIndex, false),
            ),
          ),
          const SizedBox(width: 12),
          // DELETE
          MyRippleEffect(
            onTap: () => _removeSlot(slotIndex),
            radius: 8,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: const Icon(
                Icons.delete_outline,
                color: kSecondaryColor,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: label,
            size: 10,
            weight: FontWeight.w700,
            color: kGreyTextColor,
            paddingBottom: 6,
          ),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: AppStyling().myDecoration(
              color: kPrimaryColor,
              borderColor: kTertiaryColor,
              radius: 8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: MyText(
                text: value,
                size: 15,
                weight: FontWeight.w500,
                color: kBlackColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Usage in your main code:
//   body: AccessTier()
// ─────────────────────────────────────────────────────────────────────────────

class AccessTier extends StatelessWidget {
  /// Fired when a plan is chosen. Optional so `AccessTier()` still compiles
  /// wherever the widget is only being displayed (e.g. a pricing sheet).
  final ValueChanged<String>? onPlanSelected;

  const AccessTier({super.key, this.onPlanSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Free Card ─────────────────────────────────────────────────────
          _PricingCard(
            tag: 'Entry',
            tagColor: kGreyTextColor,
            title: 'Free',
            price: '\$0',
            period: '/Lifetime',
            features: const [
              _Feature(label: 'Basic Company Profile', enabled: true),
              _Feature(label: 'Public Listing In Directory', enabled: true),
              _Feature(label: 'Standard Email Support', enabled: true),
              _Feature(label: 'Direct Client Leads', enabled: false),
            ],
            buttonText: 'Choose Basic',
            isHighlighted: false,
            onTap: () => onPlanSelected?.call('FREE'),
          ),
          const SizedBox(height: 16),

          // ── Pro Card ──────────────────────────────────────────────────────
          _PricingCard(
            tag: 'Growth',
            tagColor: kWhiteColor,
            title: 'Pro (Monthly)',
            price: '\$149',
            period: '/Month',
            features: const [
              _Feature(label: 'Unlimited High-Intent Leads', enabled: true),
              _Feature(label: 'Premium Badge & Verified Status', enabled: true),
              _Feature(label: 'Advanced Analytics Dashboard', enabled: true),
              _Feature(label: '24/7 Priority Concierge', enabled: true),
            ],
            buttonText: 'Start Pro Trial',
            isHighlighted: true,
            showBestValue: true,
            onTap: () => onPlanSelected?.call('PRO'),
          ),
          const SizedBox(height: 16),

          // ── Pay-Per-Lead Card ─────────────────────────────────────────────
          _PricingCard(
            tag: 'Flexible',
            tagColor: kSecondaryColor,
            title: 'Pay-Per-Lead',
            price: '\$12',
            period: '/Per Lead',
            features: const [
              _Feature(label: 'Credit-Based System', enabled: true),
              _Feature(label: 'No Fixed Monthly Fees', enabled: true),
              _Feature(label: 'Select Leads Manually', enabled: true),
              _Feature(label: 'Top-Up Credits Anytime', enabled: true),
            ],
            buttonText: 'Choose Credits',
            isHighlighted: false,
            onTap: () => onPlanSelected?.call('PAY_PER_LEAD'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal feature model
// ─────────────────────────────────────────────────────────────────────────────
class _Feature {
  final String label;
  final bool enabled;
  const _Feature({required this.label, required this.enabled});
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Pricing Card
// ─────────────────────────────────────────────────────────────────────────────
class _PricingCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final String title;
  final String price;
  final String period;
  final List<_Feature> features;
  final String buttonText;
  final bool isHighlighted;
  final bool showBestValue;
  final VoidCallback onTap;

  const _PricingCard({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.buttonText,
    required this.isHighlighted,
    required this.onTap,
    this.showBestValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBg = isHighlighted ? kSecondaryColor : kPrimaryColor;
    final Color titleColor = isHighlighted ? kWhiteColor : kBlackColor;
    final Color priceColor = isHighlighted ? kWhiteColor : kBlackColor;
    final Color periodColor = isHighlighted
        ? kWhiteColor.withOpacity(0.75)
        : kGreyTextColor;
    final Color featureColor = isHighlighted ? kWhiteColor : kBlackColor;
    final Color iconColor = isHighlighted ? kWhiteColor : kSecondaryColor;
    final Color disabledColor = isHighlighted
        ? kWhiteColor.withOpacity(0.4)
        : kGreyTextColor;

    return Container(
      decoration: AppStyling().myShadowDecoration(
        color: cardBg,
        radius: 16,
        borderColor: kTransperentColor,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tag ─────────────────────────────────────────────────────
                MyText(
                  text: tag,
                  size: 12,
                  weight: FontWeight.w500,
                  color: tagColor,
                  paddingBottom: 6,
                ),

                // ── Title ────────────────────────────────────────────────────
                MyText(
                  text: title,
                  size: isHighlighted ? 26 : 22,
                  weight: FontWeight.w800,
                  color: titleColor,
                  paddingBottom: 12,
                ),

                // ── Price row ────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MyText(
                      text: price,
                      size: 36,
                      weight: FontWeight.w800,
                      color: priceColor,
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: MyText(
                        text: period,
                        size: 14,
                        weight: FontWeight.w400,
                        color: periodColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Features ─────────────────────────────────────────────────
                ...features.map(
                  (f) => _FeatureRow(
                    label: f.label,
                    enabled: f.enabled,
                    enabledColor: iconColor,
                    labelColor: f.enabled ? featureColor : disabledColor,
                    isHighlighted: isHighlighted,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Button ───────────────────────────────────────────────────
                MyButton(
                  buttonText: buttonText,
                  onTap: onTap,
                  backgroundColor: isHighlighted
                      ? kPrimaryColor
                      : kSecondaryColor,
                  fontColor: isHighlighted ? kSecondaryColor : kWhiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 50,
                  radius: 100,
                ),
              ],
            ),
          ),

          // ── "Best Value" badge ───────────────────────────────────────────
          if (showBestValue)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: MyText(
                  text: 'Best Value',
                  size: 12,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature row with check / disabled icon
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color enabledColor;
  final Color labelColor;
  final bool isHighlighted;

  const _FeatureRow({
    required this.label,
    required this.enabled,
    required this.enabledColor,
    required this.labelColor,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            enabled
                ? Icons.check_circle_outline_rounded
                : Icons.do_not_disturb_on_outlined,
            size: 18,
            color: enabled
                ? enabledColor
                : isHighlighted
                ? kWhiteColor.withOpacity(0.35)
                : kGreyTextColor.withOpacity(0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MyText(
              text: label,
              size: 14,
              weight: FontWeight.w400,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/electrician/electrician_registration_controller.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration_kyc.dart';
import 'package:autonect/view/widget/enum_select_field.dart';
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
  final ElectricianRegistrationController c =
      ElectricianRegistrationController.ensure();

  /// Screens own their TextEditingControllers and dispose them; the controller
  /// owns the VALUES. The fields here had no controllers at all, so everything
  /// typed on this step was discarded on the way to the next one.
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();

  /// AVAILABILITY AND ACCESS TIER ARE GONE, and both for a reason.
  ///
  /// The availability step let a provider set arbitrary start and end times per
  /// day. The schedule this product stores is weekday + half-day BAND, so
  /// every one of those times would have been silently dropped on submit.
  /// Working hours are set from the dashboard's Availability screen, which
  /// writes the model that actually exists — and a provider cannot be booked
  /// before an admin approves them anyway, so nothing is lost by setting them
  /// after.
  ///
  /// The Access Tier step offered a plan picker. Billing is SUPPLIER-only by
  /// design — `ElectricianProfile` has no credit balance and nothing bills a
  /// provider — so it could only ever have taken a choice nobody would honour.
  static const List<String> _stepTitles = ['Basic Info', 'Services', 'KYC'];

  int _currentStep = 0;

  void _next() {
    if (_currentStep < _stepTitles.length - 1) {
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

  /// End of the wizard: SUBMIT, then land wherever the server says.
  ///
  /// This used to set a local `providerOnboarded` flag and push the shell,
  /// submitting nothing. Once the approval gate started reading server truth
  /// that became a loop — the next launch found no profile and sent them back
  /// here. Now the registration is written first, and the profile that comes
  /// back decides the destination.
  ///
  /// REGISTERING IS NOT BEING APPROVED. An admin still has to approve, so a
  /// successful submit usually lands on the awaiting-approval screen, not the
  /// shell. `syncProviderAccess` re-reads and `landingRoute` routes.
  Future<void> _finish() async {
    final profile = await c.submit();
    // Null means the submit failed and the controller has already surfaced
    // why. Staying put is the point: navigating on would strand them in a
    // shell their profile does not exist for.
    if (profile == null) return;

    RoleController.to.completeProviderOnboarding();
    await RoleController.to.syncProviderAccess();
    Get.offAllNamed(RoleController.to.landingRoute);
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
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ── Services ──────────────────────────────────────────────────────────────
  //
  // FROM THE ENUM, not from six labels of its own. The step used to offer
  // 'Wiring & Harness', 'Battery Calibration', 'Infotainment Retrofit' and
  // similar, none of which are values BookingServiceType has — so nothing it
  // collected could have been submitted, and none of it would have matched
  // the chips a buyer filters the directory with. These are the buyer's own
  // words for the same five callouts, which is the point of the field.
  static const Map<BookingServiceType, IconData> _serviceIcons = {
    BookingServiceType.diagnostic: Icons.search,
    BookingServiceType.ecuCoding: Icons.code,
    BookingServiceType.installation: Icons.directions_car,
    BookingServiceType.repair: Icons.cable,
    BookingServiceType.inspection: Icons.fact_check_outlined,
  };



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
  ];


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
              text: _stepTitles[_currentStep],
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
                      text: "Step ${_currentStep + 1} of ${_stepTitles.length}",
                      size: 12,
                      weight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                    MyText(
                      text: _stepTitles[_currentStep],
                      size: 12,
                      weight: FontWeight.w500,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
                SizedBox(height: 12),

                Row(
                  children: List.generate(_stepTitles.length, (index) {
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

                // The hints were US: '+1 (555) 000-0000' and 'New York, NY' in
                // a UK-only product. The region below is what the buyer's
                // directory filter actually joins on, so a provider who skips
                // it is invisible to a filtered search — worth asking for here
                // rather than leaving them to wonder why nobody calls.
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
                  itemCount: BookingServiceType.values.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.6,
                  ),
                  itemBuilder: (_, i) {
                    final service = BookingServiceType.values[i];
                    final label = service.label;
                    final isSelected = c.services.contains(service);

                    return MyRippleEffect(
                      radius: 10,
                      onTap: () => c.toggleService(service),
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
                              _serviceIcons[service],
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
                    // MULTI-SELECT: the column is a list and a provider
                    // realistically services several marques. A single
                    // choice could only ever have sent one.
                    final isSelected = c.brands.contains(label);

                    return MyRippleEffect(
                      radius: 12,
                      onTap: () => c.toggleBrand(label),
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
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(text: '0 YRS', size: 11, color: kGreyTextColor),
              // The middle label read a fixed '12 YEARS' while the thumb moved
              // independently of it — it now says where the thumb actually is.
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
  // STEP 3 — Review & Send Request
  // ───────────────────────────────────────────────
  // ───────────────────────────────────────────────
  // STEP 3 — Identity documents
  // ───────────────────────────────────────────────
  //
  // The SUPPLIER step widget, reused verbatim. The KYC routes are gated to
  // SUPPLIER *and* ELECTRICIAN, and the flow is identical: three documents,
  // each picked, uploaded to a presigned PUT and confirmed. Only the class
  // name says supplier.
  //
  // What was here before drew three upload cards with no onTap at all, under
  // copy about the "AutoVolt Velocity network" — a product that does not
  // exist. Nothing could be uploaded and nothing was.
  Widget _buildStep3() => SupplierKycStep(onNext: _finish);
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


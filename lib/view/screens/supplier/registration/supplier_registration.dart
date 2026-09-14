import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/controller/supplier/supplier_registration_controller.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_business_step.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration_kyc.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration_plan.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Supplier registration — three steps over one PageView.
///
/// No step counter or progress bar: the design shows none, and the first step
/// is now the whole of POST /v1/supplier/business rather than three pages of
/// it.
class SupplierRegistrationPage extends StatefulWidget {
  const SupplierRegistrationPage({super.key});

  @override
  State<SupplierRegistrationPage> createState() =>
      _SupplierRegistrationPageState();
}

class _SupplierRegistrationPageState extends State<SupplierRegistrationPage> {
  final PageController _pageController = PageController();
  // Fresh per wizard: an abandoned half-filled registration must not reappear
  // the next time this opens.
  final SupplierRegistrationController _c =
      SupplierRegistrationController.ensure();
  int _currentStep = 0;

  static const List<String> _titles = [
    'Business Registration',
    'KYC',
    'Subscription',
  ];

  Future<void> _next() async {
    if (_currentStep == 0) {
      final profile = await _c.submit();
      if (profile == null) return;
    }
    if (_currentStep < _titles.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

  /// Submits the registration, then routes on SERVER truth.
  ///
  /// This used to flip a SharedPreferences boolean and push the supplier shell,
  /// having sent nothing anywhere. The supplier arrived with no SupplierProfile
  /// row, so every supplier route answered 403 NOT_APPROVED and the app looked
  /// comprehensively broken with no clue why.
  ///
  /// Approval is never granted here. A fresh registration is PENDING until an
  /// admin acts on it, so the destination is the waiting screen; the shell
  /// opens only for a profile the server already marked approved.
  Future<void> _finish() async {
    final profile = await _c.submit();
    // Null means the submission failed and the controller has already put the
    // reason on screen. Stay on the wizard so the answers are not lost.
    if (profile == null) return;
    if (!mounted) return;

    // Take the flags from the response we already have rather than issuing a
    // second read, then route through landingRoute so this is not a fourth
    // place that decides where a supplier belongs.
    final role = RoleController.to;
    role.completeProviderOnboarding();
    role.providerApproved.value =
        profile.supplierProfile?.canEnterShell ?? false;
    Get.offAllNamed(role.landingRoute);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
          text: _titles[_currentStep],
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
                      text: "Step ${_currentStep + 1} Of ${_titles.length}",
                      size: 12,
                      weight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                    MyText(
                      text: _titles[_currentStep],
                      size: 12,
                      weight: FontWeight.w500,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(_titles.length, (index) {
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
          SupplierBusinessStep(onNext: _next),
          SupplierKycStep(onNext: _next),
          SupplierPlanStep(onFinish: _finish, onBack: _back),
        ],
      ),
    );
  }
}

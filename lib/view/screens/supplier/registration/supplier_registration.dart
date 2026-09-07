import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/controller/supplier/supplier_registration_controller.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_awaiting_approval.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration_catalogue.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration_kyc.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration_plan.dart';
import 'package:autonect/view/screens/supplier/registration/supplier_registration_steps.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Supplier KYC wizard — the same five-step PageView + segmented progress
/// header the electrician registration wizard uses, mapped onto the backend
/// SupplierProfile model.
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
    'Supplier Registration',
    'Regions Served',
    'Part Categories',
    'KYC',
    'Access Tier',
  ];

  static const List<String> _stepLabels = [
    'Business Info',
    'Coverage',
    'Catalogue',
    'Verification',
    'Plan',
  ];

  void _next() {
    if (_currentStep < 4) {
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

    RoleController.to.completeProviderOnboarding();
    if (profile.supplierProfile?.canEnterShell ?? false) {
      Get.offAllNamed(AppLinks.supplierShell);
    } else {
      Get.offAll(() => SupplierAwaitingApprovalPage(profile: profile));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
        title: MyText(
          text: _titles[_currentStep],
          size: 18,
          weight: FontWeight.w700,
          color: kBlackColor,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText(
                      text: 'Step ${_currentStep + 1} of 5',
                      size: 12,
                      weight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                    MyText(
                      text: _stepLabels[_currentStep],
                      size: 12,
                      weight: FontWeight.w500,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
          SupplierBusinessStep(onNext: _next),
          SupplierRegionsStep(onNext: _next),
          SupplierCategoriesStep(onNext: _next),
          SupplierKycStep(onNext: _next),
          SupplierPlanStep(onFinish: _finish),
        ],
      ),
    );
  }
}

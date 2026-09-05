import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/view/screens/buyer/new_part_request/steps/confirm_step_view.dart';
import 'package:autonect/view/screens/buyer/new_part_request/steps/part_details_step_view.dart';
import 'package:autonect/view/screens/buyer/new_part_request/steps/vehicle_step_view.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _stepTitles = [
  '1/3 DVLA Check', '2/3 Part Details', '3/3 Confirm & Submit'];

/// The three-step wizard shell: a PageController, the segmented progress bar
/// and the seven TextEditingControllers the steps write through. They live
/// HERE, not on NewRequestController: a GetX controller that outlives the
/// route must not own disposables the route created.
class AddPartRequestPage extends StatefulWidget {
  const AddPartRequestPage({super.key});

  @override
  State<AddPartRequestPage> createState() => _AddPartRequestPageState();
}

class _AddPartRequestPageState extends State<AddPartRequestPage> {
  static const int _stepCount = 3;

  late final PageController _pageController;
  late final NewRequestController _c;
  final TextEditingController _reg = TextEditingController(),
      _make = TextEditingController(), _model = TextEditingController(),
      _year = TextEditingController(), _partName = TextEditingController(),
      _partNumber = TextEditingController(),
      _description = TextEditingController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _c = NewRequestController.ensure();
    final d = _c.draft;
    // The RESTORED draft, not an empty one: the wizard is re-entered after the
    // OS reclaims it mid-flow, and the draft (with its S3 keys) survives that.
    _reg.text = d.regNumber;
    _model.text = d.vehicleModel ?? '';
    _partName.text = d.partName;
    _partNumber.text = d.partNumber ?? '';
    _description.text = d.description ?? '';
    _currentStep = d.step.clamp(0, _stepCount - 1);
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final t in [_reg, _make, _model, _year, _partName, _partNumber,
        _description]) {
      t.dispose();
    }
    super.dispose();
  }

  /// The old guard `_currentStep < 3` animated to page 3 of a 3-page PageView.
  void _goTo(int index) {
    if (index < 0 || index >= _stepCount) return;
    setState(() => _currentStep = index);
    _c.goTo(index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _next() => _goTo(_currentStep + 1);
  void _back() => _currentStep > 0 ? _goTo(_currentStep - 1) : Get.back();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: kPrimaryColor, surfaceTintColor: kPrimaryColor,
      elevation: 0, centerTitle: true,
      leading: GestureDetector(onTap: _back,
          child: const Icon(Icons.arrow_back_ios_new, color: kBlackColor,
              size: AppSizes.s20)),
      title: Column(children: [
        MyText(text: 'New Part Request', size: AppTextScale.subtitle,
            weight: AppWeights.semibold, color: kBlackColor),
        MyText(text: _stepTitles[_currentStep], size: AppTextScale.label,
            color: kSecondaryColor),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(AppSizes.s8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
          child: Row(children: [
            for (var i = 0; i < _stepCount; i++)
              Expanded(child: Container(height: AppSizes.s4,
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.s4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    color: i <= _currentStep
                        ? kSecondaryColor : kBlackColor.withValues(alpha: .2),
                  ))),
          ]),
        ),
      ),
    ),
    body: PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        VehicleStepView(controller: _c, reg: _reg, make: _make, model: _model,
            year: _year, onNext: _next),
        PartDetailsStepView(controller: _c, partName: _partName,
            partNumber: _partNumber, description: _description, onNext: _next),
        ConfirmStepView(controller: _c),
      ],
    ),
  );
}

/// The wizard's fixed footer. Public so all three steps share one treatment;
/// each supplies its own CTA, because only the step knows when advancing is
/// legal.
class WizardBottomBar extends StatelessWidget {
  const WizardBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
        AppSizes.s20, AppSizes.s12, AppSizes.s20, AppSizes.s24),
    color: kPrimaryColor, child: child,
  );
}

/// Shown once `POST /v1/requests` has answered. It renders the SERVER's
/// registration, never the typed one: the server normalises it, so the two can
/// legitimately differ.
class RequestSendBSheet extends StatelessWidget {
  const RequestSendBSheet({super.key, required this.request, this.onProceed});

  final PartRequest request;
  final VoidCallback? onProceed;

  @override
  Widget build(BuildContext context) => MyBSheet(
    btnText: 'Proceed', onTap: onProceed ?? () => Get.back(),
    body: Column(children: [
      CommonImageView(width: 150, imagePath: Assets.imagesRequestPartIcon),
      MyText(textAlign: TextAlign.center, paddingBottom: AppSizes.s20,
          paddingTop: AppSizes.s24, text: 'Request Sent to Sellers',
          size: AppTextScale.display, weight: AppWeights.bold),
      MyText(paddingBottom: AppSizes.s24, textAlign: TextAlign.center,
          size: AppTextScale.subtitle,
          text: 'Suppliers matching ${request.regNumber} will send you offers '
              'soon.'),
    ]),
  );
}

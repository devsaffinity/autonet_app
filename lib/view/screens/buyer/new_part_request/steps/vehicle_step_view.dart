import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/domain/reg_number.dart';
import 'package:autonect/domain/vehicle_step.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/reg_plate_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 1 — the registration lookup. MANUAL_REQUIRED is the NORMAL outcome,
/// not an edge case: the live DVLA VES adapter hardcodes `model: null`. No
/// state below is a dead end either — the create route does its own
/// find-or-create on the registration, so an outage must not block the funnel.
class VehicleStepView extends StatefulWidget {
  const VehicleStepView({
    super.key, required this.controller, required this.reg, required this.make,
    required this.model, required this.year, required this.onNext,
  });

  final NewRequestController controller;
  final TextEditingController reg, make, model, year;
  final VoidCallback onNext;

  @override
  State<VehicleStepView> createState() => _VehicleStepViewState();
}

class _VehicleStepViewState extends State<VehicleStepView> {
  late final Worker _onVehicle;

  @override
  void initState() {
    super.initState();
    // Page-owned fields are written from a worker: build() must not mutate
    // a TextEditingController.
    _onVehicle = ever<VehicleStep>(widget.controller.vehicle, _apply);
  }

  @override
  void dispose() {
    _onVehicle.dispose();
    super.dispose();
  }

  void _apply(VehicleStep step) {
    final draft = widget.controller.draft;
    switch (step) {
      case VehicleResolved(:final lookup) || VehicleManualModel(:final lookup):
        widget.make.text = lookup.vehicle.make ?? '';
        widget.year.text = lookup.vehicle.year?.toString() ?? '';
        // Empty for MANUAL_REQUIRED — exactly the field the buyer then fills.
        widget.model.text = lookup.vehicle.model ?? '';
        draft.vehicleModel = null;
      // Make and Year are hidden here, so they must not keep a previous plate.
      case VehicleUnknownReg():
        widget..make.clear()..year.clear()..model.clear();
        draft.vehicleModel = null;
      case VehicleIdle() || VehicleLooking() || VehicleFailed():
        break;
    }
    if (mounted) setState(() {});
  }

  void _edited(String path, void Function(NewRequestController) write) {
    write(widget.controller);
    widget.controller.clearFieldError(path);
    widget.controller.scheduleSave();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Obx(() {
      final step = c.vehicle.value;
      final ready = step.canAdvance &&
          (!step.modelFieldRequired || widget.model.text.trim().isNotEmpty);
      return Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: AppSizes.DEFAULT,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MyText(text: 'Enter your registration', size: AppTextScale.subtitle,
                weight: AppWeights.semibold, paddingBottom: AppSizes.s12),
            RegPlateField(controller: widget.reg,
                errorText: c.fieldErrorFor('regNumber'),
                onChanged: (v) =>
                    _edited('regNumber', (c) => c.draft.regNumber = v)),
            MyButton(buttonText: 'Find Vehicle', loading: step is VehicleLooking,
                enabled: isValidReg(widget.reg.text),
                onTap: () => c.lookupVehicle(widget.reg.text)),
            ..._afterLookup(step, c),
          ]),
        )),
        WizardBottomBar(child: MyButton(buttonText: 'Next', enabled: ready,
            onTap: widget.onNext)),
      ]);
    });
  }

  List<Widget> _afterLookup(VehicleStep step, NewRequestController c) =>
      switch (step) {
        VehicleIdle() || VehicleLooking() => const <Widget>[],
        VehicleFailed(:final retryable) => [
          _notice('Vehicle lookup is unavailable right now — you can continue.'),
          if (retryable)
            _secondary('Retry', () => c.lookupVehicle(widget.reg.text)),
          _secondary('Continue without lookup', c.continueWithoutLookup),
        ],
        // No Make/Year: neither is in the create DTO, and a field the buyer
        // fills that is silently discarded would be a lie.
        VehicleUnknownReg() => [
          _notice('We could not find that registration. You can still post '
              'your request — just tell us the model.'),
          _modelField(c, editable: true),
        ],
        VehicleManualModel() => _known(c, editable: true,
            helper: 'DVLA does not publish the model — please type it'),
        VehicleResolved() => _known(c, editable: false),
      };

  List<Widget> _known(NewRequestController c, {required bool editable,
      String? helper}) => [
    MyText(text: 'Vehicle Details', size: AppTextScale.subtitle,
        weight: AppWeights.bold, color: kSecondaryColor,
        paddingTop: AppSizes.s24, paddingBottom: AppSizes.s12),
    _readOnly(widget.make, 'Make'),
    _modelField(c, editable: editable),
    if (helper != null)
      MyText(text: helper, size: AppTextScale.label, color: kGreyTextColor,
          paddingLeft: AppSizes.s8, paddingBottom: AppSizes.s16),
    _readOnly(widget.year, 'Year'),
  ];

  Widget _secondary(String label, VoidCallback onTap) =>
      MyButton(buttonText: label, mTop: AppSizes.s12, onTap: onTap,
          backgroundColor: kTertiaryColor, fontColor: kBlackColor);

  Widget _readOnly(TextEditingController t, String label) =>
      MyTextField(controller: t, labelText: label, isReadOnly: true,
          radius: AppSizes.radiusSm);

  Widget _modelField(NewRequestController c, {required bool editable}) =>
      MyTextField(controller: widget.model, isReadOnly: !editable,
          labelText: editable ? 'Model (required)' : 'Model',
          radius: AppSizes.radiusSm,
          errorText: c.fieldErrorFor('vehicleModel'),
          onChanged: editable
              ? (v) => _edited('vehicleModel', (c) => c.draft.vehicleModel = v)
              : null);

  /// Advisory, never an error colour: the buyer can still finish from here.
  Widget _notice(String message) => Container(
    margin: const EdgeInsets.only(top: AppSizes.s20),
    padding: const EdgeInsets.all(AppSizes.s12),
    decoration: AppStyling().myDecoration(color: kLightOrangeColor,
        borderColor: kSecondaryColor, radius: AppSizes.radiusMd),
    child: MyText(text: message, size: AppTextScale.body, color: kBlackColor),
  );
}

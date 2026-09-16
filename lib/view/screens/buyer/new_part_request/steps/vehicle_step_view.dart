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

/// Step 1 — Vehicle Information.
///
/// Supports both:
/// 1. Automated Plate / DVLA lookup (with realistic fallback & model derivation)
/// 2. Custom / Manual vehicle details entry for when lookup is unavailable
///    or when the buyer has a non-standard vehicle.
class VehicleStepView extends StatefulWidget {
  const VehicleStepView({
    super.key,
    required this.controller,
    required this.reg,
    required this.make,
    required this.model,
    required this.year,
    required this.onNext,
  });

  final NewRequestController controller;
  final TextEditingController reg, make, model, year;
  final VoidCallback onNext;

  @override
  State<VehicleStepView> createState() => _VehicleStepViewState();
}

class _VehicleStepViewState extends State<VehicleStepView> {
  late final Worker _onVehicle;
  late final TextEditingController _fuel;
  late final TextEditingController _colour;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    _isCustomMode = widget.controller.draft.isCustomVehicle;
    _fuel = TextEditingController(text: widget.controller.draft.vehicleFuel ?? '');
    _colour = TextEditingController(text: widget.controller.draft.vehicleColour ?? '');
    _onVehicle = ever<VehicleStep>(widget.controller.vehicle, _apply);
  }

  @override
  void dispose() {
    _onVehicle.dispose();
    _fuel.dispose();
    _colour.dispose();
    super.dispose();
  }

  void _apply(VehicleStep step) {
    final draft = widget.controller.draft;
    switch (step) {
      case VehicleResolved(:final lookup) || VehicleManualModel(:final lookup):
        widget.make.text = lookup.vehicle.make ?? '';
        widget.year.text = lookup.vehicle.year?.toString() ?? '';
        widget.model.text = lookup.vehicle.model ?? '';
        _fuel.text = lookup.vehicle.fuel ?? '';
        _colour.text = lookup.vehicle.colour ?? '';
        draft.vehicleMake = lookup.vehicle.make;
        draft.vehicleModel = lookup.vehicle.model;
        draft.vehicleYear = lookup.vehicle.year;
        draft.vehicleFuel = lookup.vehicle.fuel;
        draft.vehicleColour = lookup.vehicle.colour;
      case VehicleUnknownReg():
        widget.make.clear();
        widget.year.clear();
        widget.model.clear();
        _fuel.clear();
        _colour.clear();
        draft.vehicleModel = null;
      case VehicleCustom():
        _isCustomMode = true;
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

  bool _isReady(VehicleStep step) {
    if (_isCustomMode) {
      return widget.reg.text.trim().isNotEmpty &&
          isValidReg(widget.reg.text) &&
          widget.make.text.trim().isNotEmpty &&
          widget.model.text.trim().isNotEmpty;
    }
    return step.canAdvance &&
        (!step.modelFieldRequired || widget.model.text.trim().isNotEmpty);
  }

  void _handleNext() {
    if (_isCustomMode) {
      widget.controller.setCustomVehicleDetails(
        regNumber: widget.reg.text,
        make: widget.make.text,
        model: widget.model.text,
        year: int.tryParse(widget.year.text),
        fuel: _fuel.text,
        colour: _colour.text,
      );
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Obx(() {
      final step = c.vehicle.value;
      final ready = _isReady(step);
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSizes.DEFAULT,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModeSelector(),
                  if (_isCustomMode) ..._buildCustomForm(c) else ..._buildLookupForm(step, c),
                ],
              ),
            ),
          ),
          WizardBottomBar(
            child: MyButton(
              buttonText: 'Next',
              enabled: ready,
              onTap: _handleNext,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s20),
      decoration: BoxDecoration(
        color: kTertiaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _isCustomMode = false);
                widget.controller.switchToLookup();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isCustomMode ? kSecondaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                alignment: Alignment.center,
                child: MyText(
                  text: 'Plate / DVLA Lookup',
                  size: AppTextScale.body,
                  weight: !_isCustomMode ? AppWeights.bold : AppWeights.medium,
                  color: !_isCustomMode ? kWhiteColor : kBlackColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _isCustomMode = true);
                widget.controller.switchToCustomVehicle();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isCustomMode ? kSecondaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                alignment: Alignment.center,
                child: MyText(
                  text: 'Custom Vehicle Entry',
                  size: AppTextScale.body,
                  weight: _isCustomMode ? AppWeights.bold : AppWeights.medium,
                  color: _isCustomMode ? kWhiteColor : kBlackColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLookupForm(VehicleStep step, NewRequestController c) {
    return [
      MyText(
        text: 'Enter your registration',
        size: AppTextScale.subtitle,
        weight: AppWeights.semibold,
        paddingBottom: AppSizes.s12,
      ),
      RegPlateField(
        controller: widget.reg,
        isRequired: true,
        errorText: c.fieldErrorFor('regNumber'),
        onChanged: (v) => _edited('regNumber', (c) {
          c.draft.regNumber = v;
          c.draft.isCustomVehicle = false;
        }),
      ),
      MyButton(
        buttonText: 'Find Vehicle',
        loading: step is VehicleLooking,
        enabled: isValidReg(widget.reg.text),
        onTap: () => c.lookupVehicle(widget.reg.text),
      ),
      ..._afterLookup(step, c),
    ];
  }

  List<Widget> _buildCustomForm(NewRequestController c) {
    return [
      MyText(
        text: 'Custom Vehicle Specifications',
        size: AppTextScale.subtitle,
        weight: AppWeights.bold,
        color: kSecondaryColor,
        paddingBottom: AppSizes.s4,
      ),
      MyText(
        text: 'Enter your vehicle details manually if registration lookup is unavailable.',
        size: AppTextScale.label,
        color: kGreyTextColor,
        paddingBottom: AppSizes.s16,
      ),
      RegPlateField(
        controller: widget.reg,
        isRequired: true,
        errorText: c.fieldErrorFor('regNumber'),
        onChanged: (v) => _edited('regNumber', (c) {
          c.draft.regNumber = v;
          c.draft.isCustomVehicle = true;
        }),
      ),
      const SizedBox(height: AppSizes.s12),
      MyTextField(
        controller: widget.make,
        labelText: 'Make',
        hintText: 'e.g. Ford, BMW, Volkswagen, Toyota',
        isRequired: true,
        radius: AppSizes.radiusSm,
        errorText: c.fieldErrorFor('vehicleMake'),
        onChanged: (v) => _edited('vehicleMake', (c) {
          c.draft.vehicleMake = v;
          c.draft.isCustomVehicle = true;
        }),
      ),
      const SizedBox(height: AppSizes.s12),
      MyTextField(
        controller: widget.model,
        labelText: 'Model',
        hintText: 'e.g. Focus, 3 Series, Golf, Corsa',
        isRequired: true,
        radius: AppSizes.radiusSm,
        errorText: c.fieldErrorFor('vehicleModel'),
        onChanged: (v) => _edited('vehicleModel', (c) {
          c.draft.vehicleModel = v;
          c.draft.isCustomVehicle = true;
        }),
      ),
      const SizedBox(height: AppSizes.s12),
      Row(
        children: [
          Expanded(
            child: MyTextField(
              controller: widget.year,
              labelText: 'Year',
              hintText: 'e.g. 2019',
              keyboardType: TextInputType.number,
              radius: AppSizes.radiusSm,
              onChanged: (v) => _edited('vehicleYear', (c) {
                c.draft.vehicleYear = int.tryParse(v);
              }),
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: MyTextField(
              controller: _fuel,
              labelText: 'Fuel Type',
              hintText: 'e.g. Petrol, Diesel, Hybrid',
              radius: AppSizes.radiusSm,
              onChanged: (v) => _edited('vehicleFuel', (c) {
                c.draft.vehicleFuel = v;
              }),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSizes.s12),
      MyTextField(
        controller: _colour,
        labelText: 'Colour',
        hintText: 'e.g. Black, Grey, Blue, Silver',
        radius: AppSizes.radiusSm,
        onChanged: (v) => _edited('vehicleColour', (c) {
          c.draft.vehicleColour = v;
        }),
      ),
    ];
  }

  List<Widget> _afterLookup(VehicleStep step, NewRequestController c) =>
      switch (step) {
        VehicleIdle() || VehicleLooking() => const <Widget>[],
        VehicleFailed(:final retryable) => [
          _notice('Vehicle lookup is currently unavailable. You can enter details manually.'),
          if (retryable)
            _secondary('Retry Lookup', () => c.lookupVehicle(widget.reg.text)),
          _secondary('Enter vehicle details manually', () {
            setState(() => _isCustomMode = true);
            c.switchToCustomVehicle();
          }),
        ],
        VehicleUnknownReg() => [
          _notice('We could not automatically match that registration. You can still post your request by specifying the model below or entering details manually.'),
          _modelField(c, editable: true),
          _secondary('Enter full vehicle details manually', () {
            setState(() => _isCustomMode = true);
            c.switchToCustomVehicle();
          }),
        ],
        VehicleManualModel() => _known(
          c,
          editable: true,
          helper: 'Please confirm or type your vehicle model',
        ),
        VehicleResolved() => _known(c, editable: false),
        VehicleCustom() => const <Widget>[],
      };

  List<Widget> _known(
    NewRequestController c, {
    required bool editable,
    String? helper,
  }) => [
    MyText(
      text: 'Vehicle Details',
      size: AppTextScale.subtitle,
      weight: AppWeights.bold,
      color: kSecondaryColor,
      paddingTop: AppSizes.s24,
      paddingBottom: AppSizes.s12,
    ),
    _readOnly(widget.make, 'Make'),
    _modelField(c, editable: editable),
    if (helper != null)
      MyText(
        text: helper,
        size: AppTextScale.label,
        color: kGreyTextColor,
        paddingLeft: AppSizes.s8,
        paddingBottom: AppSizes.s16,
      ),
    _readOnly(widget.year, 'Year'),
    if (_fuel.text.trim().isNotEmpty) _readOnly(_fuel, 'Fuel Type'),
    if (_colour.text.trim().isNotEmpty) _readOnly(_colour, 'Colour'),
    const SizedBox(height: AppSizes.s8),
    GestureDetector(
      onTap: () {
        setState(() => _isCustomMode = true);
        c.switchToCustomVehicle();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: MyText(
          text: 'Need to customize these details? Switch to Manual Entry',
          size: AppTextScale.label,
          weight: AppWeights.medium,
          color: kSecondaryColor,
        ),
      ),
    ),
  ];

  Widget _secondary(String label, VoidCallback onTap) =>
      MyButton(
        buttonText: label,
        mTop: AppSizes.s12,
        onTap: onTap,
        backgroundColor: kTertiaryColor,
        fontColor: kBlackColor,
      );

  Widget _readOnly(TextEditingController t, String label) =>
      MyTextField(
        controller: t,
        labelText: label,
        isReadOnly: true,
        radius: AppSizes.radiusSm,
      );

  Widget _modelField(NewRequestController c, {required bool editable}) =>
      MyTextField(
        controller: widget.model,
        isReadOnly: !editable,
        labelText: 'Model',
        isRequired: editable,
        radius: AppSizes.radiusSm,
        errorText: c.fieldErrorFor('vehicleModel'),
        onChanged: editable
            ? (v) => _edited('vehicleModel', (c) {
                c.draft.vehicleModel = v;
              })
            : null,
      );

  Widget _notice(String message) => Container(
    margin: const EdgeInsets.only(top: AppSizes.s20),
    padding: const EdgeInsets.all(AppSizes.s12),
    decoration: AppStyling().myDecoration(
      color: kLightOrangeColor,
      borderColor: kSecondaryColor,
      radius: AppSizes.radiusMd,
    ),
    child: MyText(text: message, size: AppTextScale.body, color: kBlackColor),
  );
}

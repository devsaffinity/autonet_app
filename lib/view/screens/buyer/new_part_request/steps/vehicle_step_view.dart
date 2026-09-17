import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/domain/reg_number.dart';
import 'package:autonect/domain/vehicle_catalog.dart';
import 'package:autonect/domain/vehicle_step.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/reg_plate_field.dart';
import 'package:autonect/view/widget/vehicle_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 1 — Vehicle Specifications.
///
/// Direct custom vehicle entry with dropdowns for Make, Model, Fuel Type,
/// Colour, and Year, with fallback "Other" options for custom inputs.
///
/// NOTE: The automated DVLA / Plate lookup flow is temporarily commented out
/// below until the official live DVLA API key is configured.
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

  // Custom text editing controllers for when "Other" is selected in dropdowns
  late final TextEditingController _customMakeController;
  late final TextEditingController _customModelController;
  late final TextEditingController _customYearController;
  late final TextEditingController _customFuelController;
  late final TextEditingController _customColourController;

  String? _selectedMake;
  String? _selectedModel;
  String? _selectedYear;
  String? _selectedFuel;
  String? _selectedColour;

  bool get _isOtherMake => _selectedMake == VehicleCatalog.otherOption;
  bool get _isOtherModel => _selectedModel == VehicleCatalog.otherOption;
  bool get _isOtherYear => _selectedYear == VehicleCatalog.otherOption;
  bool get _isOtherFuel => _selectedFuel == VehicleCatalog.otherOption;
  bool get _isOtherColour => _selectedColour == VehicleCatalog.otherOption;

  @override
  void initState() {
    super.initState();
    // Default to custom vehicle specification mode
    widget.controller.switchToCustomVehicle();

    final draft = widget.controller.draft;
    _fuel = TextEditingController(text: draft.vehicleFuel ?? '');
    _colour = TextEditingController(text: draft.vehicleColour ?? '');

    _customMakeController = TextEditingController();
    _customModelController = TextEditingController();
    _customYearController = TextEditingController();
    _customFuelController = TextEditingController();
    _customColourController = TextEditingController();

    _initSelectedValues();
    _onVehicle = ever<VehicleStep>(widget.controller.vehicle, _apply);
  }

  void _initSelectedValues() {
    // 1. Make
    final currentMake = widget.make.text.trim();
    if (currentMake.isNotEmpty) {
      if (VehicleCatalog.popularMakes.contains(currentMake)) {
        _selectedMake = currentMake;
      } else {
        _selectedMake = VehicleCatalog.otherOption;
        _customMakeController.text = currentMake;
      }
    }

    // 2. Model
    final currentModel = widget.model.text.trim();
    if (currentModel.isNotEmpty) {
      final availableModels = VehicleCatalog.modelsForMake(_selectedMake);
      if (availableModels.contains(currentModel)) {
        _selectedModel = currentModel;
      } else {
        _selectedModel = VehicleCatalog.otherOption;
        _customModelController.text = currentModel;
      }
    }

    // 3. Year
    final currentYear = widget.year.text.trim();
    if (currentYear.isNotEmpty) {
      if (VehicleCatalog.years.contains(currentYear)) {
        _selectedYear = currentYear;
      } else {
        _selectedYear = VehicleCatalog.otherOption;
        _customYearController.text = currentYear;
      }
    }

    // 4. Fuel
    final currentFuel = _fuel.text.trim();
    if (currentFuel.isNotEmpty) {
      if (VehicleCatalog.fuelTypes.contains(currentFuel)) {
        _selectedFuel = currentFuel;
      } else {
        _selectedFuel = VehicleCatalog.otherOption;
        _customFuelController.text = currentFuel;
      }
    }

    // 5. Colour
    final currentColour = _colour.text.trim();
    if (currentColour.isNotEmpty) {
      if (VehicleCatalog.colours.contains(currentColour)) {
        _selectedColour = currentColour;
      } else {
        _selectedColour = VehicleCatalog.otherOption;
        _customColourController.text = currentColour;
      }
    }
  }

  @override
  void dispose() {
    _onVehicle.dispose();
    _fuel.dispose();
    _colour.dispose();
    _customMakeController.dispose();
    _customModelController.dispose();
    _customYearController.dispose();
    _customFuelController.dispose();
    _customColourController.dispose();
    super.dispose();
  }

  void _apply(VehicleStep step) {
    if (mounted) setState(() {});
  }

  void _edited(String path, void Function(NewRequestController) write) {
    write(widget.controller);
    widget.controller.clearFieldError(path);
    widget.controller.scheduleSave();
    setState(() {});
  }

  bool _isReady() {
    return widget.reg.text.trim().isNotEmpty &&
        isValidReg(widget.reg.text) &&
        widget.make.text.trim().isNotEmpty &&
        widget.model.text.trim().isNotEmpty;
  }

  void _handleNext() {
    widget.controller.setCustomVehicleDetails(
      regNumber: widget.reg.text,
      make: widget.make.text,
      model: widget.model.text,
      year: int.tryParse(widget.year.text),
      fuel: _fuel.text,
      colour: _colour.text,
    );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Obx(() {
      final ready = _isReady();
      final makeError = c.fieldErrorFor('vehicleMake');
      final modelError = c.fieldErrorFor('vehicleModel');
      final availableModels = VehicleCatalog.modelsForMake(_selectedMake);

      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSizes.DEFAULT,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header — Custom Vehicle Specifications
                  MyText(
                    text: 'Custom Vehicle Specifications',
                    size: AppTextScale.subtitle,
                    weight: AppWeights.bold,
                    color: kSecondaryColor,
                    paddingBottom: AppSizes.s4,
                  ),
                  MyText(
                    text:
                        'Select or enter your vehicle specifications below to help suppliers match the exact parts.',
                    size: AppTextScale.label,
                    color: kGreyTextColor,
                    paddingBottom: AppSizes.s16,
                  ),

                  // Registration Number
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

                  // Make Dropdown
                  VehicleDropdownField(
                    title: 'Make',
                    hint: 'Select Vehicle Make',
                    isRequired: true,
                    items: VehicleCatalog.popularMakes,
                    selectedValue: _selectedMake,
                    isOtherSelected: _isOtherMake,
                    customController: _customMakeController,
                    customLabel: 'Custom Make',
                    customHint: 'e.g. Lotus, Bentley, Saab...',
                    errorText: makeError,
                    onDropdownChanged: (val) {
                      _edited('vehicleMake', (c) {
                        _selectedMake = val;
                        if (val == VehicleCatalog.otherOption) {
                          widget.make.text = _customMakeController.text;
                          c.draft.vehicleMake = _customMakeController.text;
                        } else if (val != null) {
                          widget.make.text = val;
                          c.draft.vehicleMake = val;
                          _customMakeController.clear();
                        } else {
                          widget.make.clear();
                          c.draft.vehicleMake = null;
                        }

                        // Reset model selection if selected make changed
                        final newModels =
                            VehicleCatalog.modelsForMake(_selectedMake);
                        if (_selectedModel != VehicleCatalog.otherOption &&
                            !newModels.contains(_selectedModel)) {
                          _selectedModel = null;
                          widget.model.clear();
                          c.draft.vehicleModel = null;
                          _customModelController.clear();
                        }
                      });
                    },
                    onCustomChanged: (val) {
                      _edited('vehicleMake', (c) {
                        widget.make.text = val;
                        c.draft.vehicleMake = val;
                      });
                    },
                  ),

                  // Model Dropdown / Custom Field
                  if (_selectedMake != null && !_isOtherMake) ...[
                    VehicleDropdownField(
                      title: 'Model',
                      hint: 'Select Vehicle Model',
                      isRequired: true,
                      items: availableModels,
                      selectedValue: _selectedModel,
                      isOtherSelected: _isOtherModel,
                      customController: _customModelController,
                      customLabel: 'Custom Model',
                      customHint: 'Enter vehicle model name',
                      errorText: modelError,
                      onDropdownChanged: (val) {
                        _edited('vehicleModel', (c) {
                          _selectedModel = val;
                          if (val == VehicleCatalog.otherOption) {
                            widget.model.text = _customModelController.text;
                            c.draft.vehicleModel = _customModelController.text;
                          } else if (val != null) {
                            widget.model.text = val;
                            c.draft.vehicleModel = val;
                            _customModelController.clear();
                          } else {
                            widget.model.clear();
                            c.draft.vehicleModel = null;
                          }
                        });
                      },
                      onCustomChanged: (val) {
                        _edited('vehicleModel', (c) {
                          widget.model.text = val;
                          c.draft.vehicleModel = val;
                        });
                      },
                    ),
                  ] else ...[
                    // When Make is "Other" or unselected, allow typing the model directly
                    MyTextField(
                      controller: widget.model,
                      labelText: 'Model',
                      hintText: 'e.g. Focus, 3 Series, Golf, Corsa',
                      isRequired: true,
                      radius: AppSizes.radiusSm,
                      errorText: modelError,
                      onChanged: (v) => _edited('vehicleModel', (c) {
                        c.draft.vehicleModel = v;
                        c.draft.isCustomVehicle = true;
                      }),
                    ),
                    const SizedBox(height: AppSizes.s16),
                  ],

                  // Year Dropdown
                  VehicleDropdownField(
                    title: 'Year',
                    hint: 'Select Year of Manufacture',
                    items: VehicleCatalog.years,
                    selectedValue: _selectedYear,
                    isOtherSelected: _isOtherYear,
                    customController: _customYearController,
                    customLabel: 'Custom Year',
                    customHint: 'e.g. 1975',
                    keyboardType: TextInputType.number,
                    onDropdownChanged: (val) {
                      _edited('vehicleYear', (c) {
                        _selectedYear = val;
                        if (val == VehicleCatalog.otherOption) {
                          widget.year.text = _customYearController.text;
                          c.draft.vehicleYear =
                              int.tryParse(_customYearController.text);
                        } else if (val != null) {
                          widget.year.text = val;
                          c.draft.vehicleYear = int.tryParse(val);
                          _customYearController.clear();
                        } else {
                          widget.year.clear();
                          c.draft.vehicleYear = null;
                        }
                      });
                    },
                    onCustomChanged: (val) {
                      _edited('vehicleYear', (c) {
                        widget.year.text = val;
                        c.draft.vehicleYear = int.tryParse(val);
                      });
                    },
                  ),

                  // Fuel Type Dropdown
                  VehicleDropdownField(
                    title: 'Fuel Type',
                    hint: 'Select Fuel Type',
                    items: VehicleCatalog.fuelTypes,
                    selectedValue: _selectedFuel,
                    isOtherSelected: _isOtherFuel,
                    customController: _customFuelController,
                    customLabel: 'Custom Fuel Type',
                    customHint: 'e.g. Hydrogen, Bio-diesel, Rotary...',
                    onDropdownChanged: (val) {
                      _edited('vehicleFuel', (c) {
                        _selectedFuel = val;
                        if (val == VehicleCatalog.otherOption) {
                          _fuel.text = _customFuelController.text;
                          c.draft.vehicleFuel = _customFuelController.text;
                        } else if (val != null) {
                          _fuel.text = val;
                          c.draft.vehicleFuel = val;
                          _customFuelController.clear();
                        } else {
                          _fuel.clear();
                          c.draft.vehicleFuel = null;
                        }
                      });
                    },
                    onCustomChanged: (val) {
                      _edited('vehicleFuel', (c) {
                        _fuel.text = val;
                        c.draft.vehicleFuel = val;
                      });
                    },
                  ),

                  // Colour Dropdown
                  VehicleDropdownField(
                    title: 'Colour',
                    hint: 'Select Vehicle Colour',
                    items: VehicleCatalog.colours,
                    selectedValue: _selectedColour,
                    isOtherSelected: _isOtherColour,
                    customController: _customColourController,
                    customLabel: 'Custom Colour',
                    customHint: 'e.g. British Racing Green, Matte Grey...',
                    onDropdownChanged: (val) {
                      _edited('vehicleColour', (c) {
                        _selectedColour = val;
                        if (val == VehicleCatalog.otherOption) {
                          _colour.text = _customColourController.text;
                          c.draft.vehicleColour = _customColourController.text;
                        } else if (val != null) {
                          _colour.text = val;
                          c.draft.vehicleColour = val;
                          _customColourController.clear();
                        } else {
                          _colour.clear();
                          c.draft.vehicleColour = null;
                        }
                      });
                    },
                    onCustomChanged: (val) {
                      _edited('vehicleColour', (c) {
                        _colour.text = val;
                        c.draft.vehicleColour = val;
                      });
                    },
                  ),
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

  // ===========================================================================
  // TEMPORARILY COMMENTED OUT: Automated Plate / DVLA Lookup
  // Re-enable when live DVLA VES API key is configured.
  // ===========================================================================
  /*
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
                widget.controller.switchToLookup();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: const MyText(
                  text: 'Plate / DVLA Lookup',
                  size: AppTextScale.body,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                widget.controller.switchToCustomVehicle();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: const MyText(
                  text: 'Custom Vehicle Entry',
                  size: AppTextScale.body,
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

  List<Widget> _afterLookup(VehicleStep step, NewRequestController c) =>
      switch (step) {
        VehicleIdle() || VehicleLooking() => const <Widget>[],
        VehicleFailed(:final retryable) => [
          _notice('Vehicle lookup is currently unavailable. You can enter details manually.'),
          if (retryable)
            _secondary('Retry Lookup', () => c.lookupVehicle(widget.reg.text)),
          _secondary('Enter vehicle details manually', () {
            c.switchToCustomVehicle();
          }),
        ],
        VehicleUnknownReg() => [
          _notice('We could not automatically match that registration. You can still post your request by specifying the model below or entering details manually.'),
          _modelField(c, editable: true),
          _secondary('Enter full vehicle details manually', () {
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
  */
}

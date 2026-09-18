import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/request_draft.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/screens/buyer/new_part_request/widgets/category_picker_sheet.dart';
import 'package:autonect/view/widget/counted_text_field.dart';
import 'package:autonect/view/widget/enum_select_field.dart';
import 'package:autonect/view/widget/field_label.dart';
import 'package:autonect/view/widget/image_tray.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Every option list is built FROM the wire enums, so an option the API would
/// reject is unrepresentable. The dropdowns this replaces offered 'Refurbished'
/// and 'Normal', neither of which exists on the backend.
final List<SelectOption<Region>> _regions = [
  for (final r in Region.values) SelectOption(r, r.label),
];
final List<SelectOption<RequestUrgency>> _urgencies = [
  for (final u in RequestUrgency.values) SelectOption(u, u.label),
];
final List<SelectOption<PartCondition>> _conditions = [
  for (final c in PartCondition.values) SelectOption(c, c.label),
];

/// The field treatment the comp specifies for this step — a rounded rectangle
/// with one light outline, and a label a size down from the app's 16. Named
/// once here so the seven controls on the screen cannot drift apart, and held
/// LOCAL to this file because it is the only screen reconciled against the
/// comp so far; the widgets themselves still default to the old styling.
const double _kFieldRadius = AppSizes.radiusSm;
const double _kLabelSize = AppTextScale.body;

/// Step 2 — the part itself. Stateful because the draft is a plain object: a
/// chip tap changes no observable, so the repaint has to be asked for.
///
/// FIELD ORDER follows the comp — name, number, then the selects, the
/// description and the upload card. Category and Region sit among them
/// because the comp omits both and neither can be dropped: `validate()` fails
/// on `categoryId` and `region`, `toBody()` throws without them, and region is
/// half the supplier-matching key. Removing them here would strand the buyer
/// on step 3 behind two errors with no field to fix them in. Region is a
/// select rather than the twelve-chip grid it was, so the three enum pickers
/// on this screen read as one control instead of two.
class PartDetailsStepView extends StatefulWidget {
  const PartDetailsStepView({
    super.key, required this.controller, required this.partName,
    required this.partNumber, required this.description, required this.onNext,
  });

  final NewRequestController controller;
  final TextEditingController partName, partNumber, description;
  final VoidCallback onNext;

  @override
  State<PartDetailsStepView> createState() => _PartDetailsStepViewState();
}

class _PartDetailsStepViewState extends State<PartDetailsStepView> {
  NewRequestController get _c => widget.controller;

  void _edited(String path) {
    _c.clearFieldError(path);
    _c.scheduleSave();
    setState(() {});
  }

  Future<void> _pickCategory() => Get.bottomSheet(
    CategoryPickerSheet(
      selectedId: _c.draft.categoryId,
      onSelected: (category) {
        _c.draft.categoryId = category.id;
        _c.draft.categoryName = category.name;
        _edited('categoryId');
      },
    ),
    isScrollControlled: true,
  );

  /// Uploads start the moment the tray changes rather than at submit: a
  /// presigned URL lives about 300 seconds, and submit is not gated on them.
  Future<void> _addPhotos() async {
    await _c.images.addFromPicker();
    await _c.images.uploadAll();
  }

  static bool _isConsumableWearItem(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return false;
    const consumableKeywords = [
      'brake pad',
      'brake pads',
      'brakepad',
      'brakepads',
      'brake disc',
      'brake discs',
      'oil filter',
      'pollen filter',
      'cabin filter',
      'spark plug',
      'spark plugs',
      'wiper blade',
      'wiper blades',
    ];
    return consumableKeywords.any((k) => lower.contains(k));
  }

  @override
  Widget build(BuildContext context) {
    final d = _c.draft;
    return Obx(() {
      // `toList()` INSIDE this closure IS the subscription: RxList registers
      // against Obx's observer proxy from its `value` getter, which every read
      // path (length, [], iterator, toList) goes through. Read BARE in
      // ImageTray.build — outside the tracking zone — this Obx subscribed to
      // nothing, and a second photo, an X and every transition
      // `slots.refresh()` announced repainted nothing. The snapshot also denies
      // the child a live RxList to re-lose it on, and gives the counter below
      // a length taken from the same read.
      final photos = _c.images.slots.toList(growable: false);
      // Only THIS step's keys: a registration typed on step 1 is step 1's
      // business, and blocking Next over it would strand the buyer on a screen
      // that cannot show them the field to fix.
      final missing = d.validateStep(RequestDraft.partStepKeys);
      return Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: AppSizes.DEFAULT,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Container(
              margin: const EdgeInsets.only(bottom: AppSizes.s16),
              padding: const EdgeInsets.all(AppSizes.s12),
              decoration: BoxDecoration(
                color: kSecondaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(_kFieldRadius),
                border: Border.all(color: kSecondaryColor.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: kSecondaryColor),
                  SizedBox(width: 10),
                  Expanded(
                    child: MyText(
                      text:
                          'Autonect connects you with verified breaker yards for reclaimed parts (e.g. headlights, body panels, doors, interior, suspension, mechanical assemblies).',
                      size: 12,
                      weight: FontWeight.w500,
                      color: kBlackColor,
                    ),
                  ),
                ],
              ),
            ),
            CountedTextField(controller: widget.partName, maxLength: 150,
                labelText: 'Part Name',
                hintText: 'e.g. Nearside Headlight, Front Door, Suspension Strut',
                isRequired: true,
                errorText: _c.fieldErrorFor('partName'),
                radius: _kFieldRadius, borderColor: kFieldBorderColor,
                labelSize: _kLabelSize, quietCounter: true,
                onChanged: (v) { d.partName = v; _edited('partName'); }),
            if (_isConsumableWearItem(widget.partName.text)) ...[
              const SizedBox(height: 6),
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.s8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFE65100),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: MyText(
                        text:
                            'Notice: Breaker yards typically supply reclaimed OEM parts (calipers, ABS units, panels, suspension) rather than consumable wear items like brake pads or filters.',
                        size: 11,
                        weight: FontWeight.w500,
                        color: Color(0xFFBF360C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            CountedTextField(controller: widget.partNumber, maxLength: 80,
                labelText: 'Part Number',
                errorText: _c.fieldErrorFor('partNumber'),
                radius: _kFieldRadius, borderColor: kFieldBorderColor,
                labelSize: _kLabelSize, quietCounter: true,
                onChanged: (v) { d.partNumber = v; _edited('partNumber'); }),
            _label('Category', isRequired: true),
            _PickerRow(value: d.categoryName, hint: 'Choose a part category',
                errorText: _c.fieldErrorFor('categoryId'), onTap: _pickCategory),
            // Required, and half the supplier-matching key. Pre-selected from
            // the buyer's last successful create, never silently defaulted: the
            // User table has no region column to read one from.
            EnumSelectField<Region>(title: 'Region', isRequired: true,
                hint: 'Choose your region', options: _regions,
                value: d.region, errorText: _c.fieldErrorFor('region'),
                borderColor: kFieldBorderColor, titleSize: _kLabelSize,
                onChanged: (r) { d.region = r; _edited('region'); }),
            EnumSelectField<RequestUrgency>(title: 'Set Urgency',
                isRequired: true,
                hint: 'How soon do you need it?', options: _urgencies,
                value: d.urgency, errorText: _c.fieldErrorFor('urgency'),
                borderColor: kFieldBorderColor, titleSize: _kLabelSize,
                onChanged: (u) { d.urgency = u; _edited('urgency'); }),
            EnumSelectField<PartCondition>(title: 'Condition',
                isRequired: true,
                hint: 'New, used or either', options: _conditions,
                value: d.condition, errorText: _c.fieldErrorFor('condition'),
                borderColor: kFieldBorderColor, titleSize: _kLabelSize,
                onChanged: (v) { d.condition = v; _edited('condition'); }),
            CountedTextField(controller: widget.description, maxLength: 2000,
                maxLines: 4, labelText: 'Description',
                hintText: 'Describe part details',
                errorText: _c.fieldErrorFor('description'),
                radius: _kFieldRadius, borderColor: kFieldBorderColor,
                labelSize: _kLabelSize, quietCounter: true,
                onChanged: (v) { d.description = v; _edited('description'); }),
            // The comp's card carries no count, but five is a hard server-side
            // cap and the buyer is owed it somewhere — so it rides the label
            // row and leaves the card exactly as drawn.
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _label('Upload Photo'),
              MyText(text: '${kMaxRequestImages - photos.length} left',
                  size: AppTextScale.label, color: kGreyTextColor,
                  paddingBottom: AppSizes.s8),
            ]),
            ImageTray(images: photos, onAdd: _addPhotos,
                onRemove: _c.images.remove, onRetry: _c.images.retry),
            if (_c.images.rejectionMessage.value case final m?)
              MyText(text: m, size: AppTextScale.label, color: kRedColor,
                  paddingTop: AppSizes.s8),
            if (_c.fieldErrorFor('imageKeys') case final e?)
              MyText(text: e, size: AppTextScale.label, color: kRedColor,
                  paddingTop: AppSizes.s8),
          ]),
        )),
        WizardBottomBar(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A disabled CTA with nothing beside it is a dead end — the buyer
            // cannot tap it to find out what is wrong. This is the same pairing
            // the confirm step uses for Send Request.
            if (missing.isNotEmpty)
              MyText(text: 'Still needed: ${_missingLabels(missing)}',
                  size: AppTextScale.label, color: kGreyTextColor,
                  maxLines: 2, textOverflow: TextOverflow.ellipsis,
                  paddingBottom: AppSizes.s8),
            MyButton(buttonText: 'Next', enabled: missing.isEmpty,
                onTap: widget.onNext),
          ],
        )),
      ]);
    });
  }

  Widget _label(String text, {bool isRequired = false}) => FieldLabel(
      text: text, isRequired: isRequired, size: _kLabelSize,
      weight: AppWeights.semibold, color: kBlackColor,
      paddingBottom: AppSizes.s8);

  /// The screen's own labels, in the order the fields appear, NOT validate()'s
  /// sentences. 'Part name must be at least 2 characters' is exactly right on
  /// the field and wrong concatenated five deep into a bottom bar. Keyed by the
  /// SERVER path, so this map and the controls above cannot drift apart without
  /// a missing key showing up verbatim in the summary.
  static const Map<String, String> _fieldLabels = {
    'partName': 'Part Name',
    'partNumber': 'Part Number',
    'categoryId': 'Category',
    'region': 'Region',
    'urgency': 'Set Urgency',
    'condition': 'Condition',
    'description': 'Description',
  };

  String _missingLabels(Map<String, String> missing) => [
    for (final e in _fieldLabels.entries)
      if (missing.containsKey(e.key)) e.value,
  ].join(', ');
}

/// A read-only row that opens a sheet. Not a dropdown: the category list is
/// long, hierarchical and searchable, none of which a dropdown does well.
class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.value, required this.hint, this.errorText,
      required this.onTap});

  final String? value, errorText;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MyRippleEffect(
        radius: _kFieldRadius, onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.s16),
          decoration: AppStyling().myDecoration(color: kPrimaryColor,
              radius: _kFieldRadius,
              borderColor: errorText == null ? kFieldBorderColor : kRedColor),
          child: Row(children: [
            Expanded(child: MyText(text: value ?? hint, maxLines: 1,
                size: AppTextScale.body, textOverflow: TextOverflow.ellipsis,
                color: value == null ? kGreyTextColor : kBlackColor)),
            const Icon(Icons.keyboard_arrow_right_rounded,
                color: kGreyTextColor),
          ]),
        ),
      ),
      if (errorText != null)
        MyText(text: errorText!, size: AppTextScale.label, color: kRedColor,
            paddingTop: AppSizes.s4, paddingLeft: AppSizes.s8),
      const SizedBox(height: AppSizes.s16),
    ],
  );
}

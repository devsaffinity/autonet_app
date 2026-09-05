import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/screens/buyer/new_part_request/widgets/category_picker_sheet.dart';
import 'package:autonect/view/widget/choice_chips_field.dart';
import 'package:autonect/view/widget/counted_text_field.dart';
import 'package:autonect/view/widget/enum_select_field.dart';
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

/// Step 2 — the part itself. Stateful because the draft is a plain object: a
/// chip tap changes no observable, so the repaint has to be asked for.
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

  @override
  Widget build(BuildContext context) {
    final d = _c.draft;
    return Obx(() => Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CountedTextField(controller: widget.partName, maxLength: 150,
              labelText: 'Part name', hintText: 'Front brake discs',
              errorText: _c.fieldErrorFor('partName'),
              onChanged: (v) { d.partName = v; _edited('partName'); }),
          _label('Category'),
          _PickerRow(value: d.categoryName, hint: 'Choose a part category',
              errorText: _c.fieldErrorFor('categoryId'), onTap: _pickCategory),
          CountedTextField(controller: widget.partNumber, maxLength: 80,
              labelText: 'Part number (optional)',
              errorText: _c.fieldErrorFor('partNumber'),
              onChanged: (v) { d.partNumber = v; _edited('partNumber'); }),
          // Required, and half the supplier-matching key. Pre-selected from the
          // buyer's last successful create, never silently defaulted: the User
          // table has no region column to read one from.
          _label('Region'),
          ChoiceChipsField<Region>(options: _regions, selected: d.region,
              onSelect: (r) { d.region = r; _edited('region'); }),
          if (_c.fieldErrorFor('region') case final e?)
            MyText(text: e, size: AppTextScale.label, color: kRedColor,
                paddingTop: AppSizes.s4, paddingLeft: AppSizes.s8),
          const SizedBox(height: AppSizes.s16),
          EnumSelectField<RequestUrgency>(title: 'Urgency',
              hint: 'How soon do you need it?', options: _urgencies,
              value: d.urgency, errorText: _c.fieldErrorFor('urgency'),
              onChanged: (u) { d.urgency = u; _edited('urgency'); }),
          EnumSelectField<PartCondition>(title: 'Condition',
              hint: 'New, used or either', options: _conditions,
              value: d.condition, errorText: _c.fieldErrorFor('condition'),
              onChanged: (v) { d.condition = v; _edited('condition'); }),
          CountedTextField(controller: widget.description, maxLength: 2000,
              maxLines: 4, labelText: 'Description',
              hintText: 'Describe the part',
              errorText: _c.fieldErrorFor('description'),
              onChanged: (v) { d.description = v; _edited('description'); }),
          _label('Photos (up to $kMaxRequestImages)'),
          // `toList()` INSIDE this closure IS the subscription: RxList registers
          // against Obx's observer proxy from its `value` getter, which every
          // read path (length, [], iterator, toList) goes through. Passed BARE
          // the list was first read in ImageTray.build — outside the tracking
          // zone — so this Obx subscribed to nothing, and a second photo, an X
          // and every transition `slots.refresh()` announced repainted nothing.
          // The snapshot also denies the child a live RxList to re-lose it on.
          ImageTray(images: _c.images.slots.toList(growable: false),
              onAdd: _addPhotos, onRemove: _c.images.remove,
              onRetry: _c.images.retry),
          if (_c.images.rejectionMessage.value case final m?)
            MyText(text: m, size: AppTextScale.label, color: kRedColor,
                paddingTop: AppSizes.s8),
          if (_c.fieldErrorFor('imageKeys') case final e?)
            MyText(text: e, size: AppTextScale.label, color: kRedColor,
                paddingTop: AppSizes.s8),
        ]),
      )),
      WizardBottomBar(child: MyButton(buttonText: 'Next', onTap: widget.onNext)),
    ]));
  }

  Widget _label(String text) => MyText(text: text,
      size: AppTextScale.subtitle, weight: AppWeights.semibold,
      color: kBlackColor, paddingBottom: AppSizes.s8);
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
        radius: AppSizes.radiusSm, onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.s16),
          decoration: AppStyling().myDecoration(color: kPrimaryColor,
              radius: AppSizes.radiusSm,
              borderColor: errorText == null
                  ? kBlackColor.withValues(alpha: .5) : kRedColor),
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

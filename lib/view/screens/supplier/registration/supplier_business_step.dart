import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/supplier/supplier_registration_controller.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/screens/supplier/registration/widgets/brand_chips.dart';
import 'package:autonect/view/screens/supplier/registration/widgets/category_grid.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/enum_select_field.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Business Registration" — the whole of `POST /v1/supplier/business` on ONE
/// screen, as the design draws it.
///
/// This replaces three separate wizard steps (business info, regions,
/// catalogue). They asked for one payload and the design puts them on one page,
/// so splitting them made the supplier tap Continue three times to fill in a
/// single form and pushed validation failures two screens away from their
/// cause.
///
/// Stateful only to own its TextEditingControllers; the values live on
/// [SupplierRegistrationController].
class SupplierBusinessStep extends StatefulWidget {
  final VoidCallback onNext;
  const SupplierBusinessStep({super.key, required this.onNext});

  @override
  State<SupplierBusinessStep> createState() => _SupplierBusinessStepState();
}

class _SupplierBusinessStepState extends State<SupplierBusinessStep> {
  final _c = Get.find<SupplierRegistrationController>();
  late final TextEditingController _name = TextEditingController(
    text: _c.businessName.value,
  );
  late final TextEditingController _address = TextEditingController(
    text: _c.address.value,
  );

  @override
  void initState() {
    super.initState();
    _c.catalog.load();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: AppSizes.HORIZONTAL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.s20),
              _sectionLabel('Company Profile'),
              MyTextField(
                controller: _name,
                labelText: 'Business Name',
                hintText: 'e.g. JIN Motors',
                onChanged: (v) => _c.businessName.value = v,
              ),
              MyTextField(
                controller: _address,
                labelText: 'Address',
                hintText: 'e.g. 14 Bole Road, Manchester',
                onChanged: (v) => _c.address.value = v,
              ),
              // Real UK macro-regions, which is what the matching engine joins
              // on. The design's "Bermingham" is both a misspelling and a city;
              // the nearest real value is West Midlands.
              Obx(() => EnumSelectField<Region>(
                title: 'Region Served',
                hint: 'Select a region',
                value: _c.region,
                options: [
                  for (final r in Region.values) SelectOption(r, r.label),
                ],
                onChanged: (r) => _c.region = r,
              )),
              _sectionLabel('Supply Specialization'),
              MyText(
                text: 'Manufacturer Focus (Car Brands)',
                size: AppTextScale.caption,
                color: kGreyTextColor,
                paddingBottom: AppSizes.s12,
              ),
              Obx(() => BrandChips(
                options: _c.brandOptions,
                selected: _c.brands.toSet(),
                onToggle: _c.toggleBrand,
                onAdd: _promptAddBrand,
              )),
              const SizedBox(height: AppSizes.s20),
              _sectionLabel('Part Categories'),
              Obx(() {
                // BOTH reads happen HERE, synchronously inside the Obx closure.
                // categoryIds used to be read from StateView's `builder`, which
                // runs inside StateView.build — a different performRebuild with
                // no tracking proxy installed — so it registered no dependency
                // and tapping a card updated the list while the grid never
                // repainted. Selection looked completely dead.
                final selected = _c.categoryIds.toSet();
                return StateView<List<PartCategory>>(
                  state: _c.catalog.categories.value,
                  onRetry: () => _c.catalog.load(forceRefresh: true),
                  emptyTitle: 'No categories yet',
                  builder: (_, all) => CategoryGrid(
                    categories: all,
                    selectedIds: selected,
                    onToggle: _c.toggleCategory,
                  ),
                );
              }),
              const SizedBox(height: AppSizes.s24),
            ],
          ),
        ),
      ),
      // Gated on everything the server requires, so a 400 can never be the
      // first time the supplier hears a field is missing.
      Obx(() => SupplierBottomButton(
        label: 'Next',
        onTap: _c.blockingReason == null ? widget.onNext : null,
      )),
    ],
  );

  Widget _sectionLabel(String text) => MyText(
    text: text,
    size: AppTextScale.body,
    weight: AppWeights.semibold,
    color: kSecondaryColor,
    paddingBottom: AppSizes.s12,
    paddingTop: AppSizes.s8,
  );

  /// "+ Add Brand". The column is free-form, so anything typed is accepted —
  /// deduped case-insensitively against the suggestions so 'audi' does not
  /// become a second Audi.
  Future<void> _promptAddBrand() async {
    final field = TextEditingController();
    final name = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: kPrimaryColor,
        title: MyText(text: 'Add a brand', size: AppTextScale.subtitle,
            weight: AppWeights.bold, color: kBlackColor),
        content: MyTextField(
          controller: field,
          hintText: 'e.g. Skoda',
          marginBottom: 0,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<String>(),
            child: MyText(text: 'Cancel', size: AppTextScale.body,
                color: kGreyTextColor),
          ),
          TextButton(
            onPressed: () => Get.back<String>(result: field.text),
            child: MyText(text: 'Add', size: AppTextScale.body,
                color: kSecondaryColor, weight: AppWeights.semibold),
          ),
        ],
      ),
    );
    field.dispose();
    if (name == null || name.trim().isEmpty) return;
    // False means it was already selected; saying nothing would look broken.
    if (!_c.addBrand(name)) {
      _c.toast('${name.trim()} is already selected');
    }
  }
}

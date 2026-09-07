import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/controller/supplier/supplier_registration_controller.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 3 of 5 — the backend `PartCategory` multi-select.
///
/// The list is READ FROM THE SERVER. It used to be ten hard-coded names
/// ('Engine', 'Brakes', 'Body Panels'…) with two pre-selected — but
/// `POST /v1/supplier/business` takes category UUIDs and validates every one of
/// them, so a name could never have been submitted, and those names do not
/// match the seeded taxonomy anyway.
class SupplierCategoriesStep extends StatefulWidget {
  final VoidCallback onNext;
  const SupplierCategoriesStep({super.key, required this.onNext});

  @override
  State<SupplierCategoriesStep> createState() => _SupplierCategoriesStepState();
}

class _SupplierCategoriesStepState extends State<SupplierCategoriesStep> {
  final _c = Get.find<SupplierRegistrationController>();

  @override
  void initState() {
    super.initState();
    // CatalogController is permanent and memoises for the session, so paging
    // back to this step costs nothing.
    _c.catalog.load();
  }

  @override
  Widget build(BuildContext context) {
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
                      "Which part categories do you stock? Only matching requests will reach your Leads tab.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 20,
                  paddingTop: 24,
                ),
                // Both Obx closures read their own Rx synchronously. A read from
                // inside StateView's builder would run in a different build and
                // register no dependency.
                Obx(() => SupplierCard(
                  child: Row(
                    children: [
                      CommonImageView(svgPath: Assets.imagesPartBox),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MyText(
                          text: _c.categoryIds.length == 1
                              ? '1 category in your catalogue'
                              : '${_c.categoryIds.length} categories in your catalogue',
                          size: 14,
                          weight: FontWeight.w600,
                          color: kBlackColor,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                Obx(() => StateView<List<PartCategory>>(
                  state: _c.catalog.categories.value,
                  onRetry: () => _c.catalog.load(forceRefresh: true),
                  emptyTitle: 'No categories yet',
                  builder: (_, all) => _chips(all),
                )),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        // At least one category is required by the server, so the step gates
        // rather than letting the supplier discover it at submit.
        Obx(() => SupplierBottomButton(
          label: 'Next',
          onTap: _c.categoryIds.isEmpty ? null : widget.onNext,
        )),
      ],
    );
  }

  /// Selection is by ID; the chips only render names. Two categories could
  /// share a name across different parents and still be distinct rows.
  Widget _chips(List<PartCategory> all) {
    final byName = {for (final c in all) c.name: c.id};
    final selectedNames = {
      for (final c in all)
        if (_c.categoryIds.contains(c.id)) c.name,
    };
    return SupplierChoiceChips(
      options: [for (final c in all) c.name],
      selected: selectedNames,
      onToggle: (name) {
        final id = byName[name];
        if (id != null) _c.toggleCategory(id);
      },
    );
  }
}

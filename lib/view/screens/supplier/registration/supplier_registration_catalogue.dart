import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Step 3 of 5 — the backend `PartCategory` multi-select.
class SupplierCategoriesStep extends StatefulWidget {
  final VoidCallback onNext;
  const SupplierCategoriesStep({super.key, required this.onNext});

  @override
  State<SupplierCategoriesStep> createState() => _SupplierCategoriesStepState();
}

class _SupplierCategoriesStepState extends State<SupplierCategoriesStep> {
  static const List<String> _categories = [
    'Engine',
    'Transmission',
    'Brakes',
    'Suspension',
    'Electrical',
    'Body Panels',
    'Interior',
    'Wheels & Tyres',
    'Exhaust',
    'Cooling',
  ];
  final Set<String> _selected = {'Engine', 'Brakes'};

  void _toggle(String c) => setState(
    () => _selected.contains(c) ? _selected.remove(c) : _selected.add(c),
  );

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
                SupplierCard(
                  child: Row(
                    children: [
                      CommonImageView(svgPath: Assets.imagesPartBox),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MyText(
                          text:
                              '${_selected.length} categories in your catalogue',
                          size: 14,
                          weight: FontWeight.w600,
                          color: kBlackColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SupplierChoiceChips(
                  options: _categories,
                  selected: _selected,
                  onToggle: _toggle,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        SupplierBottomButton(label: 'Next', onTap: widget.onNext),
      ],
    );
  }
}

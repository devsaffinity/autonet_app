import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The supplier twin of ManageServicesPage: which part categories are stocked
/// and which regions are served. Editing these is what changes the leads feed.
class ManageCatalogPage extends StatefulWidget {
  const ManageCatalogPage({super.key});

  @override
  State<ManageCatalogPage> createState() => _ManageCatalogPageState();
}

class _ManageCatalogPageState extends State<ManageCatalogPage> {
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

  static const List<String> _regions = [
    'London',
    'South East',
    'South West',
    'East of England',
    'East Midlands',
    'West Midlands',
    'Yorkshire',
    'North East',
    'North West',
    'Wales',
    'Scotland',
    'Northern Ireland',
  ];

  final Set<String> _selectedCategories = {'Engine', 'Brakes'};
  final Set<String> _selectedRegions = {'London', 'South East'};

  void _toggle(Set<String> set, String value) => setState(
    () => set.contains(value) ? set.remove(value) : set.add(value),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Catalogue'),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              text: 'Part categories',
              size: 16,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
            MyText(
              paddingTop: 2,
              paddingBottom: 12,
              text: 'Only requests in these categories reach your Leads tab.',
              size: 12,
              weight: FontWeight.w400,
              color: kGreyTextColor,
            ),
            SupplierChoiceChips(
              options: _categories,
              selected: _selectedCategories,
              onToggle: (c) => _toggle(_selectedCategories, c),
            ),
            const SizedBox(height: 24),
            MyText(
              text: 'Regions served',
              size: 16,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
            MyText(
              paddingTop: 2,
              paddingBottom: 12,
              text: 'Buyer requests are matched on region before category.',
              size: 12,
              weight: FontWeight.w400,
              color: kGreyTextColor,
            ),
            SupplierChoiceChips(
              options: _regions,
              selected: _selectedRegions,
              onToggle: (r) => _toggle(_selectedRegions, r),
            ),
            const SizedBox(height: 30),
            MyButton(buttonText: 'Save Catalogue', onTap: Get.back),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

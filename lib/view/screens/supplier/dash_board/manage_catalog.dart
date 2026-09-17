import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/catalog_controller.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
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
  final ProfileController _profile = ProfileController.ensure();
  final CatalogController _catalog = CatalogController.ensure();

  final Set<String> _selectedCategoryIds = <String>{};
  final Set<Region> _selectedRegions = <Region>{};
  bool _seeded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_profile.load(), _catalog.load()]);
    if (!mounted) return;
    final sp = _profile.me?.supplierProfile;
    if (sp != null && !_seeded) {
      _selectedCategoryIds.addAll(sp.categories.map((c) => c.id));
      _selectedRegions.addAll(sp.regionsServed);
      _seeded = true;
      setState(() {});
    }
  }

  void _toggleCategory(String id) => setState(() {
    if (_selectedCategoryIds.contains(id)) {
      _selectedCategoryIds.remove(id);
    } else {
      _selectedCategoryIds.add(id);
    }
  });

  void _toggleRegion(Region region) => setState(() {
    if (_selectedRegions.contains(region)) {
      _selectedRegions.remove(region);
    } else {
      _selectedRegions.add(region);
    }
  });

  Future<void> _save() async {
    if (_selectedCategoryIds.isEmpty) {
      displayToast(msg: 'Please pick at least one part category');
      return;
    }
    if (_selectedRegions.isEmpty) {
      displayToast(msg: 'Please pick at least one region served');
      return;
    }

    final sp = _profile.me?.supplierProfile;
    if (sp == null) {
      Get.back();
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = Get.find<ProfileRepository>();
      final draft = SupplierBusinessDraft(
        businessName: sp.businessName,
        address: sp.address,
        regionsServed: _selectedRegions.toList(),
        categoryIds: _selectedCategoryIds.toList(),
        brands: sp.brands,
        specialization: sp.specialization,
      );

      final res = await repo.registerSupplierBusiness(draft);
      if (res is Ok<MeProfile>) {
        _profile.load();
        if (Get.isRegistered<SupplierHomeController>()) {
          SupplierHomeController.ensure().load();
        }
        displayToast(msg: 'Catalogue updated successfully');
        Get.back();
      } else if (res is Err<MeProfile>) {
        displayToast(msg: res.error.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
            Obx(() {
              return StateView<List<PartCategory>>(
                state: _catalog.categories.value,
                onRetry: _catalog.load,
                emptyTitle: 'No categories available',
                builder: (_, cats) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cats.map((cat) {
                      final selected = _selectedCategoryIds.contains(cat.id);
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: selected,
                        selectedColor: kSecondaryColor,
                        backgroundColor: kPrimaryColor,
                        labelStyle: TextStyle(
                          color: selected ? kWhiteColor : kBlackColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: selected
                              ? kSecondaryColor
                              : kGreyTextColor.withValues(alpha: .3),
                        ),
                        onSelected: (_) => _toggleCategory(cat.id),
                      );
                    }).toList(),
                  );
                },
              );
            }),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Region.values.map((region) {
                final selected = _selectedRegions.contains(region);
                return ChoiceChip(
                  label: Text(region.label),
                  selected: selected,
                  selectedColor: kSecondaryColor,
                  backgroundColor: kPrimaryColor,
                  labelStyle: TextStyle(
                    color: selected ? kWhiteColor : kBlackColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected
                        ? kSecondaryColor
                        : kGreyTextColor.withValues(alpha: .3),
                  ),
                  onSelected: (_) => _toggleRegion(region),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            MyButton(
              buttonText: 'Save Catalogue',
              loading: _saving,
              onTap: _saving ? null : _save,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

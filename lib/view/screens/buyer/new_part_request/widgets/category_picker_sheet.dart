import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/catalog_controller.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/search_field.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Half the sheet's own height, so the list scrolls inside the sheet instead of
/// the sheet growing past the screen on a long catalogue.
const double _listHeightFactor = .45;

/// The wizard's category picker.
///
/// `GET /v1/categories` returns a FLAT array with a `parentId` — it is called a
/// tree everywhere and is not one — and takes no query parameters, so the
/// search below is client-side and a keystroke never becomes a request.
///
/// ANY node is a legal `categoryId`: the server does a bare `findUnique` and
/// never inspects children, so no leaf-only rule is imposed here.
class CategoryPickerSheet extends StatefulWidget {
  const CategoryPickerSheet({super.key, required this.onSelected,
      this.selectedId});

  final ValueChanged<PartCategory> onSelected;
  final String? selectedId;

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  late final CatalogController _c;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _c = CatalogController.ensure();
    // The controller is permanent and the list is public reference data the
    // server itself caches for 24h, so a second open costs nothing.
    if (_c.categories.value is! Data<List<PartCategory>>) _c.load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _choose(PartCategory category) {
    widget.onSelected(category);
    Get.back();
  }

  @override
  Widget build(BuildContext context) => MyBSheet(
    // MyBSheet's btnText defaults to the leftover literal 'Assign Penalty'.
    btnText: 'Close',
    onTap: () => Get.back(),
    body: SizedBox(
      height: MediaQuery.sizeOf(context).height * _listHeightFactor,
      child: Column(children: [
        MyText(text: 'Choose a part category', size: AppTextScale.title,
            weight: AppWeights.bold, color: kBlackColor,
            paddingBottom: AppSizes.s12),
        SearchField(
          controller: _search, hint: 'Search categories',
          onChanged: (v) => setState(() => _query = v),
        ),
        Expanded(child: Obx(() => StateView<List<PartCategory>>(
          state: _c.categories.value,
          onRetry: () => _c.load(forceRefresh: true),
          emptyTitle: 'No categories yet',
          emptyBody: 'Nobody has published a category to pick from.',
          builder: (_, all) => _list(all),
        ))),
      ]),
    ),
  );

  Widget _list(List<PartCategory> all) {
    final items = _c.filter(_query);
    if (items.isEmpty) {
      return Center(
        child: MyText(text: 'No category matches "$_query"',
            size: AppTextScale.body, color: kGreyTextColor,
            textAlign: TextAlign.center),
      );
    }
    // Only a parent that is itself in the payload gets a caption: a dangling
    // parentId must not print as a missing group header.
    final names = {for (final c in all) c.id: c.name};
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) => _CategoryRow(
        category: items[i],
        parentName: names[items[i].parentId],
        selected: items[i].id == widget.selectedId,
        onTap: () => _choose(items[i]),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.selected,
      required this.onTap, this.parentName});

  final PartCategory category;
  final String? parentName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MyRippleEffect(
    radius: AppSizes.radiusSm,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parentName != null)
              MyText(text: parentName!, size: AppTextScale.caption,
                  color: kGreyTextColor),
            MyText(text: category.name, size: AppTextScale.body,
                color: kBlackColor,
                weight: selected ? AppWeights.bold : AppWeights.regular),
          ],
        )),
        if (selected)
          const Icon(Icons.check_rounded, color: kSecondaryColor,
              size: AppSizes.s20),
      ]),
    ),
  );
}

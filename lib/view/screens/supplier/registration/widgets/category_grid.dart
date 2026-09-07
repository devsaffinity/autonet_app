import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// How many cards sit in the grid before "BROWSE MORE" takes the last cell.
///
/// Five plus the browse card fills three rows of two exactly, matching the
/// design. The rest open in a sheet.
const int _kFeaturedCount = 5;

/// The part-category picker: a two-column grid of icon cards.
///
/// Icons are chosen CLIENT-SIDE from the category name. `PartCategory` carries
/// id, name and parentId and nothing else, so there is no iconKey to read; an
/// unmapped name falls back to a generic part glyph rather than rendering an
/// empty cell, which is what keeps this from breaking the first time an admin
/// adds a category.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<PartCategory> categories;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  static const Map<String, IconData> _iconByName = {
    'Engine': Icons.settings_suggest_outlined,
    'Transmission': Icons.swap_horiz_rounded,
    'Brakes': Icons.disc_full_outlined,
    'Suspension & Steering': Icons.airline_seat_legroom_reduced_outlined,
    'Electrical': Icons.bolt_outlined,
    'Body & Exterior': Icons.directions_car_filled_outlined,
    'Interior': Icons.event_seat_outlined,
    'Wheels & Tyres': Icons.trip_origin_rounded,
    'Exhaust': Icons.air_rounded,
    'Cooling': Icons.ac_unit_rounded,
    'Filters': Icons.filter_alt_outlined,
    'Lighting': Icons.lightbulb_outline_rounded,
  };

  static IconData iconFor(String name) =>
      _iconByName[name] ?? Icons.build_outlined;

  @override
  Widget build(BuildContext context) {
    // Anything already selected is pulled into the visible grid, so a supplier
    // returning to this screen can see and deselect their picks without having
    // to open the sheet to find them.
    final featured = _featured();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.s12,
          crossAxisSpacing: AppSizes.s12,
          // Wide and short, as drawn. Below 2.4 the two-line labels clip at
          // large text scales.
          childAspectRatio: 2.4,
          children: [
            for (final c in featured)
              _CategoryCard(
                label: c.name,
                icon: iconFor(c.name),
                selected: selectedIds.contains(c.id),
                onTap: () => onToggle(c.id),
              ),
            if (categories.length > featured.length)
              _BrowseMoreCard(onTap: () => _openSheet(context)),
          ],
        ),
        if (selectedIds.isNotEmpty)
          MyText(
            text: selectedIds.length == 1
                ? '1 category selected'
                : '${selectedIds.length} categories selected',
            size: AppTextScale.caption,
            color: kSecondaryColor,
            weight: AppWeights.semibold,
            paddingTop: AppSizes.s8,
          ),
      ],
    );
  }

  List<PartCategory> _featured() {
    final selected = [for (final c in categories) if (selectedIds.contains(c.id)) c];
    final rest = [for (final c in categories) if (!selectedIds.contains(c.id)) c];
    final out = [...selected, ...rest];
    return out.length <= _kFeaturedCount ? out : out.sublist(0, _kFeaturedCount);
  }

  void _openSheet(BuildContext context) {
    Get.bottomSheet(
      _AllCategoriesSheet(
        categories: categories,
        selectedIds: selectedIds,
        onToggle: onToggle,
      ),
      backgroundColor: kPrimaryColor,
      isScrollControlled: true,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
        decoration: BoxDecoration(
          color: selected ? kLightOrangeColor : kMutedSurfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: selected ? kSecondaryColor : kTransperentColor,
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Icon(icon,
                  size: AppSizes.s20,
                  color: selected ? kSecondaryColor : kGreyTextColor),
              const SizedBox(width: AppSizes.s8),
              Expanded(
                child: MyText(
                  text: label,
                  size: AppTextScale.label,
                  weight: selected ? AppWeights.semibold : AppWeights.medium,
                  color: kBlackColor,
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BrowseMoreCard extends StatelessWidget {
  const _BrowseMoreCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Browse all categories',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kMutedSurfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: ExcludeSemantics(
          child: MyText(
            text: 'BROWSE MORE',
            size: AppTextScale.label,
            weight: AppWeights.semibold,
            color: kBlackColor,
          ),
        ),
      ),
    ),
  );
}

/// Every category, so nothing is unreachable behind the featured five.
class _AllCategoriesSheet extends StatefulWidget {
  const _AllCategoriesSheet({
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<PartCategory> categories;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  State<_AllCategoriesSheet> createState() => _AllCategoriesSheetState();
}

class _AllCategoriesSheetState extends State<_AllCategoriesSheet> {
  // Local copy: the sheet is outside the caller's Obx, so it repaints itself.
  late final Set<String> _selected = {...widget.selectedIds};

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: AppSizes.DEFAULT,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(text: 'Part Categories', size: AppTextScale.subtitle,
              weight: AppWeights.bold, color: kBlackColor,
              paddingBottom: AppSizes.s12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in widget.categories)
                  CheckboxListTile(
                    value: _selected.contains(c.id),
                    onChanged: (_) {
                      widget.onToggle(c.id);
                      setState(() {
                        _selected.contains(c.id)
                            ? _selected.remove(c.id)
                            : _selected.add(c.id);
                      });
                    },
                    activeColor: kSecondaryColor,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(CategoryGrid.iconFor(c.name),
                        size: AppSizes.s20, color: kGreyTextColor),
                    title: MyText(text: c.name, size: AppTextScale.body,
                        color: kBlackColor),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s8),
        ],
      ),
    ),
  );
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Pill tab strip — the same kLightBlueColor track + white AnimatedContainer
/// thumb the electrician booking-requests screen draws, parameterised.
///
/// NOTE: the binding spec promotes this to lib/view/widget/my_pill_tabs.dart as
/// `MyPillTabs`. That file lives outside this agent's owned directory, so the
/// supplier tree carries its own copy for now; swap the import when the shared
/// widget lands.
class SupplierPillTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const SupplierPillTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: kLightBlueColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = selectedIndex == i;
          return Expanded(
            child: MyRippleEffect(
              onTap: () => onChanged(i),
              radius: 100,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? kWhiteColor : kTransperentColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: MyText(
                  text: labels[i],
                  size: 14,
                  weight: FontWeight.w600,
                  color: isSelected ? kSecondaryColor : kBlackColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Rounded status pill — the 'Brand New' condition badge from offer_detail.dart
/// with its colour pair exposed.
class SupplierStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const SupplierStatusBadge({
    super.key,
    required this.label,
    this.color = kSecondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: AppStyling().myDecoration(
        color: color.withValues(alpha: .12),
        borderColor: kTransperentColor,
        radius: 100,
      ),
      child: MyText(
        text: label,
        size: 12,
        color: color,
        weight: FontWeight.w600,
      ),
    );
  }
}

/// Selectable chip Wrap — the 'Brands Supported' idiom from the electrician
/// registration wizard, used for regions, categories and conditions.
class SupplierChoiceChips extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const SupplierChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return MyRippleEffect(
          radius: 100,
          onTap: () => onToggle(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: AppStyling().myDecoration(
              color: isSelected ? kLightOrangeColor : kPrimaryColor,
              borderColor: isSelected ? kSecondaryColor : kTertiaryColor,
              thickness: 2,
              radius: 100,
            ),
            child: MyText(
              text: o,
              size: 12,
              weight: FontWeight.w600,
              color: isSelected ? kSecondaryColor : kBlackColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// icon + label + chevron menu row for the supplier profile.
///
/// NOTE: the binding spec promotes this to lib/view/widget/profile_menu_tile.dart
/// as `ProfileMenuTile`, shared with the buyer and electrician profiles. That
/// file is outside this agent's owned directory; swap the import when it lands.
class SupplierMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final String? trailingText;
  final Widget? trailing;
  const SupplierMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = kBlackColor,
    this.trailingText,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppStyling().myShadowStyle(),
      child: MyRippleEffect(
        radius: 12,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kLightOrangeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
                  text: label,
                  size: 14,
                  weight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 8),
              ] else if (trailingText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: MyText(
                    text: trailingText!,
                    size: 12,
                    weight: FontWeight.w600,
                    color: kSecondaryColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: kGreyTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

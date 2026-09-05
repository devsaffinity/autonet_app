import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:flutter/material.dart';

/// The one search input. It is a thin wrapper over MyTextField rather than a
/// second text field, so the pill radius and focus treatment stay in one place.
///
/// Debouncing is the CALLER's job: [onChanged] fires on every keystroke and a
/// controller that turns each one into a request would burn the global limiter.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Search',
    this.controller,
    this.marginBottom = AppSizes.s16,
  });

  final ValueChanged<String> onChanged;
  final String? hint;
  final TextEditingController? controller;
  final double marginBottom;

  @override
  Widget build(BuildContext context) => MyTextField(
    controller: controller,
    hintText: hint,
    onChanged: onChanged,
    marginBottom: marginBottom,
    textCapitalization: TextCapitalization.none,
    textInputAction: TextInputAction.search,
    prefix: const Padding(
      padding: EdgeInsets.only(left: AppSizes.s16, right: AppSizes.s8),
      child: Icon(Icons.search_rounded, color: kGreyTextColor,
          size: AppSizes.s20),
    ),
  );
}

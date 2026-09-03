import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Step 1 of 5 — SupplierProfile.businessName / address / phone.
class SupplierBusinessStep extends StatelessWidget {
  final VoidCallback onNext;
  const SupplierBusinessStep({super.key, required this.onNext});

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
                      "Tell buyers who they are ordering from. This is the name and address that appears on every offer you send.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),
                MyTextField(
                  labelText: 'Business Name',
                  hintText: 'e.g. AutoParts Hub',
                ),
                MyTextField(
                  labelText: 'Business Address',
                  hintText: 'e.g. 14 Bole Road, Manchester',
                ),
                MyTextField(
                  labelText: 'Phone Number',
                  hintText: '+44 7000 000000',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                const SupplierNoteCard(
                  title: 'Privacy First',
                  body:
                      "Your data is encrypted and used solely for identity verification in our partner ecosystem.",
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        SupplierBottomButton(label: 'Continue', onTap: onNext),
      ],
    );
  }
}

/// Step 2 of 5 — the 12 backend `Region` values as chips.
class SupplierRegionsStep extends StatefulWidget {
  final VoidCallback onNext;
  const SupplierRegionsStep({super.key, required this.onNext});

  @override
  State<SupplierRegionsStep> createState() => _SupplierRegionsStepState();
}

class _SupplierRegionsStepState extends State<SupplierRegionsStep> {
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
  final Set<String> _selected = {'London'};

  void _toggle(String r) => setState(
    () => _selected.contains(r) ? _selected.remove(r) : _selected.add(r),
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
                      "Pick every region you can deliver to. Buyer requests are matched to suppliers on region first, so choose carefully.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),
                SupplierChoiceChips(
                  options: _regions,
                  selected: _selected,
                  onToggle: _toggle,
                ),
                const SizedBox(height: 20),
                MyText(
                  text: '${_selected.length} of 12 regions selected',
                  size: 12,
                  weight: FontWeight.w600,
                  color: kSecondaryColor,
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

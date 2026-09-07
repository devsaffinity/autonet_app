import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/controller/supplier/supplier_registration_controller.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 1 of 5 — SupplierProfile.businessName / address.
///
/// Stateful only to own its TextEditingControllers: the wizard is a PageView,
/// so a step is disposed and rebuilt as the supplier moves, and text kept in
/// the widget would be gone by the time they reach submit. The VALUES live on
/// [SupplierRegistrationController]; these controllers only seed the fields
/// from it on the way back.
///
/// There is no phone field. It is not on the business-registration payload and
/// not in the design; the one that used to sit here collected a number nothing
/// ever sent.
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
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
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
                      "Tell buyers who they are ordering from. This is the name and address that appears on every offer you send.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),
                MyTextField(
                  controller: _name,
                  labelText: 'Business Name',
                  hintText: 'e.g. AutoParts Hub',
                  onChanged: (v) => _c.businessName.value = v,
                ),
                MyTextField(
                  controller: _address,
                  labelText: 'Business Address',
                  hintText: 'e.g. 14 Bole Road, Manchester',
                  onChanged: (v) => _c.address.value = v,
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
        // Gated: both fields are required server-side, and letting the supplier
        // walk to step 5 before failing tells them nothing about which of five
        // screens to go back to.
        Obx(() => SupplierBottomButton(
          label: 'Continue',
          onTap: _c.businessName.value.trim().isEmpty ||
                  _c.address.value.trim().isEmpty
              ? null
              : widget.onNext,
        )),
      ],
    );
  }
}

/// Step 2 of 5 — the 12 backend `Region` values as chips.
///
/// Reads the [Region] enum rather than a hard-coded list of strings. The
/// previous copy duplicated all twelve labels, which meant a label edit or a
/// thirteenth region silently disagreed with the wire values the server
/// accepts.
class SupplierRegionsStep extends StatelessWidget {
  final VoidCallback onNext;
  const SupplierRegionsStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SupplierRegistrationController>();
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
                // The whole subtree reads regionsServed, so it is inside ONE
                // Obx closure. A read from a child's builder registers no
                // dependency and would never repaint.
                Obx(() {
                  final selectedLabels = {
                    for (final r in c.regionsServed) r.label,
                  };
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SupplierChoiceChips(
                        options: [for (final r in Region.values) r.label],
                        selected: selectedLabels,
                        onToggle: (label) => c.toggleRegion(
                          Region.values.firstWhere((r) => r.label == label),
                        ),
                      ),
                      const SizedBox(height: 20),
                      MyText(
                        text:
                            '${c.regionsServed.length} of ${Region.values.length} regions selected',
                        size: 12,
                        weight: FontWeight.w600,
                        color: kSecondaryColor,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        // At least one region is required by the server.
        Obx(() => SupplierBottomButton(
          label: 'Next',
          onTap: c.regionsServed.isEmpty ? null : onNext,
        )),
      ],
    );
  }
}

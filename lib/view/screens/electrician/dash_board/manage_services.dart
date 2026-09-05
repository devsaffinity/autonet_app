import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usage:
//   body: ManageServicesPage()
// ─────────────────────────────────────────────────────────────────────────────

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  // ── Services data ──────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _services = [
    {
      'name': 'ECU Remapping',
      'price': '\$349',
      'priceLabel': 'Fixed Price',
      'icon': Assets.imagesMsA,
    },
    {
      'name': 'Diagnostic Sweep',
      'price': '\$89',
      'priceLabel': 'Per Session',
      'icon': Assets.imagesMsB,
    },
    {
      'name': 'Wiring Repair',
      'price': '\$120/hr',
      'priceLabel': 'Hourly Rate',
      'icon': Assets.imagesMsC,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSizes.DEFAULT,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyBackButton(),
              // ── Header ───
              MyText(
                text: 'Manage Services',
                size: 28,
                weight: FontWeight.w800,
                color: kBlackColor,
                paddingBottom: 4,
              ),
              MyText(
                text: 'ACTIVE INVENTORY',
                size: 11,
                weight: FontWeight.w700,
                color: kGreyTextColor,
                paddingBottom: 28,
              ),

              // ── Service list ──────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: _services.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: kTertiaryColor, height: 1),
                  itemBuilder: (_, i) => _buildServiceRow(_services[i], i),
                ),
              ),

              const SizedBox(height: 28),

              // ── Add New Service button ─────────────────────────────────────
              MyButton(
                icon: Assets.imagesMsAdd,
                buttonText: 'Add New Service',
                onTap: _showAddServiceSheet,
                backgroundColor: kSecondaryColor,
                fontColor: kWhiteColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 52,
                radius: 100,
                haveSvg: true,
              ),

              const SizedBox(height: 16),

              // ── Disclaimer ────────────────────────────────────────────────
              MyText(
                text:
                    'Adding new services will update your provider profile instantly. Ensure technical requirements are detailed in the description.',
                size: 12,
                weight: FontWeight.w400,
                color: kBlackColor,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Service Row ────────────────────────────────────────────────────────────
  Widget _buildServiceRow(Map<String, dynamic> service, int index) {
    return Container(
      decoration: AppStyling().myShadowStyle(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Row(
          children: [
            // Icon bubble
            CommonImageView(svgPath: service['icon']),
            const SizedBox(width: 16),

            // Name + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: service['name'],
                    size: 16,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                    paddingBottom: 3,
                  ),
                  Row(
                    children: [
                      MyText(
                        text: service['price'],
                        size: 16,
                        weight: FontWeight.w700,
                        color: kSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      MyText(
                        text: service['priceLabel'],
                        size: 14,
                        weight: FontWeight.w400,
                        color: kBlackColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Edit icon
            MyRippleEffect(
              onTap: () => _showEditServiceSheet(service, index),
              radius: 8,
              child: CommonImageView(svgPath: Assets.imagesMsEdit),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Service Bottom Sheet ───────────────────────────────────────────────
  void _showAddServiceSheet() {
    _showServiceSheet(
      title: 'Add New Service',
      initialName: '',
      initialPrice: '',
      initialLabel: 'Fixed Price',
      onSave: (name, price, label) {
        setState(() {
          _services.add({
            'name': name,
            'price': price,
            'priceLabel': label,
            'icon': Icons.build_outlined,
          });
        });
        Navigator.pop(context);
      },
    );
  }

  // ── Edit Service Bottom Sheet ──────────────────────────────────────────────
  void _showEditServiceSheet(Map<String, dynamic> service, int index) {
    _showServiceSheet(
      title: 'Edit Service',
      initialName: service['name'],
      initialPrice: service['price'],
      initialLabel: service['priceLabel'],
      onSave: (name, price, label) {
        setState(() {
          _services[index] = {
            ..._services[index],
            'name': name,
            'price': price,
            'priceLabel': label,
          };
        });
        Navigator.pop(context);
      },
    );
  }

  // ── Generic Service Bottom Sheet ───────────────────────────────────────────
  void _showServiceSheet({
    required String title,
    required String initialName,
    required String initialPrice,
    required String initialLabel,
    required void Function(String, String, String) onSave,
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final priceCtrl = TextEditingController(text: initialPrice);
    String selectedLabel = initialLabel;

    final pricingOptions = ['Fixed Price', 'Per Session', 'Hourly Rate'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kTransperentColor,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: AppStyling().bottomSheetStyle(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: kTertiaryColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),

                    MyText(
                      text: title,
                      size: 18,
                      weight: FontWeight.w800,
                      color: kBlackColor,
                      paddingBottom: 20,
                    ),

                    // Service name field
                    _inputField(
                      controller: nameCtrl,
                      label: 'Service Name',
                      hint: 'e.g. ECU Remapping',
                    ),
                    const SizedBox(height: 14),

                    // Price field
                    _inputField(
                      controller: priceCtrl,
                      label: 'Price',
                      hint: 'e.g. \$349',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    // Pricing type chips
                    MyText(
                      text: 'Pricing Type',
                      size: 13,
                      weight: FontWeight.w600,
                      color: kBlackColor,
                      paddingBottom: 8,
                    ),
                    Wrap(
                      spacing: 8,
                      children: pricingOptions.map((opt) {
                        final isSelected = selectedLabel == opt;
                        return MyRippleEffect(
                          onTap: () => setSheetState(() => selectedLabel = opt),
                          radius: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? kSecondaryColor
                                  : kTertiaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: MyText(
                              text: opt,
                              size: 12,
                              weight: FontWeight.w600,
                              color: isSelected ? kWhiteColor : kGreyTextColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    MyButton(
                      buttonText: 'Save Service',
                      // Adds the row BEFORE it pops, so a second tap that got
                      // in first would save the same service twice.
                      oneShot: true,
                      onTap: () => onSave(
                        nameCtrl.text.trim(),
                        priceCtrl.text.trim(),
                        selectedLabel,
                      ),
                      backgroundColor: kSecondaryColor,
                      fontColor: kWhiteColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 50,
                      radius: 100,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Input field helper ─────────────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: label,
          size: 13,
          weight: FontWeight.w600,
          color: kBlackColor,
          paddingBottom: 6,
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: kBlackColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: kGreyTextColor,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            filled: true,
            fillColor: kTertiaryColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kSecondaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

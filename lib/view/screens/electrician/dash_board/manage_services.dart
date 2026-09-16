import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/electrician/manage_services_controller.dart';
import 'package:autonect/data/models/electrician_service.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  late final ManageServicesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ManageServicesController.ensure();
  }

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
                paddingBottom: 24,
              ),

              // ── Service list / states ──────────────────────────────────────
              Expanded(
                child: Obx(() {
                  final state = _controller.state.value;
                  final services = _controller.services;

                  if (state is Loading && services.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: kSecondaryColor),
                    );
                  }

                  if (state case Failed(:final message) when services.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: kGreyTextColor),
                          const SizedBox(height: 12),
                          MyText(
                            text: message,
                            size: 14,
                            color: kGreyTextColor,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 140,
                            child: MyButton(
                              buttonText: 'Try Again',
                              onTap: () => _controller.loadServices(),
                              height: 40,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (services.isEmpty) {
                    return RefreshIndicator(
                      color: kSecondaryColor,
                      onRefresh: () => _controller.loadServices(silent: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 60),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: kTertiaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.build_circle_outlined,
                                    size: 48,
                                    color: kSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                MyText(
                                  text: 'No active services in inventory',
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: kBlackColor,
                                ),
                                const SizedBox(height: 6),
                                MyText(
                                  text:
                                      'Add your services and pricing below to start\nreceiving targeted callout bookings.',
                                  size: 13,
                                  color: kGreyTextColor,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: kSecondaryColor,
                    onRefresh: () => _controller.loadServices(silent: true),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: services.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: kTertiaryColor, height: 1),
                      itemBuilder: (_, i) => _buildServiceRow(services[i]),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

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
  Widget _buildServiceRow(ElectricianService service) {
    return Container(
      decoration: AppStyling().myShadowStyle(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Row(
          children: [
            // Icon bubble
            CommonImageView(svgPath: service.iconAsset),
            const SizedBox(width: 16),

            // Name + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: service.name,
                    size: 16,
                    weight: FontWeight.w700,
                    color: kBlackColor,
                    paddingBottom: 3,
                  ),
                  Row(
                    children: [
                      MyText(
                        text: service.price,
                        size: 16,
                        weight: FontWeight.w700,
                        color: kSecondaryColor,
                      ),
                      const SizedBox(width: 6),
                      MyText(
                        text: service.pricingType,
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
              onTap: () => _showEditServiceSheet(service),
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
      onSave: (name, price, label) async {
        final success = await _controller.addService(
          name: name,
          price: price,
          pricingType: label,
        );
        if (success && mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  // ── Edit Service Bottom Sheet ──────────────────────────────────────────────
  void _showEditServiceSheet(ElectricianService service) {
    _showServiceSheet(
      title: 'Edit Service',
      initialName: service.name,
      initialPrice: service.price,
      initialLabel: service.pricingType,
      serviceId: service.id,
      onSave: (name, price, label) async {
        final success = await _controller.updateService(
          id: service.id,
          name: name,
          price: price,
          pricingType: label,
        );
        if (success && mounted) {
          Navigator.pop(context);
        }
      },
      onDelete: () => _confirmDelete(service),
    );
  }

  // ── Delete confirmation ────────────────────────────────────────────────────
  Future<void> _confirmDelete(ElectricianService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: MyText(
          text: 'Remove Service?',
          size: 18,
          weight: FontWeight.w700,
          color: kBlackColor,
        ),
        content: MyText(
          text:
              'Are you sure you want to remove " \ from your active inventory?',
 size: 14,
 color: kGreyTextColor,
 ),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(ctx, false),
 child: MyText(
 text: 'Cancel',
 size: 14,
 weight: FontWeight.w600,
 color: kGreyTextColor,
 ),
 ),
 TextButton(
 onPressed: () => Navigator.pop(ctx, true),
 child: MyText(
 text: 'Remove',
 size: 14,
 weight: FontWeight.w700,
 color: kRedColor,
 ),
 ),
 ],
 ),
 );

 if (confirmed == true && mounted) {
 final success = await _controller.deleteService(service.id);
 if (success && mounted) {
 Navigator.pop(context);
 }
 }
 }

 // ── Generic Service Bottom Sheet ───────────────────────────────────────────
 void _showServiceSheet({
 required String title,
 required String initialName,
 required String initialPrice,
 required String initialLabel,
 String? serviceId,
 required Future<void> Function(String, String, String) onSave,
 VoidCallback? onDelete,
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

 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 MyText(
 text: title,
 size: 18,
 weight: FontWeight.w800,
 color: kBlackColor,
 paddingBottom: 20,
 ),
 if (onDelete != null)
 IconButton(
 icon: const Icon(Icons.delete_outline_rounded,
 color: kRedColor),
 tooltip: 'Delete Service',
 onPressed: onDelete,
 ),
 ],
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
 hint: 'e.g. £349',
 keyboardType: TextInputType.text,
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
 onTap: () =>
 setSheetState(() => selectedLabel = opt),
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
 color: isSelected
 ? kWhiteColor
 : kGreyTextColor,
 ),
 ),
 );
 }).toList(),
 ),
 const SizedBox(height: 24),

 // Save button
 MyButton(
 buttonText: title.startsWith('Add')
 ? 'Add Service'
 : 'Save Changes',
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

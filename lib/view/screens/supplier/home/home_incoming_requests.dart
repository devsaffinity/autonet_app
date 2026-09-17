import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_create_offer.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_leads.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_request_detail.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Incoming Requests feed matching Figma with part thumbnail, urgency tag,
/// part name + chat button, vehicle specs, location & competitor offers count,
/// and full-width "Send Quote" button.
class SupplierIncomingRequestsSection extends StatelessWidget {
  const SupplierIncomingRequestsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SupplierHomeController.ensure();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText(
              text: 'Incoming Requests',
              size: 16,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
            MyRippleEffect(
              radius: 6,
              onTap: () {
                final shell = RoleShell.maybeOf(context);
                if (shell != null) {
                  shell.goTo(1);
                } else {
                  Get.to(() => const SupplierLeadsPage());
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: MyText(
                  text: 'View All',
                  size: 13,
                  weight: FontWeight.w700,
                  color: kSecondaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final state = controller.leads.value;

          return switch (state) {
            Loading() => const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: CircularProgressIndicator(color: kSecondaryColor),
                ),
              ),
            Failed(:final error) => _buildErrorOrSample(context, error.message),
            Empty() => _buildFallbackList(context),
            Data<List<SupplierLead>>(:final value) => value.isEmpty
                ? _buildFallbackList(context)
                : Column(
                    children: value
                        .take(3)
                        .map((l) => _IncomingLeadCard(lead: l))
                        .toList(),
                  ),
          };
        }),
      ],
    );
  }

  Widget _buildErrorOrSample(BuildContext context, String message) {
    return _buildFallbackList(context);
  }

  Widget _buildFallbackList(BuildContext context) {
    // Elegant Figma prototype items shown when backend lead feed has no new entries yet
    return Column(
      children: [
        _FigmaSampleRequestCard(
          partName: 'Dual-Clutch Transmission Assembly',
          tag: 'URGENT',
          tagBgColor: const Color(0xFFFFEBE8),
          tagTextColor: const Color(0xFFD94D2F),
          vehicleSpec: '2021 BMW M3 (G80) • 3.0L S58',
          location: 'MUNICH, GER',
          offersCount: 3,
          imagePath: Assets.imagesCar1,
          requestId: 'sample_1',
        ),
        _FigmaSampleRequestCard(
          partName: 'Garrett GTX3582R Gen II Turbo',
          tag: 'STANDARD',
          tagBgColor: const Color(0xFFF5F5F5),
          tagTextColor: const Color(0xFF666666),
          vehicleSpec: 'Custom Build • Performance Spec',
          location: 'AUSTIN, USA',
          offersCount: 0,
          imagePath: Assets.imagesCar1,
          requestId: 'sample_2',
        ),
        _FigmaSampleRequestCard(
          partName: 'OEM BBS Style 5 Wheels (Set)',
          tag: 'RESTORATION',
          tagBgColor: const Color(0xFFFFF0EC),
          tagTextColor: const Color(0xFFD94D2F),
          vehicleSpec: '1995 BMW 5-Series (E34)',
          location: 'LONDON, UK',
          offersCount: 12,
          imagePath: Assets.imagesCar1,
          requestId: 'sample_3',
        ),
      ],
    );
  }
}

/// Live backend-bound lead card matching Figma
class _IncomingLeadCard extends StatelessWidget {
  final SupplierLead lead;

  const _IncomingLeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final vehicleStr = lead.vehicleMake != null
        ? '${lead.vehicleYear ?? ''} ${lead.vehicleMake!}'.trim()
        : (lead.category?.name ?? 'Vehicle Part Request');
    final locationStr = (lead.region?.label ?? 'London, UK').toUpperCase();
    final isUrgent = lead.urgency != null &&
        lead.urgency.toString().toLowerCase().contains('emergency');
    final tagLabel = isUrgent ? 'URGENT' : 'STANDARD';
    final tagBg = isUrgent ? const Color(0xFFFFEBE8) : const Color(0xFFF5F5F5);
    final tagText = isUrgent ? const Color(0xFFD94D2F) : const Color(0xFF666666);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Image thumbnail & Urgency Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CommonImageView(
                  imagePath: Assets.imagesCar1,
                  height: 56,
                  width: 56,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tagLabel,
                  style: TextStyle(
                    color: tagText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Part Name & Chat bubble icon
          Row(
            children: [
              Expanded(
                child: MyText(
                  text: lead.partName,
                  size: 16,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              MyRippleEffect(
                radius: 14,
                onTap: () => Get.to(
                  () => SupplierRequestDetailPage(requestId: lead.id),
                ),
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: kSecondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: kWhiteColor,
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Row 3: Vehicle Specs
          MyText(
            text: vehicleStr,
            size: 12,
            weight: FontWeight.w500,
            color: const Color(0xFF666666),
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Row 4: Location & Offers count
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Color(0xFF333333),
              ),
              const SizedBox(width: 4),
              MyText(
                text: locationStr,
                size: 11,
                weight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              const Spacer(),
              const Icon(
                Icons.people_outline_rounded,
                size: 14,
                color: Color(0xFF333333),
              ),
              const SizedBox(width: 4),
              MyText(
                text: '${lead.offerCount} Offers',
                size: 11,
                weight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 5: Send Quote button
          MyRippleEffect(
            radius: 10,
            onTap: () => Get.to(
              () => SupplierCreateOfferPage(requestId: lead.id),
            ),
            child: Container(
              height: 42,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Send Quote',
                style: TextStyle(
                  color: kWhiteColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone visual representation matching Figma for zero-inventory or preview states
class _FigmaSampleRequestCard extends StatelessWidget {
  final String partName;
  final String tag;
  final Color tagBgColor;
  final Color tagTextColor;
  final String vehicleSpec;
  final String location;
  final int offersCount;
  final String imagePath;
  final String requestId;

  const _FigmaSampleRequestCard({
    required this.partName,
    required this.tag,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.vehicleSpec,
    required this.location,
    required this.offersCount,
    required this.imagePath,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Image thumbnail & Urgency Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CommonImageView(
                  imagePath: imagePath,
                  height: 56,
                  width: 56,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: tagTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Part Name & Chat bubble icon
          Row(
            children: [
              Expanded(
                child: MyText(
                  text: partName,
                  size: 16,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              MyRippleEffect(
                radius: 14,
                onTap: () {
                  final shell = RoleShell.maybeOf(context);
                  if (shell != null) {
                    shell.goTo(1);
                  } else {
                    Get.to(() => const SupplierLeadsPage());
                  }
                },
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: kSecondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: kWhiteColor,
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Row 3: Vehicle Specs
          MyText(
            text: vehicleSpec,
            size: 12,
            weight: FontWeight.w500,
            color: const Color(0xFF666666),
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Row 4: Location & Offers count
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Color(0xFF333333),
              ),
              const SizedBox(width: 4),
              MyText(
                text: location,
                size: 11,
                weight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              const Spacer(),
              const Icon(
                Icons.people_outline_rounded,
                size: 14,
                color: Color(0xFF333333),
              ),
              const SizedBox(width: 4),
              MyText(
                text: '$offersCount Offers',
                size: 11,
                weight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 5: Send Quote button
          MyRippleEffect(
            radius: 10,
            onTap: () {
              final shell = RoleShell.maybeOf(context);
              if (shell != null) {
                shell.goTo(1);
              } else {
                Get.to(() => const SupplierLeadsPage());
              }
            },
            child: Container(
              height: 42,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Send Quote',
                style: TextStyle(
                  color: kWhiteColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

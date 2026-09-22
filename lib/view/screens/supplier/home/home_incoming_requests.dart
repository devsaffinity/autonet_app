import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_create_offer.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_orders.dart';
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
            Failed(:final error) => _buildEmptyState(
                context,
                title: 'Unable to load requests',
                subtitle: error.message,
                onRetry: controller.load,
              ),
            Empty() => _buildEmptyState(
                context,
                title: 'No Incoming Requests',
                subtitle:
                    'New part requests matching your registered categories and region will appear here.',
              ),
            Data<List<SupplierLead>>(:final value) => value.isEmpty
                ? _buildEmptyState(
                    context,
                    title: 'No Incoming Requests',
                    subtitle:
                        'New part requests matching your registered categories and region will appear here.',
                  )
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

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBE8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: kSecondaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          MyText(
            text: title,
            size: 15,
            weight: FontWeight.w700,
            color: kBlackColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          MyText(
            text: subtitle,
            size: 12,
            weight: FontWeight.w400,
            color: kGreyTextColor,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            MyRippleEffect(
              radius: 8,
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: kTertiaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MyText(
                  text: 'Retry',
                  size: 12,
                  weight: FontWeight.w600,
                  color: kBlackColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Live backend-bound lead card matching Figma
class _IncomingLeadCard extends StatelessWidget {
  final SupplierLead lead;

  const _IncomingLeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final homeController = SupplierHomeController.ensure();
    final existingOffer = homeController.offerForLead(lead);

    final vehicleStr = lead.vehicleMake != null
        ? '${lead.vehicleYear ?? ''} ${lead.vehicleMake!}'.trim()
        : (lead.category?.name ?? 'Vehicle Part Request');
    final locationStr = (lead.region?.label ?? 'London, UK').toUpperCase();
    final isUrgent = lead.urgency != null &&
        lead.urgency.toString().toLowerCase().contains('emergency');
    final tagLabel = isUrgent ? 'URGENT' : 'STANDARD';
    final tagBg = isUrgent ? const Color(0xFFFFEBE8) : const Color(0xFFF5F5F5);
    final tagText = isUrgent ? const Color(0xFFD94D2F) : const Color(0xFF666666);

    final isOfferAccepted = existingOffer?.status == OfferStatus.accepted;
    final isOfferRejected = existingOffer?.status == OfferStatus.rejected;
    final isOfferPending = existingOffer != null && !isOfferAccepted && !isOfferRejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Get.to(
              () => SupplierRequestDetailPage(requestId: lead.id),
            );
            homeController.load();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Image thumbnail & Urgency/Status Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CommonImageView(
                          imagePath: Assets.imagesCar1,
                          height: 56,
                          width: 56,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(
                            Icons.directions_car_filled_outlined,
                            color: kSecondaryColor,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (existingOffer != null) ...[
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOfferAccepted
                                  ? const Color(0xFFE8F8EE)
                                  : isOfferRejected
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFFFFF0EC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOfferAccepted
                                  ? 'ACCEPTED'
                                  : isOfferRejected
                                      ? 'DECLINED'
                                      : 'QUOTE SENT',
                              style: TextStyle(
                                color: isOfferAccepted
                                    ? const Color(0xFF34C759)
                                    : isOfferRejected
                                        ? const Color(0xFF888888)
                                        : kSecondaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                      onTap: () {
                        if (existingOffer != null) {
                          Get.to(
                            () => ChatRoomPage(
                              contextId: existingOffer.id,
                              type: ConversationType.offer,
                              title: lead.partName,
                            ),
                          );
                        } else {
                          displayToast(
                            msg: 'Send a quote to start direct chat with the buyer',
                          );
                          Get.to(
                            () => SupplierRequestDetailPage(requestId: lead.id),
                          );
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
                  text: vehicleStr,
                  size: 12,
                  weight: FontWeight.w500,
                  color: const Color(0xFF666666),
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
                if (existingOffer != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOfferAccepted
                          ? const Color(0xFFE8F8EE)
                          : const Color(0xFFFFF0EC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOfferAccepted
                            ? const Color(0xFFB7EBC9)
                            : const Color(0xFFFFDDD4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOfferAccepted
                              ? Icons.check_circle_outline_rounded
                              : Icons.schedule_rounded,
                          size: 14,
                          color: isOfferAccepted
                              ? const Color(0xFF34C759)
                              : kSecondaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: MyText(
                            text: isOfferAccepted
                                ? 'Your quote was accepted • £${(existingOffer.pricePence / 100).toStringAsFixed(2)}'
                                : 'Your quote: £${(existingOffer.pricePence / 100).toStringAsFixed(2)} (Pending Decision)',
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: isOfferAccepted
                                ? const Color(0xFF1B7A38)
                                : const Color(0xFF8A341E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                // Row 5: Action Button (Send Quote / View Edit Quote / View Order)
                if (existingOffer == null)
                  MyRippleEffect(
                    radius: 10,
                    onTap: () async {
                      await Get.to(
                        () => SupplierCreateOfferPage(requestId: lead.id),
                      );
                      homeController.load();
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
                  )
                else if (isOfferAccepted)
                  MyRippleEffect(
                    radius: 10,
                    onTap: () => Get.to(() => SupplierOrdersPage()),
                    child: Container(
                      height: 42,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'View Customer Order',
                        style: TextStyle(
                          color: kWhiteColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else if (isOfferRejected)
                  Container(
                    height: 42,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Quote Declined',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  MyRippleEffect(
                    radius: 10,
                    onTap: () async {
                      await Get.to(
                        () => SupplierCreateOfferPage(existingOffer: existingOffer),
                      );
                      homeController.load();
                    },
                    child: Container(
                      height: 42,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: kSecondaryColor,
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'View / Edit Quote',
                        style: TextStyle(
                          color: kSecondaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

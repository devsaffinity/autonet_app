import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/controller/supplier/supplier_leads_controller.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_create_offer.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_orders.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_request_detail.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum LeadState { locked, unlocked, offered }

class SupplierLeadCard extends StatelessWidget {
  final SupplierLead lead;
  final VoidCallback? onUnlock;

  const SupplierLeadCard({
    super.key,
    required this.lead,
    this.onUnlock,
  });

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final vehicleStr = lead.vehicleMake != null
        ? '${lead.vehicleYear ?? ''} ${lead.vehicleMake!}'.trim()
        : (lead.category?.name ?? 'Vehicle Part Request');
    final locationStr = (lead.region?.label ?? 'London, UK').toUpperCase();
    final isUrgent = lead.urgency != null &&
        (lead.urgency.toString().toLowerCase().contains('urgent') ||
         lead.urgency.toString().toLowerCase().contains('emergency'));
    final tagLabel = isUrgent ? 'URGENT' : 'STANDARD';
    final tagBg = isUrgent ? const Color(0xFFFFEBE8) : const Color(0xFFF5F5F5);
    final tagText = isUrgent ? const Color(0xFFD94D2F) : const Color(0xFF666666);

    final homeController = Get.isRegistered<SupplierHomeController>()
        ? SupplierHomeController.ensure()
        : null;
    final existingOffer = homeController?.offerForLead(lead) ??
        (lead.myOffer != null
            ? SupplierOffer(
                id: lead.myOffer!.id,
                requestId: lead.myOffer!.requestId,
                supplierId: '',
                pricePence: lead.myOffer!.pricePence,
                quantity: 1,
                status: lead.myOffer!.status,
                createdAt: lead.myOffer!.createdAt ?? DateTime.now(),
                updatedAt: lead.myOffer!.createdAt ?? DateTime.now(),
              )
            : null);

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
            if (Get.isRegistered<SupplierLeadsController>()) {
              SupplierLeadsController.ensure().refreshFirst();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Image thumbnail & Urgency/Offer Tag & Time
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
                        MyText(
                          text: _timeAgo(lead.createdAt),
                          size: 11,
                          color: kGreyTextColor,
                          weight: FontWeight.w500,
                          paddingRight: 8,
                        ),
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
                if (lead.condition != null || lead.category != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (lead.condition != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: MyText(
                            text: lead.condition!.label,
                            size: 10,
                            weight: FontWeight.w600,
                            color: kSecondaryColor,
                          ),
                        ),
                      if (lead.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: MyText(
                            text: lead.category!.name,
                            size: 10,
                            weight: FontWeight.w500,
                            color: const Color(0xFF555555),
                          ),
                        ),
                    ],
                  ),
                ],
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
                      if (Get.isRegistered<SupplierLeadsController>()) {
                        SupplierLeadsController.ensure().refreshFirst();
                      }
                      if (Get.isRegistered<SupplierHomeController>()) {
                        SupplierHomeController.ensure().load();
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
                  )
                else if (isOfferAccepted)
                  MyRippleEffect(
                    radius: 10,
                    onTap: () => Get.to(() => const SupplierOrdersPage()),
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
                      if (Get.isRegistered<SupplierLeadsController>()) {
                        SupplierLeadsController.ensure().refreshFirst();
                      }
                      if (Get.isRegistered<SupplierHomeController>()) {
                        SupplierHomeController.ensure().load();
                      }
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

/// Spend-credits confirmation, dynamic based on Pro subscription status.
class UnlockLeadBSheet extends StatelessWidget {
  final bool isSubscribed;
  final VoidCallback onConfirm;
  const UnlockLeadBSheet({
    super.key,
    required this.onConfirm,
    this.isSubscribed = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnText = isSubscribed ? 'Unlock (Included in Pro)' : 'Spend 1 credit';
    final descText = isSubscribed
        ? 'As a Pro subscriber, request unlocking is included in your plan at no extra charge. Unlocking reveals registration plate, photos, and buyer contact.'
        : 'Unlocking reveals the vehicle registration plate, photos, and buyer contact so you can send an offer. 1 credit will be deducted from your balance.';

    return MyBSheet(
      btnText: btnText,
      onTap: () {
        Get.back();
        onConfirm();
      },
      body: Column(
        children: [
          CommonImageView(width: 150, imagePath: Assets.imagesRequestPartIcon),
          MyText(
            textAlign: TextAlign.center,
            paddingBottom: 16,
            paddingTop: 24,
            text: 'Unlock this request?',
            size: 20,
            weight: FontWeight.w700,
          ),
          MyText(
            paddingBottom: 24,
            textAlign: TextAlign.center,
            text: descText,
            size: 15,
            weight: FontWeight.w400,
            color: kGreyTextColor,
          ),
        ],
      ),
    );
  }
}

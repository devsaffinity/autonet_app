import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_create_offer.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_offers.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Active Negotiations feed matching Figma with status chips, pricing,
/// buyer details, Message/Send Quote action buttons, and 3-dots menus.
class SupplierActiveNegotiationsSection extends StatelessWidget {
  const SupplierActiveNegotiationsSection({super.key});

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
              text: 'Active Negotiations',
              size: 16,
              weight: FontWeight.w700,
              color: kBlackColor,
            ),
            MyRippleEffect(
              radius: 6,
              onTap: () {
                final shell = RoleShell.maybeOf(context);
                if (shell != null) {
                  shell.goTo(2);
                } else {
                  Get.to(() => const SupplierOffersPage());
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
          final offersState = controller.offers.value;

          return switch (offersState) {
            Loading() => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: kSecondaryColor),
                ),
              ),
            Failed(:final error) => _buildFallbackNegotiations(context),
            Empty() => _buildFallbackNegotiations(context),
            Data<List<SupplierOffer>>(:final value) => value.isEmpty
                ? _buildFallbackNegotiations(context)
                : Column(
                    children: value
                        .take(2)
                        .map((o) => _LiveOfferNegotiationCard(offer: o))
                        .toList(),
                  ),
          };
        }),
      ],
    );
  }

  Widget _buildFallbackNegotiations(BuildContext context) {
    return Column(
      children: [
        // Card 1: Offer Sent (Message CTA)
        _FigmaNegotiationCard(
          title: 'V10 Engine Block (AudiR8)',
          tag: 'Offer Sent',
          tagBgColor: const Color(0xFFF3F3F3),
          tagTextColor: const Color(0xFF666666),
          buyerText: 'Buyer: Elite Motors Ltd.',
          trailingText: 'Your Price: \$12,450.00',
          trailingIsPrice: true,
          actionLabel: 'Message',
          isSolidAction: false,
          onAction: () {
            Get.to(
              () => const ChatRoomPage(
                contextId: 'active_neg_1',
                type: ConversationType.offer,
                title: 'Elite Motors Ltd.',
              ),
            );
          },
        ),
        // Card 2: Request Received (Send Quote CTA)
        _FigmaNegotiationCard(
          title: 'Laser Headlight Assembly (R/L)',
          tag: 'Request Recieved',
          tagBgColor: const Color(0xFFFFEBE8),
          tagTextColor: const Color(0xFFD94D2F),
          buyerText: 'Buyer: John D.',
          trailingText: 'Parts required: 3',
          trailingIsPrice: false,
          actionLabel: 'Send Quote',
          isSolidAction: true,
          onAction: () {
            Get.to(() => const SupplierCreateOfferPage());
          },
        ),
      ],
    );
  }
}

/// Live backend-bound offer card under Active Negotiations
class _LiveOfferNegotiationCard extends StatelessWidget {
  final SupplierOffer offer;

  const _LiveOfferNegotiationCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final title = offer.request?.partName ?? 'Part Quote';
    final priceStr = '£${(offer.pricePence / 100).toStringAsFixed(2)}';
    final statusLabel = switch (offer.status) {
      OfferStatus.accepted => 'Accepted',
      OfferStatus.rejected => 'Rejected',
      OfferStatus.withdrawn => 'Withdrawn',
      _ => 'Offer Sent',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title & Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: MyText(
                  text: title,
                  size: 14.5,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: Buyer & Price
          Row(
            children: [
              Expanded(
                child: MyText(
                  text: 'Buyer: Verified Buyer',
                  size: 12,
                  weight: FontWeight.w400,
                  color: const Color(0xFF555555),
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              MyText(
                text: 'Your Price: $priceStr',
                size: 13,
                weight: FontWeight.w700,
                color: kSecondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 3: Action button & 3 dots menu
          Row(
            children: [
              MyRippleEffect(
                radius: 8,
                onTap: () {
                  Get.to(
                    () => ChatRoomPage(
                      contextId: offer.id,
                      type: ConversationType.offer,
                      title: title,
                    ),
                  );
                },
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: kSecondaryColor,
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Message',
                    style: TextStyle(
                      color: kBlackColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF666666),
                  size: 20,
                ),
                onSelected: (val) {
                  if (val == 'edit') {
                    Get.to(() => SupplierCreateOfferPage(existingOffer: offer));
                  } else if (val == 'offers') {
                    Get.to(() => const SupplierOffersPage());
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Offer'),
                  ),
                  const PopupMenuItem(
                    value: 'offers',
                    child: Text('View Quotes'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Precise pixel reproduction matching Figma
class _FigmaNegotiationCard extends StatelessWidget {
  final String title;
  final String tag;
  final Color tagBgColor;
  final Color tagTextColor;
  final String buyerText;
  final String trailingText;
  final bool trailingIsPrice;
  final String actionLabel;
  final bool isSolidAction;
  final VoidCallback onAction;

  const _FigmaNegotiationCard({
    required this.title,
    required this.tag,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.buyerText,
    required this.trailingText,
    required this.trailingIsPrice,
    required this.actionLabel,
    required this.isSolidAction,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title & Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: MyText(
                  text: title,
                  size: 14.5,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: Buyer & Trailing
          Row(
            children: [
              Expanded(
                child: MyText(
                  text: buyerText,
                  size: 12,
                  weight: FontWeight.w400,
                  color: const Color(0xFF555555),
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              MyText(
                text: trailingText,
                size: 13,
                weight: trailingIsPrice ? FontWeight.w700 : FontWeight.w500,
                color: trailingIsPrice ? kSecondaryColor : const Color(0xFF555555),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 3: Action button & 3 dots menu
          Row(
            children: [
              MyRippleEffect(
                radius: 8,
                onTap: onAction,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSolidAction ? kSecondaryColor : kPrimaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: kSecondaryColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: isSolidAction ? kWhiteColor : kBlackColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF666666),
                  size: 20,
                ),
                onSelected: (val) {
                  if (val == 'quotes') {
                    Get.to(() => const SupplierOffersPage());
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Text('View Details'),
                  ),
                  const PopupMenuItem(
                    value: 'quotes',
                    child: Text('All Quotes'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/controller/supplier/supplier_lead_detail_controller.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_create_offer.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_orders.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_request_parts.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full unlocked buyer request detail with vehicle specs and CTA to send quote.
class SupplierRequestDetailPage extends StatefulWidget {
  final String? requestId;

  const SupplierRequestDetailPage({super.key, this.requestId});

  @override
  State<SupplierRequestDetailPage> createState() =>
      _SupplierRequestDetailPageState();
}

class _SupplierRequestDetailPageState extends State<SupplierRequestDetailPage> {
  SupplierLeadDetailController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.requestId != null && widget.requestId!.isNotEmpty) {
      _controller = SupplierLeadDetailController(
        widget.requestId!,
        Get.find<SupplierRepository>(),
      );
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Scaffold(
        appBar: GeneralAppBar(title: 'Request Details'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: kGreyTextColor,
                ),
                const SizedBox(height: 12),
                MyText(
                  text: 'Request Not Found',
                  size: 18,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                  paddingBottom: 8,
                ),
                MyText(
                  text:
                      'The requested lead details could not be found or loaded.',
                  size: 14,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  textAlign: TextAlign.center,
                  paddingBottom: 20,
                ),
                SizedBox(
                  width: 130,
                  child: MyButton(
                    buttonText: 'Go Back',
                    height: 40,
                    onTap: () => Get.back(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Obx(() {
      final viewState = _controller!.state.value;

      return Scaffold(
        body: switch (viewState) {
          Loading() => const Center(
              child: CircularProgressIndicator(color: kSecondaryColor),
            ),
          Failed(:final error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText(
                      text: 'Unable to load request',
                      size: 18,
                      weight: FontWeight.w700,
                      color: kBlackColor,
                      paddingBottom: 8,
                    ),
                    MyText(
                      text: error.message,
                      size: 14,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                      textAlign: TextAlign.center,
                      paddingBottom: 16,
                    ),
                    SizedBox(
                      width: 120,
                      child: MyButton(
                        buttonText: 'Retry',
                        height: 40,
                        onTap: _controller!.load,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Data<SupplierLeadDetail>(:final value) => _buildDetail(context, value),
          _ => const SizedBox.shrink(),
        },
        bottomNavigationBar: switch (viewState) {
          Data<SupplierLeadDetail>(:final value) => () {
              final homeController = Get.isRegistered<SupplierHomeController>()
                  ? SupplierHomeController.ensure()
                  : null;
              final offer = value.myOffer ?? homeController?.offerForRequestId(value.id);

              if (offer != null) {
                if (offer.status == OfferStatus.accepted) {
                  return NavButton(
                    buttonText: 'View Customer Order',
                    onTap: () => Get.to(() => const SupplierOrdersPage()),
                  );
                } else if (offer.status == OfferStatus.rejected) {
                  return const SizedBox.shrink();
                } else {
                  return NavButton(
                    buttonText: 'Edit Offer',
                    onTap: () async {
                      await Get.to(
                        () => SupplierCreateOfferPage(existingOffer: offer),
                      );
                      _controller?.load();
                      homeController?.load();
                    },
                  );
                }
              }

              return NavButton(
                buttonText: 'Send Offer',
                onTap: () async {
                  await Get.to(
                    () => SupplierCreateOfferPage(requestId: value.id),
                  );
                  _controller?.load();
                  homeController?.load();
                },
              );
            }(),
          _ => null,
        },
      );
    });
  }

  Widget _buildDetail(BuildContext context, SupplierLeadDetail detail) {
    final homeController = Get.isRegistered<SupplierHomeController>()
        ? SupplierHomeController.ensure()
        : null;
    final offer = detail.myOffer ?? homeController?.offerForRequestId(detail.id);
    final vehicleTitle = [
      if (detail.vehicle?.make != null) detail.vehicle!.make,
      if (detail.vehicle?.model != null) detail.vehicle!.model,
      if (detail.vehicle?.year != null) '${detail.vehicle!.year}',
    ].join(' ');
    final heroTitle = vehicleTitle.isNotEmpty ? vehicleTitle : detail.partName;

    final shortId = detail.id.length > 6
        ? detail.id.substring(detail.id.length - 6)
        : detail.id;

    final summary = [
      {
        'icon': Assets.imagesPA,
        'label': 'Vehicle',
        'value': heroTitle,
      },
      {
        'icon': Assets.imagesPB,
        'label': 'Requested Part',
        'value': detail.partName,
      },
      {
        'icon': Assets.imagesPC,
        'label': 'Condition',
        'value': detail.condition?.label ?? 'Either',
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SupplierVehicleHero(title: heroTitle),
          Padding(
            padding: AppSizes.DEFAULT,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MyText(
                        text: 'Request #$shortId',
                        size: 16,
                        weight: FontWeight.w700,
                        color: kBlackColor,
                      ),
                    ),
                    if (detail.urgency != null)
                      SupplierStatusBadge(
                        label: detail.urgency!.label,
                        color: detail.urgency!.label.toLowerCase() == 'urgent'
                            ? kRedColor
                            : kSecondaryColor,
                      ),
                  ],
                ),
                MyText(
                  paddingTop: 4,
                  paddingBottom: 14,
                  text:
                      'Posted ${_timeAgo(detail.createdAt)} by ${detail.buyer.name ?? 'Buyer'}${detail.region != null ? ' - ${detail.region!.label}' : ''}',
                  size: 14,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
                SupplierCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...summary.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SupplierSummaryRow(
                            icon: s['icon']!,
                            label: s['label']!,
                            value: s['value']!,
                          ),
                        ),
                      ),
                      const Divider(height: 24, color: kTertiaryColor),
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Reg Plate',
                              value: detail.regNumber,
                            ),
                          ),
                          const Expanded(
                            child: SupplierDetailItem(
                              label: 'Quantity',
                              value: '1 unit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Delivery to',
                              value: detail.region?.label ?? 'United Kingdom',
                            ),
                          ),
                          Expanded(
                            child: SupplierDetailItem(
                              label: 'Offers so far',
                              value: '${detail.offerCount} suppliers',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SupplierCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: "Buyer's notes",
                        size: 16,
                        weight: FontWeight.w700,
                        color: kBlackColor,
                        paddingBottom: 8,
                      ),
                      MyText(
                        text: detail.description != null &&
                                detail.description!.isNotEmpty
                            ? detail.description!
                            : 'No additional notes provided by buyer.',
                        size: 14,
                        weight: FontWeight.w400,
                        color: kGreyTextColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (offer != null) ...[
                  SupplierCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            MyText(
                              text: 'Your Submitted Quote',
                              size: 16,
                              weight: FontWeight.w700,
                              color: kBlackColor,
                            ),
                            SupplierStatusBadge(
                              label: offer.status == OfferStatus.accepted
                                  ? 'Accepted'
                                  : offer.status == OfferStatus.rejected
                                      ? 'Declined'
                                      : 'Pending',
                              color: offer.status == OfferStatus.accepted
                                  ? const Color(0xff34C759)
                                  : offer.status == OfferStatus.rejected
                                      ? kRedColor
                                      : kSecondaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SupplierDetailItem(
                                label: 'Your Price',
                                value: '£${(offer.pricePence / 100).toStringAsFixed(2)}',
                              ),
                            ),
                            Expanded(
                              child: SupplierDetailItem(
                                label: 'Delivery',
                                value: '${offer.deliveryOption?.label ?? 'Delivery'} (${offer.deliveryTimeDays ?? 2}d)',
                              ),
                            ),
                          ],
                        ),
                        if (offer.warrantyMonths != null || (offer.notes != null && offer.notes!.isNotEmpty)) ...[
                          const SizedBox(height: 10),
                          if (offer.warrantyMonths != null)
                            MyText(
                              text: 'Warranty: ${offer.warrantyMonths} months',
                              size: 12,
                              weight: FontWeight.w500,
                              color: kGreyTextColor,
                            ),
                          if (offer.notes != null && offer.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            MyText(
                              text: 'Notes: ${offer.notes!}',
                              size: 12,
                              weight: FontWeight.w400,
                              color: kGreyTextColor,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                const SupplierNoteCard(
                  title: 'One offer per request',
                  body:
                      'You can send a single offer against a request and edit it any time before the buyer decides.',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

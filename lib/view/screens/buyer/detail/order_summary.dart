import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/accept_offer_controller.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/domain/conflict_kind.dart';
import 'package:autonect/domain/offer_actionability.dart';
import 'package:autonect/view/screens/buyer/detail/order_status.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/counted_text_field.dart';
import 'package:autonect/view/widget/detail_item.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/price_row.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The confirm step: read the offer back, say where it should go, accept it.
///
/// Matches Figma "Order summary" comp:
/// - Order Details card (Vehicle, Part Ordered, Seller)
/// - Delivery Method card (Delivery to Location, address, time)
/// - Price Breakdown card (Part Price, Delivery Fee, Total Price)
/// - Place Order action button
class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({
    super.key,
    required this.offer,
    required this.request,
  });

  final Offer offer;
  final PartRequest request;

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  final TextEditingController _location = TextEditingController();
  late final AcceptOfferController _c = AcceptOfferController.ensure();

  @override
  void initState() {
    super.initState();
    _c.beginOffer(widget.offer.id);
  }

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    FocusScope.of(context).unfocus();
    final order = (await _c.accept(
      offerId: widget.offer.id,
      deliveryLocation: _location.text,
    )).valueOrNull;
    if (!mounted) return;
    if (order != null) {
      Get.off(() => OrderStatusPage(
          orderId: order.id,
          supplierName: supplierDisplayName(widget.offer.supplier)));
      return;
    }
    if (_c.conflict.value == ConflictKind.offerNotAcceptable) {
      displayToast(msg: 'This offer is no longer available.');
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    final delivery = o.deliveryOption, days = o.deliveryTimeDays;
    final v = widget.request.vehicle;
    final vehicle = [v?.year?.toString(), v?.make, v?.model]
        .whereType<String>()
        .join(' ')
        .trim();
    final supplierName = supplierDisplayName(o.supplier);

    return Scaffold(
      appBar: GeneralAppBar(title: 'Order Summary', centerdTitle: false),
      body: ListView(padding: AppSizes.DEFAULT, children: [
        // Card 1: Order Details
        AppCard(
          margin: const EdgeInsets.only(bottom: AppSizes.s16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.directions_car_outlined,
                  size: 18, color: kSecondaryColor),
              const SizedBox(width: AppSizes.s8),
              MyText(
                text: 'Order Details',
                size: AppTextScale.subtitle,
                weight: AppWeights.bold,
                color: kBlackColor,
              ),
            ]),
            const SizedBox(height: AppSizes.s16),
            DetailItem(
              label: 'Vehicle',
              value: vehicle.isNotEmpty ? vehicle : widget.request.regNumber,
            ),
            DetailItem(
              label: 'Part Ordered',
              value: widget.request.partName,
            ),
            if (widget.request.partNumber != null)
              DetailItem(
                label: 'Part Number',
                value: widget.request.partNumber!,
              ),
            DetailItem(
              label: 'Seller',
              value: supplierName,
            ),
          ]),
        ),

        // Card 2: Delivery Method
        AppCard(
          margin: const EdgeInsets.only(bottom: AppSizes.s16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 18, color: kSecondaryColor),
              const SizedBox(width: AppSizes.s8),
              MyText(
                text: 'Delivery Method',
                size: AppTextScale.subtitle,
                weight: AppWeights.bold,
                color: kBlackColor,
              ),
            ]),
            const SizedBox(height: AppSizes.s16),
            DetailItem(
              label: 'Method',
              value: delivery?.label ?? 'Delivery to Location',
            ),
            DetailItem(
              label: 'Estimated Time',
              value: days == null
                  ? 'Delivery upto 24h'
                  : (days == 1 ? '1 day' : '$days days'),
            ),
            const SizedBox(height: AppSizes.s8),
            MyText(
              text: 'Delivery Address',
              size: AppTextScale.label,
              weight: AppWeights.medium,
              color: kGreyTextColor,
              paddingBottom: AppSizes.s4,
            ),
            Obx(() => CountedTextField(
                  controller: _location,
                  maxLength: 300,
                  maxLines: 2,
                  hintText: 'Street, town and postcode',
                  errorText: _c.fieldErrorFor('deliveryLocation'),
                  marginBottom: AppSizes.s4,
                )),
            MyText(
              text: 'Optional — leave blank and the supplier will contact you.',
              size: AppTextScale.caption,
              color: kGreyTextColor,
            ),
          ]),
        ),

        // Card 3: Price Breakdown
        AppCard(
          margin: const EdgeInsets.only(bottom: AppSizes.s16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MyText(
              text: 'Price Breakdown',
              size: AppTextScale.subtitle,
              weight: AppWeights.bold,
              color: kBlackColor,
              paddingBottom: AppSizes.s16,
            ),
            PriceRow(label: 'Part Price', pence: o.pricePence),
            const SizedBox(height: AppSizes.s8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(
                  text: 'Delivery Fee',
                  size: AppTextScale.body,
                  color: kGreyTextColor,
                ),
                MyText(
                  text: days == null
                      ? 'Free'
                      : (delivery?.label ?? 'Included'),
                  size: AppTextScale.body,
                  weight: AppWeights.medium,
                  color: kBlackColor,
                ),
              ],
            ),
            const Divider(height: AppSizes.s24),
            PriceRow(label: 'Total Price', pence: o.pricePence, emphasised: true),
          ]),
        ),

        Obx(() {
          final e = _c.formError.value;
          return e == null
              ? const SizedBox.shrink()
              : MyText(
                  text: e,
                  size: AppTextScale.body,
                  color: kRedColor,
                  paddingTop: AppSizes.s12);
        }),
      ]),
      bottomNavigationBar: Obx(() {
        final why = unacceptableReason(widget.offer, widget.request);
        return Padding(
          padding: AppSizes.DEFAULT,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (why != null)
              MyText(
                text: why,
                size: AppTextScale.label,
                color: kGreyTextColor,
                textAlign: TextAlign.center,
                paddingBottom: AppSizes.s8,
              ),
            MyButton(
              buttonText: 'Place Order',
              loading: _c.busy.value,
              enabled: why == null && !_c.shouldRefetch,
              onTap: _place,
            ),
          ]),
        );
      }),
    );
  }
}

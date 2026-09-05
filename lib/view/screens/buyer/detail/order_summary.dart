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
/// Accepting CLOSES the parent request and auto-REJECTS every sibling offer in
/// the SAME transaction, and the buyer is sent no notification of their own
/// accept — so any comparison or offers screen still on the stack behind this
/// one is stale the moment this succeeds.
///
/// There is no `sellerAddress` row and no 'Part Price + Delivery Fee = Total'
/// block: neither has a backend source, and `Order.totalPence` is copied
/// verbatim from `Offer.pricePence`.
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
  /// `deliveryLocation` (1..300) is the ONE writable field on the accept route.
  final TextEditingController _location = TextEditingController();
  late final AcceptOfferController _c = AcceptOfferController.ensure();

  @override
  void initState() {
    super.initState();
    // The controller is a Get singleton and outlives this screen, so a 409 it
    // absorbed for ANOTHER offer would otherwise still be disabling the button
    // and printing its copy under the field here.
    _c.beginOffer(widget.offer.id);
  }

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    FocusScope.of(context).unfocus();
    // `valueOrNull` rather than a switch over Ok/Err: the sealed result type
    // lives in data/core, which the view layer must not import (§4). A blank
    // location is dropped by the repository — `""` fails the server's min(1),
    // while omitting the key entirely is valid.
    final order = (await _c.accept(
      offerId: widget.offer.id,
      deliveryLocation: _location.text,
    )).valueOrNull;
    if (!mounted) return;
    if (order != null) {
      // Order payloads carry NO supplier identity — only `supplierId` — so this
      // is the last screen that knows the name. It travels forward by hand.
      Get.off(() => OrderStatusPage(
          orderId: order.id,
          supplierName: supplierDisplayName(widget.offer.supplier)));
      return;
    }
    // The offer went while the buyer was reading it; the list behind is stale,
    // so hand them back to it rather than leaving them on a dead summary.
    if (_c.conflict.value == ConflictKind.offerNotAcceptable) {
      displayToast(msg: 'This offer is no longer available.');
      Get.back();
    }
    // requestAlreadyAccepted stays put: its copy is already in formError, and
    // the buyer's existing order is reachable from My Orders, not from here.
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    final delivery = o.deliveryOption, days = o.deliveryTimeDays;
    return Scaffold(
      appBar: GeneralAppBar(title: 'Order Summary', centerdTitle: false),
      body: ListView(padding: AppSizes.DEFAULT, children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DetailItem(label: 'Vehicle', value: widget.request.regNumber),
            DetailItem(label: 'Part ordered', value: widget.request.partName),
            DetailItem(
                label: 'Supplier', value: supplierDisplayName(o.supplier)),
            if (delivery != null)
              DetailItem(label: 'Delivery', value: delivery.label),
            if (days != null)
              DetailItem(
                  label: 'Delivery time',
                  value: days == 1 ? '1 day' : '$days days'),
            PriceRow(label: 'Total', pence: o.pricePence, emphasised: true),
          ]),
        ),
        MyText(
            text: 'Where should this be delivered?',
            size: AppTextScale.subtitle,
            weight: AppWeights.semibold,
            color: kBlackColor,
            paddingTop: AppSizes.s20,
            paddingBottom: AppSizes.s8),
        Obx(() => CountedTextField(
              controller: _location,
              maxLength: 300,
              maxLines: 2,
              hintText: 'Street, town and postcode',
              errorText: _c.fieldErrorFor('deliveryLocation'),
              marginBottom: AppSizes.s4,
            )),
        MyText(
            text: 'Optional — leave it blank and the supplier will be in touch.',
            size: AppTextScale.label,
            color: kGreyTextColor),
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
        // Defence in depth. The two screens above already refuse to walk here
        // on a dead offer; `shouldRefetch` shuts the door AFTER a 409 has
        // proved THIS one is gone, so a second tap cannot repeat it.
        final why = unacceptableReason(widget.offer, widget.request);
        return Padding(
          padding: AppSizes.DEFAULT,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (why != null)
              MyText(text: why, size: AppTextScale.label, color: kGreyTextColor,
                  textAlign: TextAlign.center, paddingBottom: AppSizes.s8),
            MyButton(buttonText: 'Place Order', loading: _c.busy.value,
                enabled: why == null && !_c.shouldRefetch, onTap: _place),
          ]),
        );
      }),
    );
  }
}

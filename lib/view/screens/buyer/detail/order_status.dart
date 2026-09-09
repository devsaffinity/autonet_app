import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/order_detail_controller.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/view/screens/buyer/detail/review_page.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/counted_text_field.dart';
import 'package:autonect/view/widget/custom_dialog_widget.dart';
import 'package:autonect/view/widget/detail_item.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/order_progress_card.dart';
import 'package:autonect/view/widget/price_row.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One order, driven entirely by the server's `status` and its `events[]` —
/// never by a locally simulated machine. An admin can force any order straight
/// to CANCELLED or DELIVERED, so PLACED -> DELIVERED is observable and the rows
/// in between must read `skipped`, which is what `buildOrderSteps` produces.
class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key, required this.orderId, this.supplierName});

  final String orderId;

  /// An order payload carries no supplier identity beyond `supplierId`, so the
  /// name only arrives from the screen that accepted the offer. Null when the
  /// order was opened from My Orders, where nothing on the wire knows it.
  final String? supplierName;

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  late final OrderDetailController c = OrderDetailController.ensure();

  @override
  void initState() {
    super.initState();
    c.load(widget.orderId);
  }

  /// ONE cancel dialog at a time. This method stays open for as long as the
  /// buyer takes to type a reason, and a second entry — a tap in the frame
  /// before the pushed route takes pointer input away from this screen — would
  /// stack a second dialog over the order the first one is already cancelling.
  bool _confirming = false;

  /// The note is MANDATORY: a CANCELLED with no note is a `.refine` 400 bound
  /// to `note`, which the repository refuses to send at all.
  Future<void> _cancel() async {
    if (_confirming) return;
    _confirming = true;
    try {
      final note = await Get.dialog<String>(const _CancelDialog());
      if (note == null) return;
      await c.cancel(note);
    } finally {
      _confirming = false;
    }
  }

  void _review() => Get.to(() => ReviewPage.forOrder(orderId: widget.orderId,
      supplierName: widget.supplierName ?? 'this supplier'));

  Widget _header(Order order) {
    final location = order.deliveryLocation;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: MyText(text: order.request.partName,
              size: AppTextScale.subtitle, weight: AppWeights.bold,
              color: kBlackColor)),
          StatusBadge(label: order.status?.label ?? 'Unknown',
              color: orderStatusColor(order.status)),
        ]),
        DetailItem(label: 'Vehicle', value: order.request.regNumber),
        if (location != null && location.trim().isNotEmpty)
          DetailItem(label: 'Delivering to', value: location),
        PriceRow(label: 'Total', pence: order.totalPence, emphasised: true),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Order Status', centerdTitle: false),
      body: Obx(() {
        final notice = c.staleNotice.value, error = c.formError.value;
        return StateView<Order>(
          state: c.order.value,
          onRetry: () => c.load(widget.orderId),
          builder: (_, order) => ListView(padding: AppSizes.DEFAULT, children: [
            _header(order),
            if (notice != null)
              MyText(text: notice, size: AppTextScale.label,
                  color: kGreyTextColor, paddingTop: AppSizes.s12),
            if (error != null)
              MyText(text: error, size: AppTextScale.body, color: kRedColor,
                  paddingTop: AppSizes.s12),
            const SizedBox(height: AppSizes.s12),
            OrderProgressCard(steps: c.steps),
          ]),
        );
      }),
      // No buyer 'mark delivered' or 'confirm receipt' exists anywhere: every
      // forward transition is supplier-only and a buyer attempting one gets a
      // 403 'Only the supplier advances fulfillment'.
      bottomNavigationBar: Obx(() {
        final cancellable = c.canCancel, reviewable = c.canReview;
        if (!cancellable && !reviewable) return const SizedBox.shrink();
        return Padding(
          padding: AppSizes.DEFAULT,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Gated on DELIVERED: reviewing earlier is a guaranteed 409.
            if (reviewable) MyButton(buttonText: 'Give Review', onTap: _review),
            if (cancellable)
              MyButton(buttonText: 'Cancel order', onTap: _cancel,
                  backgroundColor: kWhiteColor, outlineColor: kRedColor,
                  fontColor: kRedColor),
          ]),
        );
      }),
    );
  }
}

/// Owns its TextEditingController so it dies with the dialog, and keeps
/// 'Confirm cancellation' inert until a reason exists.
class _CancelDialog extends StatefulWidget {
  const _CancelDialog();

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomDialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            MyText(text: 'Cancel this order?', size: AppTextScale.title,
                weight: AppWeights.bold, color: kBlackColor,
                paddingBottom: AppSizes.s8),
            MyText(text: 'A buyer can only cancel while an order is still '
                    'PLACED, and the supplier is told why.',
                size: AppTextScale.body, color: kGreyTextColor,
                textAlign: TextAlign.center, paddingBottom: AppSizes.s16),
            // onChanged, not a controller listener: nothing sets this text
            // programmatically, and it is only the button that needs the rebuild.
            CountedTextField(controller: _note, maxLength: 500, maxLines: 3,
                hintText: 'Why are you cancelling?',
                onChanged: (_) => setState(() {})),
            // oneShot on BOTH: each pops, and the second pop of a double tap
            // reaches the order screen underneath this dialog.
            MyButton(buttonText: 'Confirm cancellation', oneShot: true,
                enabled: _note.text.trim().isNotEmpty,
                backgroundColor: kRedColor,
                onTap: () => Get.back<String>(result: _note.text)),
            MyButton(buttonText: 'Keep order', mTop: AppSizes.s12,
                backgroundColor: kWhiteColor, outlineColor: kSecondaryColor,
                fontColor: kSecondaryColor, oneShot: true,
                onTap: () => Get.back<String>()),
          ]),
        ),
      );
}

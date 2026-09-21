import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/my_orders_controller.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/buyer/detail/order_status.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/choice_chips_field.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// `GET /v1/orders`, newest first — the server sorts createdAt descending.
///
/// This is the third nav tab. Before this build the orders list had no entry
/// point anywhere in the app.
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late final MyOrdersController c = MyOrdersController.ensure();

  @override
  void initState() {
    super.initState();
    c.refreshFirst();
  }

  /// Deliberately OUTSIDE [PagedListView], as on the requests screen: a list
  /// can only paint a header above its own rows, so filtering to a status with
  /// no orders — or losing the network — would take the chips off screen and
  /// strand the buyer on a filter with no way back to 'All'.
  Widget get _filters => Obx(() => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.s20, AppSizes.s16, AppSizes.s20, AppSizes.s8),
        // ALL FIVE statuses, PLACED included: the list filter and the PATCH
        // verb enum are different sets.
        child: ChoiceChipsField<OrderStatus?>(
          options: MyOrdersController.filterOptions,
          selected: c.filter.value,
          onSelect: c.setFilter,
        ),
      ));

  Widget get _list => Obx(() {
    final err = c.loadMoreError.value;
    return PagedListView<Order>(
      state: c.state.value,
      loadingMore: c.loadingMore.value,
      // Failed.message is the one place an ApiError becomes copy; wrapping it
      // here is what keeps `data/core` out of this file's imports.
      loadMoreError: err == null ? null : Failed<List<Order>>(err).message,
      hasMore: c.hasMore,
      onLoadMore: c.loadMore,
      onRefresh: c.refreshFirst,
      itemBuilder: (_, o) => _OrderRow(order: o),
    );
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: GeneralAppBar(title: 'My Orders', hasBackButton: false),
        body: Column(children: [_filters, Expanded(child: _list)]),
      );
}

/// `yyyy-mm-dd`, not a localised date: `package:intl` is not a dependency of
/// this project and must not become one for one row's timestamp.
String _isoDate(DateTime at) {
  final d = at.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => MyRippleEffect(
        radius: AppSizes.radiusMd,
        onTap: () => Get.to(() => OrderStatusPage(orderId: order.id)),
        child: AppCard(
          margin: const EdgeInsets.only(bottom: AppSizes.s12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: MyText(text: order.request.partName,
                  size: AppTextScale.body, weight: AppWeights.semibold,
                  color: kBlackColor)),
              if (order.hasReviewed) ...[
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: kSecondaryColor),
                      const SizedBox(width: 2),
                      MyText(
                        text: '${order.buyerReview?.rating ?? 5}',
                        size: AppTextScale.label,
                        weight: AppWeights.bold,
                        color: kSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ],
              StatusBadge(label: order.status?.label ?? 'Unknown',
                  color: orderStatusColor(order.status)),
            ]),
            MyText(text: order.request.regNumber, size: AppTextScale.label,
                color: kGreyTextColor, paddingTop: AppSizes.s4),
            Row(children: [
              Expanded(child: MyText(text: formatPence(order.totalPence),
                  size: AppTextScale.subtitle, weight: AppWeights.bold,
                  color: kBlackColor)),
              MyText(text: _isoDate(order.createdAt), size: AppTextScale.label,
                  color: kGreyTextColor),
            ]),
          ]),
        ),
      );
}

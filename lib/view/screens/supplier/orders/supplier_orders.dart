import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/supplier/supplier_orders_controller.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_order_detail.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupplierOrdersPage extends StatefulWidget {
  const SupplierOrdersPage({super.key});

  @override
  State<SupplierOrdersPage> createState() => _SupplierOrdersPageState();
}

class _SupplierOrdersPageState extends State<SupplierOrdersPage> {
  late final SupplierOrdersController _controller;
  static const List<String> _tabs = ['Active', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _controller = SupplierOrdersController.ensure();
    _controller.refreshFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Customer Orders'),
      body: RefreshIndicator(
        onRefresh: _controller.refreshFirst,
        color: kSecondaryColor,
        child: SingleChildScrollView(
          padding: AppSizes.DEFAULT,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => SupplierPillTabs(
                  labels: _tabs,
                  selectedIndex: _controller.currentTabIndex.value,
                  onChanged: _controller.setTab,
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                final tabIdx = _controller.currentTabIndex.value;
                final tabName = _tabs[tabIdx].toLowerCase();

                return switch (_controller.state.value) {
                  Loading() => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: kSecondaryColor),
                      ),
                    ),
                  Failed(:final error) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            MyText(
                              text: 'Unable to load orders',
                              size: 16,
                              weight: FontWeight.w600,
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
                                height: 38,
                                onTap: _controller.refreshFirst,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Empty(:final title, :final body) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 50,
                              color: kGreyTextColor,
                            ),
                            const SizedBox(height: 12),
                            MyText(
                              text: 'No $tabName orders yet',
                              size: 15,
                              weight: FontWeight.w600,
                              color: kBlackColor,
                              paddingBottom: 4,
                            ),
                            MyText(
                              text:
                                  'Orders requiring fulfillment will appear here once accepted.',
                              size: 13,
                              weight: FontWeight.w400,
                              color: kGreyTextColor,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Data<List<Order>>(:final value) => Column(
                      children: [
                        Container(
                          decoration: AppStyling().myShadowDecoration(
                            color: kPrimaryColor,
                            radius: 14,
                            borderColor: kTransperentColor,
                          ),
                          child: Column(
                            children: List.generate(value.length * 2 - 1, (i) {
                              if (i.isOdd) {
                                return const Divider(
                                  height: 1,
                                  color: kTertiaryColor,
                                  indent: 16,
                                  endIndent: 16,
                                );
                              }
                              final o = value[i ~/ 2];
                              final shortId = o.id.length > 6
                                  ? o.id.substring(o.id.length - 6)
                                  : o.id;
                              final badgeColor = tabIdx == 1
                                  ? const Color(0xff34C759)
                                  : tabIdx == 2
                                      ? kRedColor
                                      : kSecondaryColor;

                              return SupplierListRow(
                                image: Assets.imagesProfileImage,
                                title: 'Order #$shortId',
                                subtitle: o.request.partName,
                                badge: SupplierStatusBadge(
                                  label: o.status?.label ?? 'Placed',
                                  color: badgeColor,
                                ),
                                onTap: () => Get.to(
                                  () => SupplierOrderDetailPage(order: o),
                                ),
                              );
                            }),
                          ),
                        ),
                        if (_controller.hasMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Obx(
                                () => _controller.loadingMore.value
                                    ? const CircularProgressIndicator(
                                        color: kSecondaryColor,
                                      )
                                    : SizedBox(
                                        width: 140,
                                        child: MyButton(
                                          buttonText: 'Load More',
                                          height: 38,
                                          backgroundColor: kPrimaryColor,
                                          outlineColor: kSecondaryColor,
                                          fontColor: kSecondaryColor,
                                          onTap: _controller.loadMore,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                };
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

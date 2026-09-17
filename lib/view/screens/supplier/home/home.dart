import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/supplier/home/home_cards.dart';
import 'package:autonect/view/screens/supplier/home/home_quick_management.dart';
import 'package:autonect/view/screens/supplier/home/home_top_bar.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_order_detail.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_orders.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_request_detail.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupplierHomePage extends StatefulWidget {
  const SupplierHomePage({super.key});

  @override
  State<SupplierHomePage> createState() => _SupplierHomePageState();
}

class _SupplierHomePageState extends State<SupplierHomePage> {
  late final SupplierHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SupplierHomeController.ensure();
    _controller.load();
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
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _controller.load,
          color: kSecondaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SupplierHomeTopBar(),
                const SizedBox(height: 16),
                const SupplierPerformanceCard(),
                const SizedBox(height: 12),
                const SupplierCreditCard(),
                const SizedBox(height: 20),
                MyText(
                  text: 'Quick Management',
                  size: 16,
                  weight: FontWeight.w700,
                  color: kBlackColor,
                  paddingBottom: 12,
                ),
                const SupplierQuickManagement(),
                const SizedBox(height: 20),
                SupplierSectionHeader(
                  title: 'Leads matching you',
                  onAction: () => RoleShell.maybeOf(context)?.goTo(1),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  return switch (_controller.leads.value) {
                    Loading() => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: kSecondaryColor,
                          ),
                        ),
                      ),
                    Failed(:final error) => _buildEmptyCard(
                        title: 'Unable to load leads',
                        message: error.message,
                      ),
                    Empty(:final title, :final body) => _buildEmptyCard(
                        title: title ?? 'No matching leads',
                        message: body ?? '',
                      ),
                    Data<List<SupplierLead>>(:final value) => _buildList(
                        value.map((l) {
                          final vehicleStr = l.vehicleMake != null
                              ? '${l.vehicleMake} ${l.vehicleYear ?? ''}'.trim()
                              : l.partName;
                          final partStr =
                              '${l.partName}${l.region != null ? ' - ${l.region!.label}' : ''}';
                          return SupplierListRow(
                            image: Assets.imagesCar1,
                            title: vehicleStr,
                            subtitle: partStr,
                            trailing: _timeAgo(l.createdAt),
                            onTap: () => Get.to(
                              () => SupplierRequestDetailPage(requestId: l.id),
                            ),
                          );
                        }).toList(),
                      ),
                  };
                }),
                const SizedBox(height: 20),
                SupplierSectionHeader(
                  title: 'Orders to fulfil',
                  onAction: () => Get.to(() => const SupplierOrdersPage()),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  return switch (_controller.orders.value) {
                    Loading() => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: kSecondaryColor,
                          ),
                        ),
                      ),
                    Failed(:final error) => _buildEmptyCard(
                        title: 'Unable to load orders',
                        message: error.message,
                      ),
                    Empty(:final title, :final body) => _buildEmptyCard(
                        title: title ?? 'No orders to fulfil',
                        message: body ?? '',
                      ),
                    Data<List<Order>>(:final value) => _buildList(
                        value.map((o) {
                          final shortId = o.id.length > 6
                              ? o.id.substring(o.id.length - 6)
                              : o.id;
                          final subtitle =
                              '${o.request.partName} - Order #$shortId';
                          return SupplierListRow(
                            image: Assets.imagesProfileImage,
                            title: 'Order #$shortId',
                            subtitle: subtitle,
                            trailing: o.status?.label ?? 'Placed',
                            onTap: () => Get.to(
                              () => SupplierOrderDetailPage(order: o),
                            ),
                          );
                        }).toList(),
                      ),
                  };
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard({required String title, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: AppStyling().myShadowDecoration(
        color: kPrimaryColor,
        radius: 14,
        borderColor: kTransperentColor,
      ),
      child: Column(
        children: [
          MyText(
            text: title,
            size: 14,
            weight: FontWeight.w600,
            color: kBlackColor,
            textAlign: TextAlign.center,
            paddingBottom: 4,
          ),
          MyText(
            text: message,
            size: 12,
            weight: FontWeight.w400,
            color: kGreyTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Divider-separated rows inside one shadowed card.
  Widget _buildList(List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: AppStyling().myShadowDecoration(
        color: kPrimaryColor,
        radius: 14,
        borderColor: kTransperentColor,
      ),
      child: Column(
        children: List.generate(rows.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Divider(
              height: 1,
              color: kTertiaryColor,
              indent: 16,
              endIndent: 16,
            );
          }
          return rows[i ~/ 2];
        }),
      ),
    );
  }
}

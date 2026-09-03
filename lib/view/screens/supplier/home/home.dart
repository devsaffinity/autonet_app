import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/supplier/home/home_cards.dart';
import 'package:autonect/view/screens/supplier/home/home_quick_management.dart';
import 'package:autonect/view/screens/supplier/home/home_top_bar.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_order_detail.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_request_detail.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupplierHomePage extends StatelessWidget {
  const SupplierHomePage({super.key});

  // Placeholder rows, shaped like the buyer screens so one API layer replaces
  // both uniformly.
  static const List<Map<String, String>> _leads = [
    {
      'vehicle': 'Toyota Yaris 2020',
      'part': 'Transmission - London',
      'age': '12m ago',
    },
    {
      'vehicle': 'Ford Mustang GT',
      'part': 'Brake Discs - South East',
      'age': '1h ago',
    },
    {'vehicle': 'BMW M3 2019', 'part': 'Alternator - Wales', 'age': '3h ago'},
  ];

  static const List<Map<String, String>> _orders = [
    {
      'buyer': 'Sarah Johnson',
      'detail': 'Transmission - Order #4821',
      'state': 'Paid',
    },
    {
      'buyer': 'Michael Chen',
      'detail': 'Brake Discs - Order #4818',
      'state': 'Packing',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
              _buildList(
                _leads
                    .map(
                      (l) => SupplierListRow(
                        image: Assets.imagesCar1,
                        title: l['vehicle']!,
                        subtitle: l['part']!,
                        trailing: l['age']!,
                        onTap: () =>
                            Get.to(() => const SupplierRequestDetailPage()),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              SupplierSectionHeader(
                title: 'Orders to fulfil',
                onAction: () => RoleShell.maybeOf(context)?.goTo(2),
              ),
              const SizedBox(height: 12),
              _buildList(
                _orders
                    .map(
                      (o) => SupplierListRow(
                        image: Assets.imagesProfileImage,
                        title: o['buyer']!,
                        subtitle: o['detail']!,
                        trailing: o['state']!,
                        onTap: () =>
                            Get.to(() => const SupplierOrderDetailPage()),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Divider-separated rows inside one shadowed card, exactly the container the
  /// electrician home wraps its Upcoming Bookings list in.
  Widget _buildList(List<Widget> rows) {
    return Container(
      decoration: AppStyling().myShadowDecoration(
        color: kPrimaryColor,
        radius: 14,
        borderColor: kTransperentColor,
      ),
      child: Column(
        children: List.generate(rows.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Divider(
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

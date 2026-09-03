import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_order_detail.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Orders created when a buyer accepts one of this supplier's offers.
class SupplierOrdersPage extends StatefulWidget {
  const SupplierOrdersPage({super.key});

  @override
  State<SupplierOrdersPage> createState() => _SupplierOrdersPageState();
}

class _SupplierOrdersPageState extends State<SupplierOrdersPage> {
  int _tab = 0;
  static const List<String> _tabs = ['Active', 'Delivered', 'Cancelled'];

  static const Map<int, List<Map<String, String>>> _orders = {
    0: [
      {
        'buyer': 'Michael Chen',
        'detail': 'Brake Discs - Order #4818',
        'state': 'Packing',
      },
      {
        'buyer': 'Sarah Johnson',
        'detail': 'Transmission - Order #4821',
        'state': 'Paid',
      },
    ],
    1: [
      {
        'buyer': 'David Miller',
        'detail': 'Radiator - Order #4790',
        'state': 'Delivered',
      },
    ],
    2: [
      {
        'buyer': 'Elena Ross',
        'detail': 'Headlamp - Order #4771',
        'state': 'Cancelled',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final rows = _orders[_tab] ?? const <Map<String, String>>[];
    return Scaffold(
      appBar: GeneralAppBar(title: 'Orders'),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SupplierPillTabs(
              labels: _tabs,
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 20),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: MyText(
                    text: 'No ${_tabs[_tab].toLowerCase()} orders yet',
                    size: 14,
                    weight: FontWeight.w500,
                    color: kGreyTextColor,
                  ),
                ),
              )
            else
              Container(
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
                  final o = rows[i ~/ 2];
                  return SupplierListRow(
                    image: Assets.imagesProfileImage,
                    title: o['buyer']!,
                    subtitle: o['detail']!,
                    badge: SupplierStatusBadge(
                      label: o['state']!,
                      color: _tab == 1
                          ? const Color(0xff34C759)
                          : _tab == 2
                          ? kRedColor
                          : kSecondaryColor,
                    ),
                    onTap: () => Get.to(() => const SupplierOrderDetailPage()),
                  );
                }),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

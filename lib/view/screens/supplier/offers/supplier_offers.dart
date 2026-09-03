import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_offer_card.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Every offer this supplier has sent, split by the backend's OfferStatus.
class SupplierOffersPage extends StatefulWidget {
  const SupplierOffersPage({super.key});

  @override
  State<SupplierOffersPage> createState() => _SupplierOffersPageState();
}

class _SupplierOffersPageState extends State<SupplierOffersPage> {
  int _tab = 0;
  static const List<String> _tabs = ['Pending', 'Accepted', 'Rejected'];

  // Placeholder feed keyed by tab, shaped like the buyer's offer lists.
  final Map<int, List<Map<String, dynamic>>> _offers = {
    0: [
      {
        'buyer': 'Sarah Johnson',
        'vehicle': 'Toyota Yaris 2020 - Transmission',
        'price': '350.00',
        'delivery': 'Courier - 2 days',
        'status': 'Pending',
      },
      {
        'buyer': 'James Wilson',
        'vehicle': 'BMW M3 2019 - Alternator',
        'price': '180.00',
        'delivery': 'Collection',
        'status': 'Pending',
      },
    ],
    1: [
      {
        'buyer': 'Michael Chen',
        'vehicle': 'Ford Mustang GT - Brake Discs',
        'price': '240.00',
        'delivery': 'Courier - 1 day',
        'status': 'Accepted',
      },
    ],
    2: [
      {
        'buyer': 'Elena Ross',
        'vehicle': 'Audi A4 2018 - Radiator',
        'price': '120.00',
        'delivery': 'Courier - 3 days',
        'status': 'Rejected',
      },
    ],
  };

  void _withdraw(int index) => setState(() => _offers[0]!.removeAt(index));

  @override
  Widget build(BuildContext context) {
    final rows = _offers[_tab] ?? const <Map<String, dynamic>>[];
    return Scaffold(
      appBar: GeneralAppBar(hasBackButton: false, title: 'My Offers'),
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
                    text: 'No ${_tabs[_tab].toLowerCase()} offers yet',
                    size: 14,
                    weight: FontWeight.w500,
                    color: kGreyTextColor,
                  ),
                ),
              )
            else
              ...List.generate(
                rows.length,
                (i) => SupplierOfferCard(
                  offer: rows[i],
                  statusIndex: _tab,
                  onWithdraw: () => _withdraw(i),
                ),
              ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

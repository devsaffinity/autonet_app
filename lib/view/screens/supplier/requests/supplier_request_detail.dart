import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_create_offer.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_request_parts.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One unlocked buyer request, read-only, ending in Send Offer. The hero is the
/// same tinted header ComparisonPage draws for the buyer.
class SupplierRequestDetailPage extends StatelessWidget {
  const SupplierRequestDetailPage({super.key});

  static const List<Map<String, String>> _summary = [
    {
      'icon': Assets.imagesPA,
      'label': 'Vehicle',
      'value': 'Toyota Yaris 2020',
    },
    {
      'icon': Assets.imagesPB,
      'label': 'Requested Part',
      'value': 'Transmission',
    },
    {'icon': Assets.imagesPC, 'label': 'Condition', 'value': 'New or Refurb'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SupplierVehicleHero(title: 'Toyota Yaris 2020'),
            Padding(
              padding: AppSizes.DEFAULT,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MyText(
                          text: 'Request #4821',
                          size: 16,
                          weight: FontWeight.w700,
                          color: kBlackColor,
                        ),
                      ),
                      const SupplierStatusBadge(
                        label: 'Urgent',
                        color: kRedColor,
                      ),
                    ],
                  ),
                  MyText(
                    paddingTop: 4,
                    paddingBottom: 14,
                    text: 'Posted 12 minutes ago by Sarah Johnson - London',
                    size: 14,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                  ),
                  SupplierCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._summary.map(
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
                            const Expanded(
                              child: SupplierDetailItem(
                                label: 'Reg Plate',
                                value: 'LM20 XKR',
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
                          children: const [
                            Expanded(
                              child: SupplierDetailItem(
                                label: 'Delivery to',
                                value: 'London, N1',
                              ),
                            ),
                            Expanded(
                              child: SupplierDetailItem(
                                label: 'Offers so far',
                                value: '4 suppliers',
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
                          text:
                              'Gearbox slipping in second. Happy with a refurbished unit if it carries at least 6 months warranty. Needs fitting this week.',
                          size: 14,
                          weight: FontWeight.w400,
                          color: kGreyTextColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SupplierNoteCard(
                    title: 'One offer per request',
                    body:
                        'You can send a single offer against a request and edit it any time before the buyer decides.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavButton(
        buttonText: 'Send Offer',
        onTap: () => Get.to(() => const SupplierCreateOfferPage()),
      ),
    );
  }
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/supplier/supplier_offers_controller.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_offer_card.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupplierOffersPage extends StatefulWidget {
  const SupplierOffersPage({super.key});

  @override
  State<SupplierOffersPage> createState() => _SupplierOffersPageState();
}

class _SupplierOffersPageState extends State<SupplierOffersPage> {
  late final SupplierOffersController _controller;
  static const List<String> _tabs = ['Pending', 'Accepted', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _controller = SupplierOffersController.ensure();
    _controller.refreshFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(hasBackButton: false, title: 'My Quotes'),
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
                              text: 'Unable to load offers',
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
                              Icons.local_offer_outlined,
                              size: 50,
                              color: kGreyTextColor,
                            ),
                            const SizedBox(height: 12),
                            MyText(
                              text: 'No $tabName offers yet',
                              size: 15,
                              weight: FontWeight.w600,
                              color: kBlackColor,
                              paddingBottom: 4,
                            ),
                            MyText(
                              text:
                                  'Quotes you send to buyers will appear in this section.',
                              size: 13,
                              weight: FontWeight.w400,
                              color: kGreyTextColor,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Data<List<SupplierOffer>>(:final value) => Column(
                      children: [
                        ...value.map(
                          (offer) => SupplierOfferCard(
                            offer: offer,
                            statusIndex: tabIdx,
                            onWithdraw: () => _controller.withdrawOffer(offer.id),
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

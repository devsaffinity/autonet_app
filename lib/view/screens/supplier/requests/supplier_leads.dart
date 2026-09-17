import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/supplier/supplier_leads_controller.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_lead_card.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/search_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupplierLeadsPage extends StatefulWidget {
  const SupplierLeadsPage({super.key});

  @override
  State<SupplierLeadsPage> createState() => _SupplierLeadsPageState();
}

class _SupplierLeadsPageState extends State<SupplierLeadsPage> {
  late final SupplierLeadsController _controller;

  static const List<String> _filters = [
    'London',
    'South East',
    'South West',
    'Midlands',
    'New',
    'Used',
    'Urgent',
  ];

  @override
  void initState() {
    super.initState();
    _controller = SupplierLeadsController.ensure();
    _controller.refreshFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(hasBackButton: false, title: 'Incoming Leads'),
      body: RefreshIndicator(
        onRefresh: _controller.refreshFirst,
        color: kSecondaryColor,
        child: SingleChildScrollView(
          padding: AppSizes.DEFAULT,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchField(
                hint: 'Search by part name...',
                onChanged: _controller.setQuery,
              ),
              const SizedBox(height: 12),
              MyText(
                text: 'Filter by region, condition or urgency',
                size: 12,
                weight: FontWeight.w400,
                color: kGreyTextColor,
                paddingBottom: 10,
              ),
              Obx(
                () => SupplierChoiceChips(
                  options: _filters,
                  selected: _controller.activeFilterLabels,
                  onToggle: _controller.toggleFilter,
                ),
              ),
              const SizedBox(height: 18),
              Obx(() {
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
                              text: 'Unable to load leads',
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
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 60,
                              color: kGreyTextColor,
                            ),
                            const SizedBox(height: 12),
                            MyText(
                              text: title ?? 'No matches found',
                              size: 16,
                              weight: FontWeight.w600,
                              color: kBlackColor,
                              paddingBottom: 6,
                            ),
                            MyText(
                              text: body ?? 'Try adjusting your search or filters.',
                              size: 13,
                              weight: FontWeight.w400,
                              color: kGreyTextColor,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Data<List<SupplierLead>>(:final value) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: 'Showing ${value.length} matching leads',
                          size: 14,
                          weight: FontWeight.w500,
                          color: kGreyTextColor,
                          paddingBottom: 12,
                        ),
                        ...value.map(
                          (lead) => SupplierLeadCard(lead: lead),
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
                                        width: 160,
                                        child: MyButton(
                                          buttonText: 'Load More Leads',
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

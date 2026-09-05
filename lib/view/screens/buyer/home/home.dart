import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/buyer_home_controller.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/buyer/detail/comparison.dart';
import 'package:autonect/view/screens/buyer/home/widgets/active_request_card.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The buyer's home.
///
/// Stateful because BuyerNavBar mounts it as a `const` screen: nothing upstream
/// can fetch on its behalf, so it owns its own load.
///
/// PHASE 4: there is no Service Providers section. The backend exposes no
/// electrician or provider listing route anywhere — only
/// `POST /electrician/registration`, a write — so the fixture card deck that
/// used to sit here could never have been filled from the API.
class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  late final BuyerHomeController _c;

  @override
  void initState() {
    super.initState();
    _c = BuyerHomeController.ensure();
    _c.load();
  }

  /// Straight off the session — `GET /v1/me` is phase 2, and the token payload
  /// already carries the name that the 'Lorem Ipsum' literal stood in for.
  String get _name => Get.find<TokenStore>().user?.name ?? 'there';

  void _openRequests() => RoleShell.maybeOf(context)?.goTo(1);

  List<PartRequest> _withOffers(ViewState<List<PartRequest>> s) =>
      switch (s) {
        Data<List<PartRequest>>(:final value) => [
          for (final r in value)
            if (r.offerCount > 0) r,
        ],
        _ => const [],
      };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _c.load,
        child: ListView(
          padding: AppSizes.DEFAULT,
          children: [
            _header(),
            const SizedBox(height: AppSizes.s20),
            // The only inbound navigation to the wizard from this screen; the
            // search bar it replaces promised a filter no route accepts.
            MyButton(buttonText: 'Request a Part',
                onTap: () => Get.to(() => const AddPartRequestPage())),
            const SizedBox(height: AppSizes.s24),
            _sectionHeader('Active Requests'),
            SizedBox(
              height: kActiveRequestCardHeight,
              child: Obx(() => StateView<List<PartRequest>>(
                state: _c.activeRequests.value,
                onRetry: _c.load,
                emptyTitle: 'No open requests',
                builder: (_, items) => _carousel(items),
              )),
            ),
            const SizedBox(height: AppSizes.s24),
            // NOT an offers feed: there is no cross-request buyer offers
            // endpoint, so this is driven by the offerCount already on each
            // request — zero extra calls, and the label says what it shows.
            _sectionHeader('Requests with offers'),
            Obx(() {
              final items = _withOffers(_c.activeRequests.value);
              if (items.isEmpty) {
                return MyText(text: 'No offers yet — suppliers reply here.',
                    size: AppTextScale.body, color: kGreyTextColor);
              }
              return SizedBox(
                height: kActiveRequestCardHeight,
                child: _carousel(items),
              );
            }),
            const SizedBox(height: AppSizes.s24),
          ],
        ),
      ),
    ),
  );

  Widget _carousel(List<PartRequest> items) => ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: items.length,
    separatorBuilder: (_, _) => const SizedBox(width: AppSizes.s12),
    itemBuilder: (_, i) => ActiveRequestCard(
      request: items[i],
      onTap: () => Get.to(() => ComparisonPage(request: items[i])),
    ),
  );

  Widget _header() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(text: 'Hello', size: AppTextScale.label,
              color: kGreyTextColor),
          MyText(text: _name, size: AppTextScale.subtitle,
              weight: AppWeights.bold, color: kBlackColor),
        ],
      ),
      const Icon(Icons.notifications_outlined, size: AppSizes.s24,
          color: kBlackColor),
    ],
  );

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.s12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(text: title, size: AppTextScale.subtitle,
            weight: AppWeights.bold, color: kBlackColor),
        // maybeOf is nullable on purpose: this page is also pushable
        // standalone, where there is no shell ancestor.
        MyText(text: 'View All', size: AppTextScale.label,
            color: kSecondaryColor, weight: AppWeights.medium,
            onTap: _openRequests),
      ],
    ),
  );
}

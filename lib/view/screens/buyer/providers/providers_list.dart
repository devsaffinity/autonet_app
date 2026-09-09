import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/providers_list_controller.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/screens/buyer/home/widgets/service_provider_card.dart'
    show brandsLabel;
import 'package:autonect/view/screens/buyer/providers/provider_detail.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/enum_select_field.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_pill_tabs.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:autonect/view/widget/search_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The provider directory — the comp's Services screen.
///
/// THE ELECTRICIANS / CODERS TABS ARE A FILTER, NOT TWO POPULATIONS. The
/// schema has exactly one provider table and no column separating a coder
/// from an electrician; what it has is `services`, the callouts each takes.
/// So 'Coders' is `service=ECU_CODING`, and the chips below use the same
/// field. Two tabs returning identical lists would have been worse than one
/// honest list, which is why this waited for the column to exist.
///
/// The comp's 'Dubai, UAE' pill is a UK region picker here: `Region` is twelve
/// UK regions and every price in this product is GBP integer pence.
class ProvidersListPage extends StatefulWidget {
  const ProvidersListPage({super.key});

  @override
  State<ProvidersListPage> createState() => _ProvidersListPageState();
}

class _ProvidersListPageState extends State<ProvidersListPage> {
  final ProvidersListController c = ProvidersListController.ensure();

  @override
  void initState() {
    super.initState();
    c.refreshFirst();
  }

  /// Region options with an explicit 'All' at the head — the null value is
  /// what makes the repository omit the key rather than send it blank.
  static final List<SelectOption<Region?>> _regionOptions = [
    const SelectOption<Region?>(null, 'All regions'),
    for (final r in Region.values) SelectOption<Region?>(r, r.label),
  ];

  /// Tabs and the region picker share a row, as the comp draws them.
  Widget get _tabsAndRegion => Padding(
    padding: const EdgeInsets.fromLTRB(
        AppSizes.s20, AppSizes.s8, AppSizes.s20, 0),
    child: Obx(() => Row(
      children: [
        Expanded(
          child: MyPillTabs(
            labels: ProvidersListController.tabLabels,
            selectedIndex:
                ProvidersListController.tabs.indexOf(c.service.value) < 0
                    // A chip selected a service that is not a tab, so neither
                    // tab is current. Fall back to the first rather than -1,
                    // which MyPillTabs would render as nothing selected.
                    ? 0
                    : ProvidersListController.tabs.indexOf(c.service.value),
            onChanged: (i) => c.setService(ProvidersListController.tabs[i]),
          ),
        ),
        const SizedBox(width: AppSizes.s12),
        SizedBox(
          width: 132,
          child: EnumSelectField<Region?>(
            options: _regionOptions,
            value: c.region.value,
            onChanged: c.setRegion,
            hint: 'All regions',
            bottomPadding: 0,
          ),
        ),
      ],
    )),
  );

  /// Outside [PagedListView] for the same reason as on My Requests: its header
  /// slot renders only in the Data arm, so a search matching nothing would
  /// take its own box away and leave no way to clear it.
  Widget get _search => Padding(
    padding: const EdgeInsets.fromLTRB(
        AppSizes.s20, AppSizes.s12, AppSizes.s20, 0),
    child: SearchField(
      hint: 'Search coders or services',
      marginBottom: 0,
      onChanged: c.setQuery,
    ),
  );

  /// The comp's Diagnostics / ECU Tuning / Dashcam Install row. Tapping the
  /// active chip clears it, so a buyer is never stuck inside a filter.
  Widget get _serviceChips => Obx(() => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s20, vertical: AppSizes.s8),
      itemCount: ProvidersListController.serviceChips.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSizes.s8),
      itemBuilder: (_, i) {
        final service = ProvidersListController.serviceChips[i];
        final selected = c.service.value == service;
        return GestureDetector(
          onTap: () => c.setService(selected ? null : service),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
            decoration: BoxDecoration(
              color: selected ? kSecondaryColor : kMutedSurfaceColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: MyText(
              text: service.label,
              size: AppTextScale.label,
              weight: AppWeights.medium,
              color: selected ? kWhiteColor : kGreyTextColor,
            ),
          ),
        );
      },
    ),
  ));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(title: 'Services'),
    body: Column(children: [
      _tabsAndRegion,
      _search,
      _serviceChips,
      Expanded(child: Obx(() {
        final more = c.loadMoreError.value;
        return PagedListView<ServiceProvider>(
          state: c.state.value,
          loadingMore: c.loadingMore.value,
          loadMoreError: more == null ? null : userMessageFor(more),
          hasMore: c.hasMore,
          onLoadMore: c.loadMore,
          onRefresh: c.refreshFirst,
          emptyTitle: 'No providers match',
          emptyBody: 'Try another service, region or search.',
          itemBuilder: (_, p) => ProviderRow(provider: p),
        );
      })),
    ]),
  );
}

/// One provider in the directory — the comp's row.
///
/// Public so the home strip's View All and this screen render the same thing;
/// a second copy is how two lists of the same data drift apart.
class ProviderRow extends StatelessWidget {
  const ProviderRow({super.key, required this.provider, this.onTap});

  final ServiceProvider provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brands = brandsLabel(provider.brands);
    final url = provider.avatarUrl;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.s20, 0, AppSizes.s20, AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SizedBox(
              height: 48,
              width: 48,
              child: url != null && url.isNotEmpty
                  ? CommonImageView(url: url, cacheKey: provider.id,
                      height: 48, width: 48, radius: AppSizes.radiusPill,
                      fit: BoxFit.cover)
                  : InitialsAvatar(name: provider.fullName, size: 48,
                      radius: AppSizes.radiusPill),
            ),
            const SizedBox(width: AppSizes.s12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name and trade line on one wrapping line, as the comp draws
                // it. Wrap, not Row: at a large font 'Callum Whitfield · ECU
                // Specialist' will not sit on one line at 320dp.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MyText(text: provider.fullName, size: AppTextScale.body,
                        weight: AppWeights.bold, color: kBlackColor),
                    if (provider.headline case final h? when h.isNotEmpty) ...[
                      MyText(text: '  ·  ', size: AppTextScale.body,
                          color: kGreyTextColor),
                      MyText(text: h, size: AppTextScale.body,
                          weight: AppWeights.medium, color: kSecondaryColor),
                    ],
                  ],
                ),
                const SizedBox(height: AppSizes.s4),
                _rating(),
              ],
            )),
          ]),
          // Skills is what they DO; brands is what they do it TO. The comp
          // shows the skills line, and falls back to brands rather than
          // leaving a gap for a provider who listed only manufacturers.
          if (_secondary(brands) case final line?) ...[
            const SizedBox(height: AppSizes.s8),
            MyText(text: line, size: AppTextScale.label,
                color: kGreyTextColor, maxLines: 2,
                textOverflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: AppSizes.s12),
          MyButton(
            buttonText: 'View Profile',
            fontSize: AppTextScale.label,
            height: 40,
            radius: AppSizes.radiusMd,
            onTap: onTap ??
                () => Get.to(() => ProviderDetailPage(providerId: provider.id)),
          ),
        ],
      ),
    );
  }

  String? _secondary(String brands) {
    if (provider.skills.isNotEmpty) return provider.skills.join(', ');
    return brands.isEmpty ? null : brands;
  }

  /// '4.8 (126 Reviews)' as the comp writes it, or 'New' — never 0.0, which
  /// would read as a bad rating rather than a missing one.
  Widget _rating() {
    if (!provider.isRated) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_outline_rounded, size: AppSizes.s16,
            color: kGreyTextColor),
        const SizedBox(width: AppSizes.s4),
        MyText(text: 'New', size: AppTextScale.label, color: kGreyTextColor,
            weight: AppWeights.semibold),
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star_rounded, size: AppSizes.s16, color: kWarningColor),
      const SizedBox(width: AppSizes.s4),
      Flexible(child: MyText(
        text: '${provider.ratingAvg.toStringAsFixed(1)} '
            '(${provider.ratingCount} '
            '${provider.ratingCount == 1 ? 'Review' : 'Reviews'})',
        size: AppTextScale.label,
        color: kGreyTextColor,
        maxLines: 1,
        textOverflow: TextOverflow.ellipsis,
      )),
    ]);
  }
}

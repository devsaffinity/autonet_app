import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/providers_list_controller.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/screens/buyer/home/widgets/service_provider_card.dart'
    show brandsLabel;
import 'package:autonect/view/screens/buyer/providers/my_bookings.dart';
import 'package:autonect/view/screens/buyer/providers/new_booking.dart';
import 'package:autonect/view/screens/buyer/providers/provider_detail.dart';
import 'package:autonect/view/screens/chat/chat_home.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
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
    child: Obx(() {
      // A chip can select a service that is not a tab, so neither tab is
      // current. Fall back to the first rather than -1, which would render
      // as nothing selected.
      final raw = ProvidersListController.tabs.indexOf(c.service.value);
      final tab = raw < 0 ? 0 : raw;
      return Row(children: [
        for (final (i, label) in ProvidersListController.tabLabels.indexed) ...[
          if (i > 0) const SizedBox(width: AppSizes.s8),
          _ServiceTab(
            label: label,
            icon: i == 0
                ? Icons.electrical_services_rounded
                : Icons.memory_rounded,
            selected: tab == i,
            onTap: () => c.setService(ProvidersListController.tabs[i]),
          ),
        ],
        // Expanded and right-aligned rather than a Spacer: the picker needs a
        // bounded box to ellipsize inside, and at 320dp the two pills leave
        // it very little.
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _regionPicker(c.region.value),
          ),
        ),
      ]);
    }),
  );

  /// The comp's location pill, not a boxed dropdown.
  ///
  /// Keyed by INDEX, never by the region itself, for the same reason the
  /// requests filter is: 'All regions' carries a null value — the repository
  /// must OMIT the key rather than send it blank — and PopupMenuButton treats
  /// a null result as a DISMISSED menu, so a null-valued item is unselectable
  /// and choosing 'All regions' would silently leave the old filter applied.
  Widget _regionPicker(Region? selected) {
    final index = _regionOptions.indexWhere((o) => o.value == selected);
    return PopupMenuButton<int>(
      tooltip: 'Filter by region',
      initialValue: index,
      onSelected: (i) => c.setRegion(_regionOptions[i].value),
      color: kWhiteColor,
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      itemBuilder: (_) => [
        for (final (i, o) in _regionOptions.indexed)
          PopupMenuItem<int>(
            value: i,
            child: MyText(text: o.label, size: AppTextScale.body,
                color: i == index ? kSecondaryColor : kBlackColor,
                weight: i == index ? AppWeights.semibold : AppWeights.regular),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined, size: AppSizes.s16,
              color: kSecondaryColor),
          const SizedBox(width: AppSizes.s4),
          Flexible(
            child: MyText(
              // 'All' in the trigger, 'All regions' in the menu. The two pills
              // leave roughly 70dp here at 320dp, and a truncated 'All regi…'
              // says less than the short word does.
              text: selected?.label ?? 'All',
              size: AppTextScale.label,
              weight: AppWeights.semibold,
              color: kBlackColor,
              maxLines: 1,
              textOverflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, size: AppSizes.s20,
              color: kGreyTextColor),
        ],
      ),
    );
  }

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
  ///
  /// The selected service is read HERE, in the Obx closure itself — not down
  /// inside itemBuilder.
  ///
  /// Obx subscribes only to Rx values read SYNCHRONOUSLY inside its own
  /// closure. ListView's itemBuilder runs in a later build with no tracking
  /// zone installed, so reading c.service.value there registers no dependency:
  /// GetX sees an Obx with no subscriptions and throws, which in a release
  /// build paints a grey rectangle instead of the screen. Same trap as
  /// StateView.builder, which carries the same warning.
  Widget get _serviceChips => Obx(() {
    final selectedService = c.service.value;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s20, vertical: AppSizes.s8),
        itemCount: ProvidersListController.serviceChips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.s8),
        itemBuilder: (_, i) {
          final service = ProvidersListController.serviceChips[i];
          final selected = selectedService == service;
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
    );
  });

  /// The comp's calendar glyph, and it goes to MY BOOKINGS.
  ///
  /// That is the only calendar this screen can honestly lead to. A buyer
  /// browsing providers has no diary of their own here — what they have is
  /// the callouts they have already booked, which is exactly the question a
  /// calendar icon on a booking directory is being asked.
  ///
  /// IconButton rather than a bare Icon in the actions slot: it carries the
  /// 48dp target and the tooltip, and the tooltip IS the semantics label —
  /// an unlabelled glyph in an app bar is unreadable to a screen reader.
  Widget get _bookingsAction => IconButton(
    tooltip: 'My bookings',
    onPressed: () => Get.to(() => const MyBookingsPage()),
    icon: const Icon(Icons.calendar_month_rounded,
        size: AppSizes.s24, color: kSecondaryColor),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(
      title: 'Services',
      action: [_bookingsAction, const SizedBox(width: AppSizes.s8)],
    ),
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

/// The comp's tab pair: a filled pill for the active filter, an outlined one
/// for the other, each with its glyph.
///
/// Local rather than MyPillTabs, which is a segmented control on a tinted
/// track — a different component, and one that electrician bookings and the
/// supplier chips both still render. Restyling that would have changed two
/// screens nobody has reconciled against a comp.
class _ServiceTab extends StatelessWidget {
  const _ServiceTab({required this.label, required this.icon,
      required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MyRippleEffect(
    radius: AppSizes.radiusPill,
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
      decoration: BoxDecoration(
        color: selected ? kSecondaryColor : kWhiteColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: kSecondaryColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.s16,
              color: selected ? kWhiteColor : kSecondaryColor),
          const SizedBox(width: AppSizes.s4),
          MyText(text: label, size: AppTextScale.label,
              weight: AppWeights.semibold,
              color: selected ? kWhiteColor : kSecondaryColor),
        ],
      ),
    ),
  );
}

/// What the comp's '⋯' offers.
///
/// An enum, not an index. The requests filter and the region picker are
/// keyed by index because one of their entries carries a null value and
/// PopupMenuButton reads a null result as a DISMISSED menu; nothing here is
/// null, so the values can say what they mean.
enum _RowAction { profile, book, message }

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
      // Bottom gap ONLY. PagedListView already pads its scroll view by
      // AppSizes.DEFAULT, so a horizontal margin here inset the card twice
      // and left it visibly narrower than the search box and chips above.
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 48,
              width: 48,
              child: url != null &&
                      url.isNotEmpty &&
                      (url.startsWith('http://') || url.startsWith('https://'))
                  ? CommonImageView(
                      url: url,
                      cacheKey: provider.id,
                      height: 48,
                      width: 48,
                      radius: AppSizes.radiusPill,
                      fit: BoxFit.cover,
                      errorWidget: InitialsAvatar(
                        name: provider.fullName,
                        size: 48,
                        radius: AppSizes.radiusPill,
                      ),
                    )
                  : InitialsAvatar(
                      name: provider.fullName,
                      size: 48,
                      radius: AppSizes.radiusPill,
                    ),
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
            _kebab(),
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
            onTap: _openProfile,
          ),
        ],
      ),
    );
  }

  /// The card's primary destination, shared by the button and the menu.
  ///
  /// One method rather than two call sites, because a caller that overrode
  /// [onTap] means it for BOTH: the home strip opens this row inside its own
  /// flow, and a kebab that quietly bypassed that would be the same card
  /// going two places depending on which pixel was hit.
  void _openProfile() {
    if (onTap case final override?) {
      override();
      return;
    }
    Get.to(() => ProviderDetailPage(providerId: provider.id));
  }

  /// The comp's '⋯'.
  ///
  /// Three entries, and every one of them goes somewhere that exists today:
  /// the profile, the booking form seeded with this provider, and the
  /// Messages tab. Message does NOT yet open the thread for this provider —
  /// `POST /v1/conversations` accepts type OFFER only, so a booking has no
  /// conversation to open — and when it does, this is the one call site to
  /// change rather than a fourth entry to add.
  Widget _kebab() => PopupMenuButton<_RowAction>(
    tooltip: 'More actions',
    color: kWhiteColor,
    position: PopupMenuPosition.under,
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
    onSelected: (a) => switch (a) {
      _RowAction.profile => _openProfile(),
      _RowAction.book => Get.to(() => NewBookingPage(provider: provider)),
      _RowAction.message => Get.to(() => const ChatHomePage()),
    },
    itemBuilder: (_) => const [
      PopupMenuItem<_RowAction>(
        value: _RowAction.profile,
        child: _MenuRow(Icons.person_outline_rounded, 'View Profile'),
      ),
      PopupMenuItem<_RowAction>(
        value: _RowAction.book,
        child: _MenuRow(Icons.event_available_outlined, 'Book a callout'),
      ),
      PopupMenuItem<_RowAction>(
        value: _RowAction.message,
        child: _MenuRow(Icons.chat_bubble_outline_rounded, 'Message'),
      ),
    ],
    child: Container(
      height: 28,
      width: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
          color: kLightOrangeColor, shape: BoxShape.circle),
      child: const Icon(Icons.more_horiz_rounded, size: AppSizes.s16,
          color: kSecondaryColor),
    ),
  );

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

/// One line in the row's '⋯' menu.
///
/// Const-constructible on purpose: itemBuilder runs on every open, and a
/// const list is three widgets that are never rebuilt rather than three that
/// are allocated each time the menu is tapped.
class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: AppSizes.s16, color: kGreyTextColor),
      const SizedBox(width: AppSizes.s8),
      MyText(text: label, size: AppTextScale.body, color: kBlackColor),
    ],
  );
}

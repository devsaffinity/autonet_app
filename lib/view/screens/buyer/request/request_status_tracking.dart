import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/my_requests_controller.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/view/screens/buyer/detail/comparison.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/screens/buyer/request/request_detail.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:autonect/view/widget/search_field.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The comp's metadata glyphs, shipped as 16pt SVGs with #D94D2F baked in —
/// tag, clock, calendar, engine, in the order the card reads them.
const double _kChipIcon = 16;

/// `GET /v1/requests` — the buyer's own requests, with the four states and the
/// real pagination both coming from the shared [PagedListView].
class RequestStatusTrackingPage extends StatefulWidget {
  const RequestStatusTrackingPage({super.key});

  @override
  State<RequestStatusTrackingPage> createState() => _RequestListState();
}

class _RequestListState extends State<RequestStatusTrackingPage> {
  final MyRequestsController c = MyRequestsController.ensure();

  @override
  void initState() {
    super.initState();
    c.refreshFirst();
  }

  /// Deliberately OUTSIDE [PagedListView], for the same reason as the filter it
  /// now carries: its header slot renders only in the Data arm, so a search
  /// that matched nothing would take the box away and leave the buyer no way to
  /// clear it — or to widen the filter that emptied the list.
  ///
  /// Not wrapped in Obx and not given the query as its `controller` text: this
  /// field OWNS what is typed in it, and feeding the debounced value back would
  /// fight the cursor mid-word. Only the filter button inside it is reactive.
  Widget get _search => Padding(
    padding: const EdgeInsets.fromLTRB(
        AppSizes.s20, AppSizes.s8, AppSizes.s20, AppSizes.s4),
    child: SearchField(
      // NOT the comp's 'Search Vehicle'. The server matches partName,
      // partNumber and regNumber only (requests.service.ts) — nothing on the
      // vehicle — so that placeholder would promise a search where typing
      // 'Toyota' returns an empty list.
      hint: 'Search part, number or reg',
      marginBottom: 0,
      onChanged: c.setQuery,
      suffix: _filter,
    ),
  );

  /// The status filter, moved off its own row of pill tabs and into the search
  /// field, as the comp draws it.
  ///
  /// The funnel turns orange while a filter is applied. The comp has no such
  /// state, but a control that hides the current selection AND changes what the
  /// list contains has to say so somewhere: without it a buyer who filtered to
  /// Closed, left, and came back sees a short list and no reason for it.
  Widget get _filter => Obx(() {
    const options = MyRequestsController.filterOptions;
    final selected = c.filter.value;
    final index = options.indexWhere((o) => o.value == selected);
    // Keyed by INDEX, never by the status itself. 'All' carries a null value —
    // the repository has to OMIT `status` rather than send it blank, because
    // `?status=` is a 400 on this route — and PopupMenuButton cannot deliver a
    // null selection: it pops with the item's value and then treats a null
    // result as a DISMISSED menu, calling onCanceled instead of onSelected. So
    // a PopupMenuItem<RequestStatus?> whose value is null is unselectable, and
    // choosing 'All' would silently leave the previous filter applied.
    return PopupMenuButton<int>(
      tooltip: 'Filter by status',
      initialValue: index,
      onSelected: (i) => c.setFilter(options[i].value),
      color: kWhiteColor,
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      itemBuilder: (_) => [
        for (final (i, o) in options.indexed)
          PopupMenuItem<int>(
            value: i,
            child: MyText(text: o.label, size: AppTextScale.body,
                color: i == index ? kSecondaryColor : kBlackColor,
                weight: i == index
                    ? AppWeights.semibold : AppWeights.regular),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(
            left: AppSizes.s8, right: AppSizes.s16),
        child: Icon(Icons.filter_alt_outlined,
            color: selected == null ? kGreyTextColor : kSecondaryColor,
            size: AppSizes.s20),
      ),
    );
  });

  Widget get _list => Obx(() {
    final more = c.loadMoreError.value;
    return PagedListView<PartRequest>(
      state: c.state.value,
      loadingMore: c.loadingMore.value,
      loadMoreError: more == null ? null : userMessageFor(more),
      hasMore: c.hasMore,
      onLoadMore: c.loadMore,
      onRefresh: c.refreshFirst,
      emptyAction: MyButton(buttonText: 'Request a part',
          fontSize: AppTextScale.body,
          onTap: () => Get.to(() => const AddPartRequestPage())),
      itemBuilder: (_, r) => _RequestRow(request: r),
    );
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    // No '+' action, per the comp. This page is mounted in exactly one place —
    // nav_bar.dart's requests tab — so the centre FAB that opens the same
    // wizard is always on screen under it, and the empty state carries its own
    // 'Request a part' CTA for the one case where it is not enough.
    // Not const: GeneralAppBar's fields are non-final, so it has no const
    // constructor — the same reason its other call sites build it plainly.
    appBar: GeneralAppBar(
        hasBackButton: false, title: 'Request Status Tracking'),
    body: Column(children: [_search, Expanded(child: _list)]),
  );
}

/// Kept public and const-constructible so services.dart, chat_home.dart and
/// supplier_leads.dart — none of which this partition may edit — keep
/// compiling. It delegates to [SearchField]; it is not a second search input.
class MySearchBar extends StatelessWidget {
  const MySearchBar({super.key, this.onChanged, this.hint = 'Search'});

  final ValueChanged<String>? onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) =>
      SearchField(hint: hint, onChanged: onChanged ?? (_) {});
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final PartRequest request;

  /// The comp's '1 Day' was a fixture literal; the payload carries only
  /// createdAt. Safe across zones without converting: `difference` compares
  /// absolute instants, so a UTC createdAt against a local now is still right.
  static String _age(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    if (d.inMinutes >= 1) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  /// dd/MM/yyyy by hand — `intl` is deliberately not a dependency of this app.
  /// `toLocal()` matters here where it does not in [_age]: createdAt parses to
  /// UTC, and a request made at 00:30 BST would otherwise print yesterday.
  static String _date(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    final v = request.vehicle;
    final n = request.offerCount;
    return MyRippleEffect(
      radius: AppSizes.radiusMd,
      splashColor: kSecondaryColor.withValues(alpha: .1),
      onTap: () => Get.to(() => BuyerRequestDetailPage(requestId: request.id)),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSizes.s12),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // The left cluster is bounded so the make ellipsizes instead of
                // overflowing; the badge and the link keep their intrinsic
                // widths at every screen size.
                Expanded(child: Row(children: [
                  // make and model are BOTH nullable on Vehicle, and vehicle
                  // itself is null on a manual-reg request.
                  Flexible(child: MyText(text: v?.make ?? request.regNumber,
                      size: AppTextScale.label, weight: AppWeights.bold,
                      color: kGreyTextColor, maxLines: 1,
                      textOverflow: TextOverflow.ellipsis)),
                  const SizedBox(width: AppSizes.s8),
                  // Not in the comp, and kept anyway: this screen is called
                  // Request Status Tracking, the pill tabs that used to carry
                  // status are gone, and without it nothing on an unfiltered
                  // list says which requests are closed.
                  StatusBadge(label: request.status?.label ?? 'Unknown',
                      color: requestStatusColor(request.status)),
                ])),
                const SizedBox(width: AppSizes.s8),
                MyText(text: 'View Offers',
                    onTap: () => Get.to(() => ComparisonPage(request: request)),
                    size: AppTextScale.label, weight: AppWeights.semibold,
                    color: kSecondaryColor,
                    decoration: TextDecoration.underline),
              ]),
              MyText(text: v?.model ?? request.partName,
                  size: AppTextScale.body, weight: AppWeights.bold,
                  color: kBlackColor, maxLines: 1, paddingTop: AppSizes.s4,
                  textOverflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSizes.s8),
              // The comp's 2x2 metadata grid. The offer COUNT lives here, which
              // is what lets the link above shrink to a plain 'View Offers'.
              Row(children: [
                Expanded(child: _Chip(asset: Assets.imagesRsA,
                    label: n == 1 ? '1 Offer' : '$n Offers')),
                Expanded(child: _Chip(asset: Assets.imagesRsB,
                    label: _age(request.createdAt))),
              ]),
              const SizedBox(height: AppSizes.s8),
              Row(children: [
                Expanded(child: _Chip(asset: Assets.imagesRsC,
                    label: _date(request.createdAt))),
                Expanded(child: _Chip(asset: Assets.imagesRsD,
                    label: request.category.name)),
              ]),
            ],
          )),
          // The API carries no vehicle imagery — Vehicle has no image column
          // and request photos are unsigned S3 keys — so one static render.
          CommonImageView(imagePath: Assets.imagesCar1, width: 90,
              fit: BoxFit.contain),
        ]),
      ),
    );
  }
}

/// One metadata cell: the comp's 16pt glyph and a label that ellipsizes.
///
/// The label really can be long — a category is free text from the admin side
/// ('Body & Exterior' already overflows a half-width cell at 320dp) — so the
/// text is bounded rather than left to overflow the row it shares.
class _Chip extends StatelessWidget {
  const _Chip({required this.asset, required this.label});

  final String asset, label;

  @override
  Widget build(BuildContext context) => Row(children: [
    CommonImageView(svgPath: asset, height: _kChipIcon, width: _kChipIcon),
    Expanded(child: MyText(text: label, size: AppTextScale.label,
        color: kGreyTextColor, maxLines: 1,
        textOverflow: TextOverflow.ellipsis, paddingLeft: AppSizes.s8)),
  ]);
}

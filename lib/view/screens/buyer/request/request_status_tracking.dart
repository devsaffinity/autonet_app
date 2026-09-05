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
import 'package:autonect/view/widget/my_pill_tabs.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:autonect/view/widget/search_field.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  /// Deliberately OUTSIDE [PagedListView]: its header slot renders only in the
  /// Data arm, which would strand a buyer whose chosen filter came back empty.
  Widget get _filters => Obx(() {
    const options = MyRequestsController.filterOptions;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s20, AppSizes.s8, AppSizes.s20, AppSizes.s4),
      child: MyPillTabs(
        labels: [for (final o in options) o.label],
        selectedIndex: options.indexWhere((o) => o.value == c.filter.value),
        // 'All' carries a null value, so the repository OMITS `status` rather
        // than sending it blank — `?status=` is a 400 on this route.
        onChanged: (i) => c.setFilter(options[i].value),
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
    appBar: GeneralAppBar(
      hasBackButton: false,
      title: 'My Requests',
      action: [
        MyRippleEffect(
          radius: AppSizes.radiusPill,
          onTap: () => Get.to(() => const AddPartRequestPage()),
          splashColor: kSecondaryColor.withValues(alpha: .2),
          child: const Padding(padding: EdgeInsets.all(AppSizes.s8),
              child: Icon(Icons.add_rounded, color: kBlackColor,
                  size: AppSizes.s24)),
        ),
        const SizedBox(width: AppSizes.s12),
      ],
    ),
    body: Column(children: [_filters, Expanded(child: _list)]),
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

  /// The fixture's '1 Day' was a literal; the payload carries only createdAt.
  static String _age(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    if (d.inMinutes >= 1) return '${d.inMinutes}m ago';
    return 'Just now';
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
                // make and model are BOTH nullable on Vehicle, and vehicle
                // itself is null on a manual-reg request.
                Expanded(child: MyText(text: v?.make ?? request.regNumber,
                    size: AppTextScale.label, weight: AppWeights.bold,
                    color: kGreyTextColor, maxLines: 1,
                    textOverflow: TextOverflow.ellipsis)),
                StatusBadge(label: request.status?.label ?? 'Unknown',
                    color: requestStatusColor(request.status)),
              ]),
              MyText(text: v?.model ?? request.partName,
                  size: AppTextScale.body, weight: AppWeights.bold,
                  color: kBlackColor, maxLines: 1, paddingTop: AppSizes.s4,
                  textOverflow: TextOverflow.ellipsis),
              MyText(text: '${request.category.name} · ${_age(request.createdAt)}',
                  size: AppTextScale.label, color: kGreyTextColor,
                  paddingTop: AppSizes.s4),
              MyText(text: n == 1 ? '1 offer · View' : '$n offers · View',
                  onTap: () => Get.to(() => ComparisonPage(request: request)),
                  size: AppTextScale.label, weight: AppWeights.semibold,
                  color: kSecondaryColor, paddingTop: AppSizes.s8,
                  decoration: TextDecoration.underline),
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

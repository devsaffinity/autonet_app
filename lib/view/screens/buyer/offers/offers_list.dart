import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/buyer/offers_list_controller.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/view/screens/buyer/home/widgets/buyer_offer_card.dart';
import 'package:autonect/view/screens/buyer/request/request_detail.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Every offer the buyer has received — the screen behind the home feed's
/// View All, where home itself shows only the latest two.
///
/// It reuses [BuyerOfferCard] rather than growing a wider row of its own, the
/// way the provider directory does. The offer card is already full-width and
/// already vertical; the reason that one differs is that its home form is a
/// square tile in a horizontal strip, and this one's is not.
class BuyerOffersListPage extends StatefulWidget {
  const BuyerOffersListPage({super.key});

  @override
  State<BuyerOffersListPage> createState() => _BuyerOffersListPageState();
}

class _BuyerOffersListPageState extends State<BuyerOffersListPage> {
  final OffersListController c = OffersListController.ensure();

  @override
  void initState() {
    super.initState();
    c.refreshFirst();
  }

  /// The request, not the offer alone: accepting is a decision BETWEEN offers,
  /// and ComparisonPage is the screen that can make it. That screen needs the
  /// whole PartRequest and this feed carries only the joined projection, so the
  /// route goes through the detail page, which fetches it and can push onward.
  void _open(Offer o) {
    final id = o.request?.id;
    if (id == null) return;
    Get.to(() => BuyerRequestDetailPage(requestId: id));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(title: 'Offers'),
    body: Obx(() {
      final more = c.loadMoreError.value;
      return PagedListView<Offer>(
        state: c.state.value,
        loadingMore: c.loadingMore.value,
        loadMoreError: more == null ? null : userMessageFor(more),
        hasMore: c.hasMore,
        onLoadMore: c.loadMore,
        onRefresh: c.refreshFirst,
        itemBuilder: (_, o) => Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.s12),
          child: BuyerOfferCard(offer: o, onTap: () => _open(o)),
        ),
      );
    }),
  );
}

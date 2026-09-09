import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/providers_list_controller.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/view/screens/buyer/home/widgets/service_provider_card.dart'
    show brandsLabel;
import 'package:autonect/view/screens/buyer/providers/provider_detail.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:autonect/view/widget/search_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The full provider directory — the comp's Services screen.
///
/// The comp's Electricians/Coders tab pair is NOT here. Both would read the
/// same table: the schema has one provider type, ElectricianProfile, and no
/// column that separates a coder from an electrician. `BookingServiceType`
/// does carry ECU_CODING, so the split is probably meant to be a SERVICE
/// filter rather than two populations — but that is a product decision, and
/// two tabs returning identical lists is worse than one honest list.
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

  /// Outside [PagedListView] for the same reason as on My Requests: its header
  /// slot renders only in the Data arm, so a search matching nothing would take
  /// the box away and leave no way to clear it.
  Widget get _search => Padding(
    padding: const EdgeInsets.fromLTRB(
        AppSizes.s20, AppSizes.s8, AppSizes.s20, 0),
    child: SearchField(
      hint: 'Search providers or area',
      marginBottom: 0,
      onChanged: c.setQuery,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(title: 'Service Providers'),
    body: Column(children: [
      _search,
      const SizedBox(height: AppSizes.s8),
      Expanded(child: Obx(() {
        final more = c.loadMoreError.value;
        return PagedListView<ServiceProvider>(
          state: c.state.value,
          loadingMore: c.loadingMore.value,
          loadMoreError: more == null ? null : userMessageFor(more),
          hasMore: c.hasMore,
          onLoadMore: c.loadMore,
          onRefresh: c.refreshFirst,
          itemBuilder: (_, p) => _ProviderRow(provider: p),
        );
      })),
    ]),
  );
}

/// A wide row, not the home card: a vertical list has the width for the
/// location and rating to sit beside the name rather than stacked under it.
class _ProviderRow extends StatelessWidget {
  const _ProviderRow({required this.provider});

  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) {
    final brands = brandsLabel(provider.brands);
    final url = provider.avatarUrl;
    return MyRippleEffect(
      radius: AppSizes.radiusMd,
      splashColor: kSecondaryColor.withValues(alpha: .1),
      onTap: () =>
          Get.to(() => ProviderDetailPage(providerId: provider.id)),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSizes.s12),
        child: Row(children: [
          SizedBox(
            height: 56,
            width: 56,
            child: url != null && url.isNotEmpty
                ? CommonImageView(url: url, cacheKey: provider.id,
                    height: 56, width: 56, radius: AppSizes.radiusMd,
                    fit: BoxFit.cover)
                : CommonImageView(imagePath: Assets.imagesProfileImage,
                    height: 56, width: 56, radius: AppSizes.radiusMd,
                    fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(text: provider.fullName, size: AppTextScale.body,
                  weight: AppWeights.bold, color: kBlackColor,
                  maxLines: 1, textOverflow: TextOverflow.ellipsis),
              if (brands.isNotEmpty) ...[
                const SizedBox(height: AppSizes.s4),
                MyText(text: brands, size: AppTextScale.label,
                    color: kGreyTextColor, maxLines: 1,
                    textOverflow: TextOverflow.ellipsis),
              ],
              if (provider.location case final l? when l.isNotEmpty) ...[
                const SizedBox(height: AppSizes.s4),
                Row(children: [
                  const Icon(Icons.place_outlined, size: AppSizes.s12,
                      color: kGreyTextColor),
                  const SizedBox(width: AppSizes.s4),
                  Flexible(child: MyText(text: l, size: AppTextScale.caption,
                      color: kGreyTextColor, maxLines: 1,
                      textOverflow: TextOverflow.ellipsis)),
                ]),
              ],
            ],
          )),
          if (provider.isRated) ...[
            const SizedBox(width: AppSizes.s8),
            Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, size: AppSizes.s16,
                  color: kWarningColor),
              MyText(text: provider.ratingAvg.toStringAsFixed(1),
                  size: AppTextScale.label, weight: AppWeights.semibold,
                  color: kBlackColor),
              MyText(text: '(${provider.ratingCount})',
                  size: AppTextScale.caption, color: kGreyTextColor),
            ]),
          ],
        ]),
      ),
    );
  }
}

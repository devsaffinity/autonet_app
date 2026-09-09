import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/provider_detail_controller.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/view/screens/buyer/home/widgets/service_provider_card.dart'
    show brandsLabel;
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One approved provider — `GET /v1/providers/{id}`.
///
/// THIS IS THE COMP'S EXPERT PROFILE, MINUS EVERYTHING THE API CANNOT FEED.
/// The design also shows an expertise write-up, a '1240+ Vehicles Serviced'
/// counter, a four-tile Specializations grid and client testimonials. None of
/// those exist as data:
///
///   * ElectricianProfile carries no bio, no service counter and no
///     specialization list — only fullName, brands, location, region,
///     yearsExperience and the rating pair.
///   * Review.orderId is REQUIRED and points at Order, and an Order is created
///     by accepting a parts Offer. A booking cannot produce one, so an
///     electrician can never accumulate a testimonial — or a rating — through
///     the product as it stands today.
///
/// Rendering those sections from literals would put invented numbers in front
/// of a buyer choosing who to let near their car, so they are absent until
/// there is a column behind them.
class ProviderDetailPage extends StatefulWidget {
  const ProviderDetailPage({super.key, required this.providerId});

  final String providerId;

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  late final ProviderDetailController _c;

  @override
  void initState() {
    super.initState();
    _c = ProviderDetailController.ensure();
    _c.load(widget.providerId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(title: 'Provider'),
    body: Obx(() => StateView<ServiceProvider>(
      state: _c.provider.value,
      onRetry: () => _c.load(widget.providerId),
      builder: (_, p) => ListView(
        padding: AppSizes.DEFAULT,
        children: [_header(p), const SizedBox(height: AppSizes.s20), _facts(p)],
      ),
    )),
  );

  Widget _header(ServiceProvider p) {
    final url = p.avatarUrl;
    return Column(
      children: [
        SizedBox(
          height: 96,
          width: 96,
          child: url != null && url.isNotEmpty
              ? CommonImageView(url: url, cacheKey: p.id, height: 96, width: 96,
                  radius: AppSizes.radiusLg, fit: BoxFit.cover)
              : CommonImageView(imagePath: Assets.imagesProfileImage,
                  height: 96, width: 96, radius: AppSizes.radiusLg,
                  fit: BoxFit.cover),
        ),
        const SizedBox(height: AppSizes.s12),
        MyText(text: p.fullName, size: AppTextScale.title,
            weight: AppWeights.bold, color: kBlackColor,
            textAlign: TextAlign.center),
        if (p.isRated) ...[
          const SizedBox(height: AppSizes.s4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.star_rounded, size: AppSizes.s20,
                color: kWarningColor),
            const SizedBox(width: AppSizes.s4),
            // The COUNT ships with the average, unlike the home card where
            // there is no room: 4.8 from three reviews and 4.8 from three
            // hundred are different claims, and this is the screen where a
            // buyer is actually deciding.
            MyText(
              text: '${p.ratingAvg.toStringAsFixed(1)}/5.0  '
                  '(${p.ratingCount} review${p.ratingCount == 1 ? '' : 's'})',
              size: AppTextScale.body, color: kGreyTextColor,
            ),
          ]),
        ],
      ],
    );
  }

  /// Only the rows that have a value. A provider who gave no location and no
  /// years of experience renders a shorter card, never a column of dashes.
  Widget _facts(ServiceProvider p) {
    final brands = brandsLabel(p.brands);
    final rows = <(IconData, String, String)>[
      if (p.location case final l? when l.isNotEmpty)
        (Icons.place_outlined, 'Location', l),
      if (p.region?.label case final r?) (Icons.map_outlined, 'Region', r),
      if (p.yearsExperience case final y?)
        (Icons.workspace_premium_outlined, 'Experience',
            '$y year${y == 1 ? '' : 's'}'),
      if (brands.isNotEmpty) (Icons.directions_car_outlined, 'Brands', brands),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: AppStyling().myShadowStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, label, value) in rows) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: AppSizes.s20, color: kSecondaryColor),
              const SizedBox(width: AppSizes.s12),
              SizedBox(
                width: 92,
                child: MyText(text: label, size: AppTextScale.label,
                    color: kGreyTextColor),
              ),
              Expanded(
                child: MyText(text: value, size: AppTextScale.body,
                    weight: AppWeights.medium, color: kBlackColor),
              ),
            ]),
            if (rows.last.$2 != label) const SizedBox(height: AppSizes.s12),
          ],
        ],
      ),
    );
  }
}

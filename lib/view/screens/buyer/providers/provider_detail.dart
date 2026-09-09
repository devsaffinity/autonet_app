import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/provider_detail_controller.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/view/screens/buyer/providers/new_booking.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One approved provider — the comp's Expert profile.
///
/// EVERY SECTION IS OMITTED WHEN ITS DATA IS ABSENT rather than rendered
/// blank. A provider who registered before the profile columns existed has no
/// headline, no bio and no skills, and this is the page a buyer reads to
/// decide who to let near their car — an empty 'Expertise Profile' heading
/// over nothing is worse than no heading at all.
///
/// Two things in the comp are still missing, and both are absences of DATA
/// rather than of effort:
///   * 'EXPERT VERIFIED' — the schema has `approved`, but this route can only
///     ever return approved providers, so a badge on every one says nothing.
///   * 'Chat Now' — a conversation can only be opened against an OFFER.
///     ConversationType.BOOKING exists in the enum but nothing implements it,
///     and the Flutter chat screen is a static mock with no repository. A
///     button opening a fake inbox is worse than no button.
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
    appBar: GeneralAppBar(title: 'Expert profile'),
    body: Obx(() {
      // Read INSIDE the closure. An Rx read from a builder that runs later
      // registers no dependency and leaves the subtree frozen — or throws,
      // which a release build paints as a grey rectangle.
      final reviews = _c.reviews.toList(growable: false);
      return StateView<ServiceProvider>(
        state: _c.provider.value,
        onRetry: () => _c.load(widget.providerId),
        builder: (_, p) => ListView(
          padding: AppSizes.DEFAULT,
          children: [
            _header(p),
            if (p.bio case final bio? when bio.isNotEmpty)
              _section('Expertise Profile',
                  MyText(text: bio, size: AppTextScale.body,
                      color: kGreyTextColor)),
            if (p.vehiclesServiced case final n? when n > 0) _servedCounter(n),
            if (p.services.isNotEmpty) _specializations(p),
            if (p.brands.isNotEmpty) _brands(p),
            _testimonials(reviews),
            const SizedBox(height: AppSizes.s24),
            MyButton(
              buttonText: 'Book ${_primaryServiceLabel(p)}',
              radius: AppSizes.radiusMd,
              // The whole provider travels, not just the id: the booking
              // screen needs their region and services to build a valid
              // request, and re-fetching what this screen already holds
              // would be a round trip for nothing.
              onTap: () => Get.to(() => NewBookingPage(provider: p)),
            ),
            const SizedBox(height: AppSizes.s32),
          ],
        ),
      );
    }),
  );

  /// 'Book Diagnostic' in the comp — but taken from what THIS provider
  /// offers, so a coder is not invited to book a diagnostic.
  String _primaryServiceLabel(ServiceProvider p) =>
      p.services.isEmpty ? 'a callout' : p.services.first.label;

  Widget _header(ServiceProvider p) {
    final url = p.avatarUrl;
    return Column(children: [
      SizedBox(
        height: 96,
        width: 96,
        child: url != null && url.isNotEmpty
            ? CommonImageView(url: url, cacheKey: p.id, height: 96, width: 96,
                radius: AppSizes.radiusLg, fit: BoxFit.cover)
            : InitialsAvatar(name: p.fullName, size: 96,
                radius: AppSizes.radiusLg),
      ),
      const SizedBox(height: AppSizes.s12),
      MyText(text: p.fullName.toUpperCase(), size: AppTextScale.title,
          weight: AppWeights.bold, color: kSecondaryColor,
          textAlign: TextAlign.center),
      if (p.headline case final h? when h.isNotEmpty) ...[
        const SizedBox(height: AppSizes.s4),
        MyText(text: h, size: AppTextScale.body, color: kBlackColor,
            textAlign: TextAlign.center),
      ],
      const SizedBox(height: AppSizes.s8),
      // Rating and experience on one line as the comp draws them, with the
      // separator rendered only where both sides exist.
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (p.isRated) ...[
            const Icon(Icons.star_rounded, size: AppSizes.s16,
                color: kWarningColor),
            const SizedBox(width: AppSizes.s4),
            MyText(text: p.ratingAvg.toStringAsFixed(1),
                size: AppTextScale.body, weight: AppWeights.semibold,
                color: kSecondaryColor),
          ] else
            MyText(text: 'New', size: AppTextScale.body,
                weight: AppWeights.semibold, color: kGreyTextColor),
          if (p.yearsExperience case final y?) ...[
            MyText(text: '   |   ', size: AppTextScale.body,
                color: kGreyTextColor),
            MyText(text: '$y Year${y == 1 ? '' : 's'} Experience',
                size: AppTextScale.body, color: kGreyTextColor),
          ],
        ],
      ),
    ]);
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.s20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: title, size: AppTextScale.subtitle,
          weight: AppWeights.bold, color: kBlackColor),
      const SizedBox(height: AppSizes.s8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.s16),
        decoration: AppStyling().myShadowStyle(),
        child: child,
      ),
    ]),
  );

  /// The comp's '1240+ Vehicles Serviced'. The '+' is the comp's and it is
  /// honest: the column is a milestone a provider states, not a live count.
  Widget _servedCounter(int n) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.s16),
    child: Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: AppStyling().myShadowStyle(),
      child: Row(children: [
        const Icon(Icons.directions_car_filled_outlined,
            size: AppSizes.s24, color: kSecondaryColor),
        const SizedBox(width: AppSizes.s12),
        Expanded(child: MyText(text: '$n+ Vehicles Serviced',
            size: AppTextScale.subtitle, weight: AppWeights.bold,
            color: kBlackColor)),
      ]),
    ),
  );

  /// The comp's tile grid, driven by what the provider ACTUALLY offers rather
  /// than four hardcoded tiles. Each callout carries its own label and blurb
  /// on the enum, so this renders one to five tiles honestly.
  Widget _specializations(ServiceProvider p) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.s20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: 'Specializations', size: AppTextScale.subtitle,
          weight: AppWeights.bold, color: kBlackColor),
      const SizedBox(height: AppSizes.s8),
      // Wrap, not GridView: an odd number of services leaves a hole in a
      // fixed 2-column grid, and a nested scrollable inside a ListView needs
      // shrinkWrap plus a physics override before it behaves.
      Wrap(
        spacing: AppSizes.s12,
        runSpacing: AppSizes.s12,
        children: [for (final s in p.services) _specializationTile(context, s)],
      ),
    ]),
  );

  Widget _specializationTile(BuildContext context, BookingServiceType s) {
    // Two per row at the page's content width, minus the gap between them.
    final available =
        MediaQuery.sizeOf(context).width - AppSizes.s20 * 2 - AppSizes.s12;
    final width = available / 2;
    return Container(
      width: width < 120 ? 120 : width,
      padding: const EdgeInsets.all(AppSizes.s12),
      decoration: AppStyling().myShadowStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.build_circle_outlined, size: AppSizes.s24,
              color: kSecondaryColor),
          const SizedBox(height: AppSizes.s8),
          MyText(text: s.label, size: AppTextScale.body,
              weight: AppWeights.semibold, color: kBlackColor,
              maxLines: 1, textOverflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSizes.s4),
          MyText(text: s.blurb, size: AppTextScale.caption,
              color: kGreyTextColor, maxLines: 2,
              textOverflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _brands(ServiceProvider p) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.s20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: 'Brands Supported', size: AppTextScale.subtitle,
          weight: AppWeights.bold, color: kBlackColor),
      const SizedBox(height: AppSizes.s8),
      Wrap(
        spacing: AppSizes.s8,
        runSpacing: AppSizes.s8,
        children: [
          for (final b in p.brands)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s12, vertical: AppSizes.s8),
              decoration: BoxDecoration(
                color: kMutedSurfaceColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: MyText(text: b, size: AppTextScale.label,
                  color: kBlackColor),
            ),
        ],
      ),
    ]),
  );

  /// Real reviews, from `GET /v1/reviews?targetId=`.
  ///
  /// Possible only since Review stopped requiring an orderId: an Order comes
  /// from a parts offer, so before that an electrician could never be
  /// reviewed at all. Until a booking runs to COMPLETED and somebody reviews
  /// it, this section correctly reads as empty rather than showing invented
  /// quotes attributed to named people.
  Widget _testimonials(List<Review> reviews) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.s20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MyText(text: 'Client Testimonials', size: AppTextScale.subtitle,
          weight: AppWeights.bold, color: kBlackColor),
      const SizedBox(height: AppSizes.s8),
      if (reviews.isEmpty)
        MyText(text: 'No reviews yet — nobody has rated this provider.',
            size: AppTextScale.body, color: kGreyTextColor)
      else
        for (final r in reviews) _testimonial(r),
    ]),
  );

  Widget _testimonial(Review r) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: AppSizes.s12),
    padding: const EdgeInsets.all(AppSizes.s16),
    decoration: AppStyling().myShadowStyle(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        // author is nullable on the wire; the initials tile falls back to a
        // glyph on an empty name rather than rendering a blank square.
        InitialsAvatar(name: r.author?.name ?? '', size: 36,
            radius: AppSizes.radiusPill),
        const SizedBox(width: AppSizes.s8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(text: r.author?.name ?? 'A buyer', size: AppTextScale.body,
                weight: AppWeights.semibold, color: kBlackColor,
                maxLines: 1, textOverflow: TextOverflow.ellipsis),
            Row(children: [
              for (var star = 1; star <= 5; star++)
                Icon(
                  star <= r.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: AppSizes.s12,
                  color: star <= r.rating ? kWarningColor : kGreyTextColor,
                ),
              const SizedBox(width: AppSizes.s8),
              MyText(text: formatDayMonthYear(r.createdAt),
                  size: AppTextScale.caption, color: kGreyTextColor),
            ]),
          ],
        )),
      ]),
      // text is optional — a buyer can leave stars without writing anything,
      // and the card must not collapse to a name and a date with a gap.
      if (r.text case final t? when t.isNotEmpty) ...[
        const SizedBox(height: AppSizes.s8),
        MyText(text: '"$t"', size: AppTextScale.body, color: kGreyTextColor),
      ],
    ]),
  );
}

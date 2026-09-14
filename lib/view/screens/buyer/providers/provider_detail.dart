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
import 'package:autonect/view/screens/chat/chat_home.dart';
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
/// 'CHAT NOW' OPENS THE MESSAGES TAB, NOT THIS PROVIDER'S THREAD, and that
/// is a limit of the API rather than of this screen: `POST /v1/conversations`
/// accepts type OFFER only, so a booking has no conversation to open.
/// ConversationType.BOOKING exists in the schema and the DTO does not accept
/// it yet. When it does, [_chat] is the single call site to point at the
/// thread — the button, its place in the comp and its label do not move.
class ProviderDetailPage extends StatefulWidget {
  const ProviderDetailPage({super.key, required this.providerId});

  final String providerId;

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

/// The tinted square behind the vehicles-serviced glyph.
const double _kGlyphTile = 40;

/// A glyph per callout, so the comp's tile grid reads as four different
/// things rather than the same icon four times.
///
/// Exhaustive on purpose — no default arm. Adding a sixth BookingServiceType
/// should fail to compile here and be given a glyph, not silently inherit a
/// spanner.
IconData _serviceIcon(BookingServiceType s) => switch (s) {
  BookingServiceType.diagnostic => Icons.troubleshoot_rounded,
  BookingServiceType.ecuCoding => Icons.memory_rounded,
  BookingServiceType.installation => Icons.settings_input_component_rounded,
  BookingServiceType.repair => Icons.build_rounded,
  BookingServiceType.inspection => Icons.fact_check_outlined,
};

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
            if (p.bio case final bio? when bio.isNotEmpty) _expertise(bio),
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
            const SizedBox(height: AppSizes.s12),
            // The comp's outlined second action. Same height and radius as
            // the primary, inverted colours — a second FILLED button beside
            // it would make the buyer choose between two equals, and booking
            // is the one this page exists to get to.
            MyButton(
              buttonText: 'Chat Now',
              radius: AppSizes.radiusMd,
              backgroundColor: kWhiteColor,
              fontColor: kSecondaryColor,
              outlineColor: kSecondaryColor,
              onTap: _chat,
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

  /// The Messages tab. See the class doc: the thread for THIS provider is
  /// not openable until the chat DTO accepts a booking as a context.
  void _chat() => Get.to(() => const ChatHomePage());

  Widget _header(ServiceProvider p) {
    final url = p.avatarUrl;
    return Column(children: [
      SizedBox(
        height: 96,
        width: 96,
        child: url != null &&
                url.isNotEmpty &&
                (url.startsWith('http://') || url.startsWith('https://'))
            ? CommonImageView(
                url: url,
                cacheKey: p.id,
                height: 96,
                width: 96,
                radius: AppSizes.radiusLg,
                fit: BoxFit.cover,
                errorWidget: InitialsAvatar(
                  name: p.fullName,
                  size: 96,
                  radius: AppSizes.radiusLg,
                ),
              )
            : InitialsAvatar(
                name: p.fullName,
                size: 96,
                radius: AppSizes.radiusLg,
              ),
      ),
      const SizedBox(height: AppSizes.s8),
      // EXPERT VERIFIED.
      //
      // I argued against this once, on the grounds that /v1/providers only
      // ever returns approved providers so the badge is true of everybody.
      // That was wrong: the BUYER does not know the route is filtered, and to
      // them it says this provider cleared KYC — which is exactly what
      // `approved` means and exactly what they are weighing up.
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s8, vertical: AppSizes.s4),
        decoration: BoxDecoration(
          color: kMutedSurfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified_rounded, size: AppSizes.s12,
              color: kSecondaryColor),
          const SizedBox(width: AppSizes.s4),
          MyText(text: 'EXPERT VERIFIED', size: AppTextScale.caption,
              weight: AppWeights.bold, color: kGreyTextColor,
              letterSpacing: 0.5),
        ]),
      ),
      const SizedBox(height: AppSizes.s8),
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
      // Where they work. Not in the comp's profile header, but it is the
      // first thing a buyer wants after 'are they any good' — and the booking
      // screen shows it as the Service Location, so the two agree.
      if (p.location case final l? when l.isNotEmpty) ...[
        const SizedBox(height: AppSizes.s8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.place_outlined, size: AppSizes.s16,
              color: kGreyTextColor),
          const SizedBox(width: AppSizes.s4),
          MyText(text: l, size: AppTextScale.body, color: kGreyTextColor),
        ]),
      ],
    ]);
  }

  /// The comp's Expertise Profile: the heading sits INSIDE the card, in the
  /// brand colour, rather than above it in black like every other section.
  ///
  /// That is the comp's own distinction and it is a real one — the other
  /// headings label a LIST that continues past the card, while this one
  /// titles the paragraph it is printed on.
  Widget _expertise(String bio) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.s20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: AppStyling().myShadowStyle(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MyText(text: 'Expertise Profile', size: AppTextScale.body,
            weight: AppWeights.semibold, color: kSecondaryColor),
        const SizedBox(height: AppSizes.s8),
        MyText(text: bio, size: AppTextScale.body, color: kGreyTextColor,
            lineHeight: 1.5),
      ]),
    ),
  );

  /// The comp's '1240+ / Vehicles Serviced'. The '+' is the comp's and it is
  /// honest: the column is a milestone a provider states, not a live count.
  ///
  /// TWO LINES, behind a tinted tile, which is the comp's arrangement and
  /// the better one: the number is the claim and the noun is only its unit,
  /// so setting them at one weight on one line made the buyer read the whole
  /// string to find the figure.
  Widget _servedCounter(int n) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.s16),
    child: Container(
      padding: const EdgeInsets.all(AppSizes.s12),
      decoration: AppStyling().myShadowStyle(),
      child: Row(children: [
        Container(
          height: _kGlyphTile,
          width: _kGlyphTile,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kLightOrangeColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: const Icon(Icons.directions_car_filled_rounded,
              size: AppSizes.s20, color: kSecondaryColor),
        ),
        const SizedBox(width: AppSizes.s12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(text: '$n+', size: AppTextScale.subtitle,
                weight: AppWeights.bold, color: kBlackColor),
            MyText(text: 'Vehicles Serviced', size: AppTextScale.label,
                color: kGreyTextColor),
          ],
        )),
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
          Icon(_serviceIcon(s), size: AppSizes.s24, color: kSecondaryColor),
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
        if (r.author?.avatarUrl != null &&
            r.author!.avatarUrl!.isNotEmpty &&
            (r.author!.avatarUrl!.startsWith('http://') ||
                r.author!.avatarUrl!.startsWith('https://')))
          CommonImageView(
            url: r.author!.avatarUrl,
            width: 36,
            height: 36,
            radius: AppSizes.radiusPill,
            fit: BoxFit.cover,
            errorWidget: InitialsAvatar(
              name: r.author?.name ?? '',
              size: 36,
              radius: AppSizes.radiusPill,
            ),
          )
        else
          InitialsAvatar(
            name: r.author?.name ?? '',
            size: 36,
            radius: AppSizes.radiusPill,
          ),
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

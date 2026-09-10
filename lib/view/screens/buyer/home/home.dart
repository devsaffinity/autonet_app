import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/buyer_home_controller.dart';
import 'package:autonect/controller/buyer/buyer_offers_controller.dart';
import 'package:autonect/controller/buyer/notifications_controller.dart';
import 'package:autonect/controller/buyer/service_providers_controller.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/view/screens/buyer/detail/comparison.dart';
import 'package:autonect/view/screens/buyer/home/widgets/active_request_card.dart';
import 'package:autonect/view/screens/buyer/home/widgets/buyer_offer_card.dart';
import 'package:autonect/view/screens/buyer/home/widgets/service_provider_card.dart';
import 'package:autonect/view/screens/buyer/providers/provider_detail.dart';
import 'package:autonect/view/screens/buyer/providers/providers_list.dart';
import 'package:autonect/view/screens/buyer/notifications/notifications_page.dart';
import 'package:autonect/view/screens/buyer/offers/offers_list.dart';
import 'package:autonect/view/screens/buyer/profile/buyer_profile_creation_page.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/search_field.dart';
import 'package:autonect/view/widget/section_header.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The buyer's home.
///
/// Stateful because BuyerNavBar mounts it as a `const` screen: nothing upstream
/// can fetch on its behalf, so it owns its own load.
///
/// The three sections are backed by three independent controllers, so one
/// failing read degrades its own strip and leaves the other two alone.
///
/// Service Providers is real as of `GET /v1/providers`. It spent phase 4 out
/// of the design precisely because no provider listing route existed — only
/// `POST /electrician/registration`, a write — and a fixture card deck would
/// have been furniture, not a feature.
class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  late final BuyerHomeController _c;
  late final BuyerOffersController _offers;
  late final ServiceProvidersController _providers;
  // Permanent, so the badge is already correct the moment Home builds rather
  // than only after the list screen has been visited once.
  final NotificationsController _notifications =
      NotificationsController.ensure();
  final ProfileController _profile = ProfileController.ensure();

  @override
  void initState() {
    super.initState();
    _c = BuyerHomeController.ensure();
    _c.load();
    _offers = BuyerOffersController.ensure();
    _offers.load();
    _providers = ServiceProvidersController.ensure();
    _providers.load();
    // Badge only — a one-row read, not the whole list. Home should not pay for
    // a page the buyer may never open.
    _notifications.refreshUnread();
    // The presigned avatarUrl expires, so it is re-read rather than cached.
    _profile.load();
  }

  /// Straight off the session — `GET /v1/me` is phase 2, and the token payload
  /// already carries the name that the 'Lorem Ipsum' literal stood in for.
  String get _name => Get.find<TokenStore>().user?.name ?? 'there';

  void _openRequests() => RoleShell.maybeOf(context)?.goTo(1);

  void _openNotifications() => Get.to(() => const NotificationsPage());

  /// Profile is pushed on top of the shell rather than being a tab, so it
  /// cannot reach the shell itself — `RoleShell.maybeOf` returns null from a
  /// routed page. We capture the shell HERE, where it is still an ancestor, and
  /// hand it down as a closure. Without this, Profile's 'My Requests' tile is a
  /// dead control.
  void _openProfile() async {
    await Get.to(
      () => const BuyerProfileCreationPage(isInitialSetup: false),
    );
    await _profile.load();
    if (mounted) setState(() {});
  }

  /// Both sections, together, so one pull refreshes the whole screen. They are
  /// separate controllers precisely so a failure in one does not blank the
  /// other, and `wait` — not `then` — is what keeps that true here: the
  /// spinner stays until both have answered, whichever of them failed.
  Future<void> _refresh() =>
      Future.wait([_c.load(), _offers.load(), _providers.load()]);

  /// Comparison, not the offer on its own: accepting is a decision between
  /// offers, and ComparisonPage is the screen that can make it. It needs the
  /// whole [PartRequest] and the feed carries only the six-field projection, so
  /// this routes to the request detail, which fetches it and can push onward.
  /// Tapping an offer opens the Offers / Comparison flow for that request,
  /// matching the Figma comp.
  void _openOffer(Offer o) {
    final id = o.request?.id;
    if (id == null) return;
    Get.to(() => ComparisonPage(requestId: id));
  }

  void _openProviders() => Get.to(() => const ProvidersListPage());

  /// The whole feed, paged. Home shows the latest two; this is the rest.
  void _openOffers() => Get.to(() => const BuyerOffersListPage());

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: AppSizes.DEFAULT,
          children: [
            _header(),
            const SizedBox(height: AppSizes.s24),
            // The search bar is back, and real: `GET /v1/requests` now takes a
            // `q` over partName / partNumber / regNumber, which is why the last
            // one was deleted and this one is not a decoration. It filters the
            // carousel below, server-side, across every open request — not just
            // the five on screen.
            //
            // Still no 'Request a Part' button: the wizard is the nav bar's
            // centre FAB, one entry point rather than two.
            SearchField(
              hint: 'Search your requests',
              marginBottom: AppSizes.s16,
              onChanged: _c.setQuery,
            ),
            SectionHeader(title: 'Active Requests', onAction: _openRequests),
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
            // A REAL offers feed now: `GET /v1/buyer/offers` returns every live
            // offer across all of this buyer's requests with the request and
            // supplier joined in, so these cards carry the comp's price instead
            // of the offer COUNT the old derived-from-offerCount list showed.
            SectionHeader(title: 'Offers', onAction: _openOffers),
            // minHeight, not height: the loading spinner and the empty panel
            // both shrink-wrap in an unbounded ListView slot, so without a
            // floor the section is a few pixels tall while it loads and the
            // page jumps when the cards land. A Data arm taller than the floor
            // simply ignores it.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120),
              child: Obx(() => StateView<List<Offer>>(
              state: _offers.offers.value,
              onRetry: _offers.load,
              emptyTitle: 'No offers yet',
              // A short vertical list, not a carousel: these need the buyer's
              // attention, and a horizontal strip hides how many there are
              // behind a swipe.
              builder: (_, items) => Column(
                children: [
                  for (final o in items) ...[
                    BuyerOfferCard(offer: o, onTap: () => _openOffer(o)),
                    const SizedBox(height: AppSizes.s12),
                  ],
                ],
              ),
              )),
            ),
            const SizedBox(height: AppSizes.s24),
            // Service Providers — the approved electrician directory.
            //
            // This section could not exist until now: the backend had no
            // provider listing at all, only POST /electrician/registration,
            // which is a write. GET /v1/providers is what made it real.
            SectionHeader(title: 'Service Providers', onAction: _openProviders),
            SizedBox(
              // Scales with the system font — the card's three text lines grow
              // where its avatar and button do not.
              height: serviceProviderCardHeight(context),
              child: Obx(() => StateView<List<ServiceProvider>>(
                state: _providers.providers.value,
                onRetry: _providers.load,
                emptyTitle: 'No providers yet',
                builder: (_, items) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSizes.s12),
                  itemBuilder: (_, i) => ServiceProviderCard(
                    provider: items[i],
                    onTap: () => Get.to(
                        () => ProviderDetailPage(providerId: items[i].id)),
                  ),
                ),
              )),
            ),
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

  /// Both side slots are the SAME fixed width so the greeting between them is
  /// optically centred. Sizing them to their contents would centre the greeting
  /// in the leftover space instead, pushing it off-centre by the difference.
  static const double _kHeaderSlot = 56;

  Widget _header() => Row(
    children: [
      SizedBox(
        width: _kHeaderSlot,
        child: Align(alignment: Alignment.centerLeft, child: _avatarButton()),
      ),
      // A centred column between two fixed boxes has LESS room than a
      // left-aligned one, not more, so the ellipsis here is load-bearing: real
      // display names off the token routinely overrun 200px.
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MyText(text: 'Hello,', size: AppTextScale.label,
                color: kGreyTextColor, textAlign: TextAlign.center),
            MyText(text: _name, size: AppTextScale.subtitle,
                weight: AppWeights.bold, color: kBlackColor,
                maxLines: 1, textOverflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
          ],
        ),
      ),
      SizedBox(
        width: _kHeaderSlot,
        child: Align(alignment: Alignment.centerRight, child: _bellButton()),
      ),
    ],
  );

  /// Profile's only entry point now that it is not a tab.
  ///
  /// The image is a static asset for every user. `GET /v1/me` does return a
  /// presigned `avatarUrl` and an upload route exists, so this CAN be real —
  /// the app simply has no profile repository yet. Wiring it is client-side
  /// work only.
  Widget _avatarButton() => Semantics(
    button: true,
    label: 'Profile',
    child: InkWell(
      onTap: _openProfile,
      customBorder: const CircleBorder(),
      // 40 image + 2 ring padding + 2 ring stroke + 4 outer = 56, comfortably
      // over the 48dp floor. The outer padding IS the touch target; do not
      // shrink it to tighten the layout.
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kSecondaryColor, width: 2),
          ),
          // Reads the same permanent controller Profile writes, so changing the
          // photo there updates this header without a restart.
          child: Obx(() {
            final url = _profile.avatarUrl;
            return ClipOval(
              child: SizedBox(
                height: 40,
                width: 40,
                child: url != null && url.isNotEmpty
                    ? CommonImageView(
                        url: url,
                        cacheKey: _profile.me?.id,
                        height: 40, width: 40, fit: BoxFit.cover)
                    : CommonImageView(
                        imagePath: Assets.imagesProfileImage,
                        height: 40, width: 40, fit: BoxFit.cover),
              ),
            );
          }),
        ),
      ),
    ),
  );

  /// The badge and the list ship together, as they had to: a dot the buyer
  /// cannot tap through to something they can clear is worse than no dot.
  ///
  /// The count is the SERVER's `meta.unread`, not a count of whatever page the
  /// list happens to have loaded — the controller is permanent so the badge
  /// survives leaving the screen.
  Widget _bellButton() => Semantics(
    button: true,
    label: 'Notifications',
    child: IconButton(
      onPressed: _openNotifications,
      icon: Obx(() {
        final unread = _notifications.unread.value;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined,
                size: AppSizes.s24, color: kBlackColor),
            if (unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  decoration: BoxDecoration(
                    color: kRedColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    // Against the white header the ring is what stops the badge
                    // reading as part of the glyph.
                    border: Border.all(color: kPrimaryColor, width: 1.5),
                  ),
                  child: Center(
                    child: MyText(
                      // Capped: a three-digit count is wider than the icon and
                      // the exact number stops mattering well before then.
                      text: unread > 99 ? '99+' : '$unread',
                      size: AppTextScale.caption,
                      color: kWhiteColor,
                      weight: AppWeights.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    ),
  );

}

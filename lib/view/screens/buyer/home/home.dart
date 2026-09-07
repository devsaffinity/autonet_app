import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/buyer_home_controller.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/buyer/detail/comparison.dart';
import 'package:autonect/view/screens/buyer/home/widgets/active_request_card.dart';
import 'package:autonect/view/screens/buyer/home/widgets/offer_style_request_card.dart';
import 'package:autonect/view/screens/buyer/profile/profile.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
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
/// PHASE 4: there is no Service Providers section. The backend exposes no
/// electrician or provider listing route anywhere — only
/// `POST /electrician/registration`, a write — so the fixture card deck that
/// used to sit here could never have been filled from the API.
class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  late final BuyerHomeController _c;

  @override
  void initState() {
    super.initState();
    _c = BuyerHomeController.ensure();
    _c.load();
  }

  /// Straight off the session — `GET /v1/me` is phase 2, and the token payload
  /// already carries the name that the 'Lorem Ipsum' literal stood in for.
  String get _name => Get.find<TokenStore>().user?.name ?? 'there';

  void _openRequests() => RoleShell.maybeOf(context)?.goTo(1);

  /// Profile is pushed on top of the shell rather than being a tab, so it
  /// cannot reach the shell itself — `RoleShell.maybeOf` returns null from a
  /// routed page. We capture the shell HERE, where it is still an ancestor, and
  /// hand it down as a closure. Without this, Profile's 'My Requests' tile is a
  /// dead control.
  void _openProfile() {
    final shell = RoleShell.maybeOf(context);
    Get.to(() => BuyerProfilePage(
      onOpenRequests: shell == null
          ? null
          : () {
              Get.back();
              shell.goTo(1);
            },
    ));
  }

  List<PartRequest> _withOffers(ViewState<List<PartRequest>> s) =>
      switch (s) {
        Data<List<PartRequest>>(:final value) => [
          for (final r in value)
            if (r.offerCount > 0) r,
        ],
        _ => const [],
      };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _c.load,
        child: ListView(
          padding: AppSizes.DEFAULT,
          children: [
            _header(),
            const SizedBox(height: AppSizes.s24),
            // No 'Request a Part' button and no search bar. The wizard is the
            // nav bar's centre FAB — one entry point, not two — and a search
            // field would promise a filter no route accepts, which is the
            // exact reason the last one was deleted.
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
            // NOT an offers feed: there is no cross-request buyer offers
            // endpoint, so this is driven by the offerCount already on each
            // request — zero extra calls, and the label says what it shows.
            SectionHeader(
              title: 'Requests with offers',
              onAction: _openRequests,
            ),
            Obx(() {
              final items = _withOffers(_c.activeRequests.value);
              if (items.isEmpty) {
                return MyText(text: 'No offers yet — suppliers reply here.',
                    size: AppTextScale.body, color: kGreyTextColor);
              }
              // A short vertical list, not a carousel: these are the requests
              // needing the buyer's attention, and a horizontal strip hides how
              // many there are behind a swipe.
              return Column(
                children: [
                  for (final r in items) ...[
                    OfferStyleRequestCard(
                      request: r,
                      onTap: () => Get.to(() => ComparisonPage(request: r)),
                    ),
                    const SizedBox(height: AppSizes.s12),
                  ],
                ],
              );
            }),
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
          child: CommonImageView(
            imagePath: Assets.imagesProfileImage,
            height: 40,
            width: 40,
            radius: 20,
            fit: BoxFit.cover,
          ),
        ),
      ),
    ),
  );

  /// No unread badge. The backend does expose one — `GET /v1/notifications`
  /// returns `meta.unread` — but a dot the buyer cannot tap through to a list
  /// and clear is worse than no dot, so the badge ships in the same commit as
  /// the notifications screen or not at all. Until then this opens Profile,
  /// which is where the notifications entry lives.
  Widget _bellButton() => Semantics(
    button: true,
    label: 'Notifications',
    child: IconButton(
      onPressed: _openProfile,
      icon: const Icon(Icons.notifications_outlined,
          size: AppSizes.s24, color: kBlackColor),
    ),
  );

}

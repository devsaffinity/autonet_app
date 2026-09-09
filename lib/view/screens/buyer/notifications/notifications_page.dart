import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/notifications_controller.dart';
import 'package:autonect/data/models/app_notification.dart';
import 'package:autonect/view/screens/buyer/detail/order_status.dart';
import 'package:autonect/view/screens/buyer/request/request_detail.dart';
import 'package:autonect/view/widget/confirm_dialog.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The notification centre.
///
/// Everything here is a READ of something that already happened elsewhere, so
/// there is no create/edit path and no double-submit hazard. The only writes
/// are marking rows read and deleting them — and deletion is the one thing on
/// this screen that cannot be undone, which is why the bulk form asks first
/// and the per-row form is a deliberate swipe rather than a tappable target.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _c = NotificationsController.ensure();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _c.load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// 400px from the bottom rather than at it, so the next page is already in
  /// flight by the time the user reaches the end.
  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      _c.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kPrimaryColor,
    appBar: GeneralAppBar(
      title: 'Notifications',
      hasBackButton: true,
      // Hidden rather than disabled at zero: an always-visible action that does
      // nothing invites the tap that proves it does nothing.
      action: [
        Obx(() => _c.unread.value == 0
            ? const SizedBox.shrink()
            : TextButton(
                onPressed: _c.markAllRead,
                child: MyText(
                  text: 'Mark all read',
                  size: AppTextScale.label,
                  color: kSecondaryColor,
                  weight: AppWeights.semibold,
                ),
              )),
        // An icon, not a second text button: 'Mark all read' plus 'Clear all'
        // beside a back button and a title overruns the bar at 320dp, and the
        // label that would be truncated is the one on the destructive action.
        Obx(() => !_c.hasAny
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: _clearAll,
                tooltip: 'Clear all notifications',
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: kGreyTextColor, size: AppSizes.s24),
              )),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _c.load,
      color: kSecondaryColor,
      child: Obx(() => StateView<List<AppNotification>>(
        state: _c.state.value,
        onRetry: _c.load,
        emptyTitle: 'No notifications yet',
        builder: (_, items) => ListView.separated(
          controller: _scroll,
          padding: AppSizes.DEFAULT,
          // Always scrollable so pull-to-refresh works even on a short list.
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.s8),
          itemBuilder: (_, i) =>
              i == items.length ? _footer() : _dismissible(items[i]),
        ),
      )),
    ),
  );

  /// Swipe-to-delete, one direction only.
  ///
  /// endToStart alone because startToEnd is the platform back gesture on iOS,
  /// and a row that deletes itself when someone tries to leave the screen is
  /// the worst possible home for an irreversible action.
  ///
  /// confirmDismiss does the server call and onDismissed does the local
  /// removal, deliberately in that order: removing from the list inside
  /// confirmDismiss would rebuild without the row and dispose the very
  /// Dismissible still awaiting the answer.
  Widget _dismissible(AppNotification n) => Dismissible(
    key: ValueKey<String>(n.id),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSizes.s20),
      decoration: BoxDecoration(
        color: kRedColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: kWhiteColor),
    ),
    confirmDismiss: (_) => _c.confirmRemove(n),
    onDismissed: (_) => _c.forget(n),
    child: _NotificationTile(notification: n, onTap: () => _open(n)),
  );

  /// Clearing every notification is irreversible and one tap from the app bar,
  /// so it asks first — the same dialog the request-cancel flow uses, whose
  /// buttons each fire at most once.
  Future<void> _clearAll() async {
    final confirmed = await Get.dialog<bool>(const ConfirmDialog(
      verb: 'Clear all',
      warning: 'Every notification will be removed from this account. '
          'This cannot be undone.',
      keepLabel: 'Keep them',
    ));
    if (confirmed == true) await _c.removeAll();
  }

  Widget _footer() => Obx(() {
    if (_c.loadingMore.value) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.s16),
        child: Center(
          child: SizedBox(
            height: AppSizes.s20,
            width: AppSizes.s20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: kSecondaryColor),
          ),
        ),
      );
    }
    // Space for the last row to clear the bottom inset, and nothing else — a
    // "no more notifications" line on a list of three reads as an error.
    return const SizedBox(height: AppSizes.s24);
  });

  /// Marks read, then deep-links where the payload points.
  ///
  /// The read happens regardless of whether there is anywhere to go: tapping a
  /// notification is the user telling us they have seen it.
  Future<void> _open(AppNotification n) async {
    await _c.markRead(n);
    if (!mounted) return;

    if (n.orderId case final id?) {
      Get.to(() => OrderStatusPage(orderId: id));
      return;
    }
    if (n.requestId case final id?) {
      Get.to(() => BuyerRequestDetailPage(requestId: id));
    }
    // No payload: the row itself carried the whole message, and there is
    // nothing to open.
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;
    return Semantics(
      button: true,
      label: '${notification.title}. ${notification.body}'
          '${unread ? '. Unread' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.s12),
            decoration: BoxDecoration(
              // Unread is tinted rather than merely bolder: on a list of
              // twenty, weight alone is very hard to scan.
              color: unread ? kLightOrangeColor : kPrimaryColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: unread
                    ? kSecondaryColor.withValues(alpha: .3)
                    : kGreyTextColor.withValues(alpha: .2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.s8),
                  decoration: BoxDecoration(
                    color: unread
                        ? kSecondaryColor.withValues(alpha: .12)
                        : kMutedSurfaceColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    _glyphFor(notification.type),
                    size: AppSizes.s20,
                    color: unread ? kSecondaryColor : kGreyTextColor,
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: notification.title,
                        size: AppTextScale.body,
                        weight: unread ? AppWeights.bold : AppWeights.medium,
                        color: kBlackColor,
                        maxLines: 2,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                      MyText(
                        text: notification.body,
                        size: AppTextScale.label,
                        color: kGreyTextColor,
                        lineHeight: 1.4,
                        paddingTop: AppSizes.s4,
                      ),
                      MyText(
                        text: relativeTime(notification.createdAt),
                        size: AppTextScale.caption,
                        color: kGreyTextColor,
                        paddingTop: AppSizes.s8,
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(left: AppSizes.s8, top: 6),
                    height: AppSizes.s8,
                    width: AppSizes.s8,
                    decoration: const BoxDecoration(
                      color: kSecondaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Keyed off the backend's routing-map types. An unknown type falls back
  /// rather than rendering nothing — the server can add a type at any time and
  /// an older build must still show the notification.
  static IconData _glyphFor(String type) {
    if (type.startsWith('offer')) return Icons.local_offer_outlined;
    if (type.startsWith('order')) return Icons.receipt_long_outlined;
    if (type.startsWith('kyc')) return Icons.verified_user_outlined;
    if (type.startsWith('request')) return Icons.build_outlined;
    return Icons.notifications_none_rounded;
  }
}

/// 'Just now', '5m ago', '3h ago', '2d ago', then a date.
///
/// Hand-rolled, like every other date in this app: `intl` is deliberately not a
/// dependency.
String relativeTime(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final d = when.day.toString().padLeft(2, '0');
  final m = when.month.toString().padLeft(2, '0');
  return '$d/$m/${when.year}';
}

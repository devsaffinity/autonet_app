import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/my_bookings_controller.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/review_context.dart';
import 'package:autonect/view/screens/buyer/detail/review_page.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/choice_chips_field.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The comp's My Bookings screen — `GET /v1/bookings`.
///
/// 'Save Receipt' from the comp is absent: nothing in this product generates
/// a receipt, so the button would have nowhere to lead. 'Chat Now' is absent
/// for the same reason it is missing on the profile — a conversation can only
/// be opened against an OFFER today.
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final MyBookingsController c = MyBookingsController.ensure();

  @override
  void initState() {
    super.initState();
    c.refreshFirst();
  }

  /// Outside [PagedListView]: its header slot renders only in the Data arm,
  /// so a filter that matched nothing would take its own chips away.
  Widget get _filters => Obx(() {
    final selected = c.filter.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s20, AppSizes.s8, AppSizes.s20, 0),
      child: ChoiceChipsField<BookingStatus?>(
        options: MyBookingsController.filterOptions,
        selected: selected,
        onSelect: c.setFilter,
      ),
    );
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(title: 'My Bookings'),
    body: Column(children: [
      _filters,
      Expanded(child: Obx(() {
        final more = c.loadMoreError.value;
        return PagedListView<Booking>(
          state: c.state.value,
          loadingMore: c.loadingMore.value,
          loadMoreError: more == null ? null : userMessageFor(more),
          hasMore: c.hasMore,
          onLoadMore: c.loadMore,
          onRefresh: c.refreshFirst,
          emptyTitle: 'No bookings yet',
          emptyBody: 'Book an electrician and it will appear here.',
          itemBuilder: (_, b) => _BookingCard(
            booking: b,
            onCancel: () => _confirmCancel(b),
            onReview: () => _review(b),
          ),
        );
      })),
    ]),
  );

  /// A completed callout can be rated — the thing that finally lets an
  /// electrician earn a rating at all, since a Review needed an Order until
  /// bookingId existed.
  ///
  /// Pops back to this list rather than clearing the stack the way the order
  /// journey does: the buyer is standing in a list they may want to keep
  /// reading, not at the end of a road.
  void _review(Booking booking) => Get.to(() => ReviewPage(
    context: BookingReview(booking.id),
    supplierName: booking.provider?.fullName ??
        booking.provider?.name ??
        'your provider',
    onDone: () {
      Get.back();
      c.refreshFirst();
    },
  ));

  /// Cancelling demands a REASON — the server requires one, so asking for it
  /// here is not ceremony, it is the request body.
  Future<void> _confirmCancel(Booking booking) async {
    final note = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: MyText(text: 'Cancel booking?', size: AppTextScale.subtitle,
            weight: AppWeights.bold, color: kBlackColor),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          MyText(
            text: 'Let the provider know why. This cannot be undone.',
            size: AppTextScale.body, color: kGreyTextColor,
          ),
          const SizedBox(height: AppSizes.s12),
          TextField(
            controller: note,
            maxLength: 300,
            decoration: const InputDecoration(hintText: 'Reason'),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: MyText(text: 'Keep it', size: AppTextScale.body,
                color: kGreyTextColor),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: MyText(text: 'Cancel booking', size: AppTextScale.body,
                color: kRedColor, weight: AppWeights.semibold),
          ),
        ],
      ),
    );

    final reason = note.text.trim();
    note.dispose();
    // An empty reason is a guaranteed 400, so it is caught here rather than
    // spent on a round trip.
    if (confirmed != true || reason.isEmpty || !mounted) return;
    await c.cancel(booking, reason);
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.onReview,
  });

  final Booking booking;
  final VoidCallback onCancel;
  final VoidCallback onReview;

  String get _providerName =>
      booking.provider?.fullName ?? booking.provider?.name ?? 'Provider';

  @override
  Widget build(BuildContext context) {
    final at = booking.scheduledAt.toLocal();
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.s20, 0, AppSizes.s20, AppSizes.s12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: MyText(
            text: booking.serviceType?.label ?? 'Callout',
            size: AppTextScale.subtitle, weight: AppWeights.bold,
            color: kSecondaryColor, maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          )),
          if (booking.status case final s?)
            StatusBadge(label: s.label, color: _statusColor(s)),
        ]),
        if (booking.description case final d? when d.isNotEmpty) ...[
          const SizedBox(height: AppSizes.s4),
          MyText(text: d, size: AppTextScale.label, color: kGreyTextColor,
              maxLines: 2, textOverflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: AppSizes.s12),
        Row(children: [
          InitialsAvatar(name: _providerName, size: 36,
              radius: AppSizes.radiusPill),
          const SizedBox(width: AppSizes.s8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(text: _providerName, size: AppTextScale.body,
                  weight: AppWeights.semibold, color: kBlackColor,
                  maxLines: 1, textOverflow: TextOverflow.ellipsis),
              MyText(
                text: '${formatDayMonthYear(at)} · ${formatClock(at)}',
                size: AppTextScale.label, color: kGreyTextColor,
              ),
            ],
          )),
          // 'Awaiting quote', never '£0.00': quotedPence is null until the
          // provider has seen the job, and a zero would read as free.
          MyText(
            text: booking.isQuoted
                ? formatPence(booking.quotedPence!)
                : 'Awaiting quote',
            size: booking.isQuoted ? AppTextScale.body : AppTextScale.label,
            weight: booking.isQuoted ? AppWeights.bold : AppWeights.regular,
            color: booking.isQuoted ? kSecondaryColor : kGreyTextColor,
          ),
        ]),
        // COMPLETED is the only state a review is accepted from, so the
        // control appears exactly there. A second review earns a 409, but the
        // server is the authority on that and the toast says so.
        if (booking.status == BookingStatus.completed) ...[
          const SizedBox(height: AppSizes.s12),
          MyButton(
            buttonText: 'Rate this provider',
            fontSize: AppTextScale.label,
            height: 40,
            radius: AppSizes.radiusMd,
            onTap: onReview,
          ),
        ],
        // Shown only while the server would accept it. Past IN_PROGRESS the
        // provider has travelled and started, so this would only earn a 409.
        if (booking.canCancel) ...[
          const SizedBox(height: AppSizes.s12),
          MyButton(
            buttonText: 'Cancel booking',
            fontSize: AppTextScale.label,
            height: 40,
            radius: AppSizes.radiusMd,
            backgroundColor: kWhiteColor,
            fontColor: kRedColor,
            outlineColor: kRedColor,
            onTap: onCancel,
          ),
        ],
      ]),
    );
  }

  Color _statusColor(BookingStatus s) => switch (s) {
    BookingStatus.pending => kWarningColor,
    BookingStatus.confirmed => kInfoColor,
    BookingStatus.inProgress => kInfoColor,
    BookingStatus.completed => kSuccessColor,
    BookingStatus.cancelled => kRedColor,
  };
}

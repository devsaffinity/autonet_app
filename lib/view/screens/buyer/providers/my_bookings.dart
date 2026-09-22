import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/my_bookings_controller.dart';
import 'package:autonect/controller/buyer/receipt_controller.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/domain/review_context.dart';
import 'package:autonect/view/screens/buyer/detail/review_page.dart';
import 'package:autonect/view/screens/buyer/providers/booking_detail.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/counted_text_field.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:autonect/view/widget/status_badge.dart';
import 'package:autonect/view/widget/submitted_review_line.dart';
import 'package:autonect/view/widget/technician_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The comp's My Bookings screen — `GET /v1/bookings`.
///
/// THE FIVE FILTER CHIPS MOVED INTO THE APP BAR. The comp draws no filter at
/// all, and the chip row it replaced could not honour that: All / Pending /
/// Confirmed / Completed / Cancelled does not fit on one line at any phone
/// width, so 'Cancelled' wrapped onto a second row of its own and the screen
/// opened on a broken-looking header. Deleting the filter outright would have
/// matched the comp and lost a real capability — the repository takes
/// `status`, and a buyer with a year of callouts needs it. One funnel glyph
/// is the version that fits, and it is the same control My Requests already
/// uses.
///
/// 'Save Receipt' is LIVE once a booking is COMPLETED and PRICED — the rule the
/// server applies before it issues one — and visibly unavailable until then.
/// The receipt itself is the server's frozen snapshot, rendered as a PDF by
/// ReceiptController.
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

  /// The status filter, as one glyph in the app bar.
  ///
  /// Keyed by INDEX, never by the status itself. 'All' carries a null value —
  /// the repository must OMIT `status` rather than send it blank — and
  /// PopupMenuButton treats a null result as a DISMISSED menu, calling
  /// onCanceled instead of onSelected. A PopupMenuItem whose value is null is
  /// therefore unselectable, and choosing 'All' would silently leave the
  /// previous filter applied.
  ///
  /// The funnel turns orange while a filter is applied. The comp has no such
  /// state, but a control that hides its own selection AND changes what the
  /// list contains has to say so somewhere: without it a buyer who filtered to
  /// Cancelled, left, and came back sees a short list and no reason for it.
  Widget get _filter => Obx(() {
    const options = MyBookingsController.filterOptions;
    final selected = c.filter.value;
    final index = options.indexWhere((o) => o.value == selected);
    return PopupMenuButton<int>(
      tooltip: 'Filter by status',
      initialValue: index,
      onSelected: (i) => c.setFilter(options[i].value),
      color: kWhiteColor,
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      itemBuilder: (_) => [
        for (final (i, o) in options.indexed)
          PopupMenuItem<int>(
            value: i,
            child: MyText(text: o.label, size: AppTextScale.body,
                color: i == index ? kSecondaryColor : kBlackColor,
                weight: i == index ? AppWeights.semibold : AppWeights.regular),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
        child: Icon(Icons.filter_alt_outlined, size: AppSizes.s24,
            color: selected == null ? kGreyTextColor : kSecondaryColor),
      ),
    );
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(title: 'My Bookings', action: [_filter]),
    body: Obx(() {
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
          onOpen: () => _open(b),
          onCancel: () => _confirmCancel(b),
          onReview: () => _review(b),
          onReceipt: () => ReceiptController.ensure().open(b),
        ),
      );
    }),
  );

  /// The comp's 'View Booking'.
  ///
  /// The list's own handlers travel with it rather than being rebuilt on the
  /// detail screen, and both POP FIRST: cancelling and reviewing each refresh
  /// this list, and a detail page left standing over a refreshed list would go
  /// on showing the status the booking had before the buyer changed it.
  void _open(Booking booking) => Get.to(() => BookingDetailPage(
    booking: booking,
    onCancel: () {
      Get.back();
      _confirmCancel(booking);
    },
    onReview: booking.status == BookingStatus.completed && !booking.isReviewed
        ? () {
            Get.back();
            _review(booking);
          }
        : null,
  ));

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
    existingReview: booking.buyerReview,
    isReviewed: booking.isReviewed,
    onDone: () {
      Get.back();
      c.refreshFirst();
    },
  ));

  /// Cancelling demands a REASON — the server requires one, so asking for it
  /// here is not ceremony, it is the request body.
  Future<void> _confirmCancel(Booking booking) async {
    final reason = await Get.dialog<String>(const _CancelBookingDialog());
    // An empty reason is a guaranteed 400, so it is caught here rather than
    // spent on a round trip.
    if (reason == null || reason.isEmpty || !mounted) return;
    await c.cancel(booking, reason);
  }
}

class _CancelBookingDialog extends StatefulWidget {
  const _CancelBookingDialog();

  @override
  State<_CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<_CancelBookingDialog> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _note.text.trim().isNotEmpty;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      title: const MyText(
        text: 'Cancel booking?',
        size: AppTextScale.subtitle,
        weight: AppWeights.bold,
        color: kBlackColor,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MyText(
            text: 'Let the provider know why. This cannot be undone.',
            size: AppTextScale.body,
            color: kGreyTextColor,
          ),
          const SizedBox(height: AppSizes.s16),
          CountedTextField(
            controller: _note,
            maxLength: 300,
            maxLines: 3,
            labelText: 'Reason',
            isRequired: true,
            hintText: 'Enter reason for cancellation',
            marginBottom: AppSizes.s4,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: null),
          child: const MyText(
            text: 'Keep it',
            size: AppTextScale.body,
            color: kGreyTextColor,
          ),
        ),
        TextButton(
          onPressed: canSubmit ? () => Get.back(result: _note.text.trim()) : null,
          child: MyText(
            text: 'Cancel booking',
            size: AppTextScale.body,
            color: canSubmit ? kRedColor : kGreyTextColor.withValues(alpha: 0.5),
            weight: AppWeights.semibold,
          ),
        ),
      ],
    );
  }
}

/// One booking, in the comp's card language.
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onOpen,
    required this.onCancel,
    required this.onReview,
    required this.onReceipt,
  });

  final Booking booking;
  final VoidCallback onOpen;
  final VoidCallback onCancel;
  final VoidCallback onReview;
  final VoidCallback onReceipt;

  String get _providerName =>
      booking.provider?.fullName ?? booking.provider?.name ?? 'Provider';

  @override
  Widget build(BuildContext context) {
    final at = booking.scheduledAt.toLocal();
    return AppCard(
      // Bottom gap ONLY: PagedListView already pads its scroll view by
      // AppSizes.DEFAULT, and a horizontal margin here would inset the card
      // twice — the same defect the provider rows carried.
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: MyText(text: 'Service Details',
              size: AppTextScale.caption, color: kGreyTextColor,
              letterSpacing: 0.5)),
          // Not in the comp, and kept: on a LIST every card looks alike, and
          // whether a callout is still waiting on the provider or was
          // cancelled last week is the one thing that tells them apart.
          if (booking.status case final s?)
            StatusBadge(label: s.label, color: bookingStatusColor(s)),
        ]),
        const SizedBox(height: AppSizes.s4),
        MyText(
          text: booking.serviceType?.label ?? 'Callout',
          size: AppTextScale.title, weight: AppWeights.bold,
          color: kSecondaryColor, maxLines: 1,
          textOverflow: TextOverflow.ellipsis,
        ),
        // The buyer's own words about the job, when they gave any.
        if (booking.description case final d? when d.isNotEmpty) ...[
          const SizedBox(height: AppSizes.s4),
          MyText(text: d, size: AppTextScale.body, color: kGreyTextColor,
              maxLines: 2, textOverflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: AppSizes.s8),
        // WHEN, and for how much. The comp's card omits both; on a list of
        // bookings the date is the first thing a buyer looks for, and a
        // booking with no price showing would read as free rather than as
        // unquoted.
        Row(children: [
          const Icon(Icons.schedule, size: AppSizes.s16,
              color: kGreyTextColor),
          const SizedBox(width: AppSizes.s4),
          Expanded(child: MyText(
            text: '${formatDayMonthYear(at)} · ${formatClock(at)}',
            size: AppTextScale.label, color: kGreyTextColor,
            maxLines: 1, textOverflow: TextOverflow.ellipsis,
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
        const SizedBox(height: AppSizes.s12),
        TechnicianPanel(
          name: _providerName,
          headline: booking.provider?.headline,
          avatarUrl: booking.provider?.avatarUrl,
        ),
        const SizedBox(height: AppSizes.s12),
        // EQUAL THIRDS, and the row is guaranteed to stay a row.
        //
        // Intrinsic widths in a Wrap were tried first and are the closer
        // reading of the comp, whose 'Chat Now' is visibly the narrow one.
        // Measured, they do not survive: this app sets Cairo, a wide face,
        // and at label size the three labels plus their padding land within
        // a few pixels of the card width on a 390dp handset — the commonest
        // width there is. A layout that is one glyph away from silently
        // becoming three stacked bars is not the comp, it is a coin toss.
        //
        // Thirds cost a little fidelity and buy certainty, and the label
        // ellipsizes rather than overflowing if a very narrow phone or a
        // large text scale takes the third below what fits.
        Row(children: [
          // THIS booking's thread, not the Messages tab.
          Expanded(child: _CardAction(label: 'Chat Now',
              onTap: () => Get.to(
                    () => ChatRoomPage(
                      contextId: booking.id,
                      myUserId: booking.buyerId,
                      title: _providerName,
                      peerAvatarUrl: booking.provider?.avatarUrl,
                    ),
                  ))),
          const SizedBox(width: AppSizes.s8),
          Expanded(child: _CardAction(label: 'View Booking', onTap: onOpen)),
          const SizedBox(width: AppSizes.s8),
          // LIVE once the job is COMPLETED and PRICED — the same rule the
          // server applies, so the button is only tappable when tapping it can
          // succeed. Until then it stays visibly unavailable, and the tooltip
          // says why rather than a caption repeated down the list.
          //
          // Its OWN Obx: cards are built lazily by the list, outside the page's
          // Obx, so a read of `working` up there would never rebuild this.
          Expanded(child: booking.canHaveReceipt
              ? Obx(() {
                  final busy =
                      ReceiptController.ensure().working.value == booking.id;
                  return _CardAction(
                    label: busy ? 'Preparing…' : 'Save Receipt',
                    onTap: busy ? null : onReceipt,
                  );
                })
              : const _CardAction(
                  label: 'Save Receipt',
                  tooltip: 'A receipt is available once the job is complete '
                      'and your provider has recorded the price',
                )),
        ]),
        // A REVIEW IS FINAL. Offered only on a COMPLETED booking the buyer has
        // not yet reviewed; once left, their review is shown read-only in its
        // place. There is no edit — the server has no update route and
        // refuses a second review — so a button here could only earn a 409.
        if (booking.status == BookingStatus.completed) ...[
          const SizedBox(height: AppSizes.s12),
          if (booking.buyerReview case final review?)
            SubmittedReviewLine(review: review)
          else
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
}

/// One of the comp's small outlined actions inside a booking card.
///
/// Local rather than MyButton, which has no single-line guard on its label —
/// at a large text scale MyButton wraps its text and grows the card instead
/// of ellipsizing. These three share a row of equal thirds, so the guard is
/// the whole point of them.
///
/// A null [onTap] renders it UNAVAILABLE rather than merely inert: greyed,
/// hairline border, and no ripple, so it never invites the tap that proves it
/// does nothing.
class _CardAction extends StatelessWidget {
  const _CardAction({required this.label, this.onTap, this.tooltip});

  final String label;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    // Both read into locals so flow analysis promotes them: a bare
    // `onTap != null` guard does not narrow a FIELD, and the ! that would
    // otherwise be needed is the kind that survives a later refactor after
    // it has stopped being true.
    final action = onTap;
    final hint = tooltip;
    final enabled = action != null;
    // `alignment` is correct HERE and was the bug one layout ago, which is
    // worth spelling out because it looks like the same line of code.
    //
    // A Container with an alignment EXPANDS to fill bounded incoming
    // constraints, then positions its child inside itself. Under Expanded
    // the incoming width is TIGHT — exactly one third — so expanding is
    // what is wanted and the label centres in it. Under the Wrap this
    // briefly used, the constraints were LOOSE and bounded, so the same
    // line took the whole card width, every pill became a run of its own,
    // and the comp's row of three rendered as three full-width bars.
    final pill = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
            color: enabled ? kSecondaryColor : kFieldBorderColor),
      ),
      child: MyText(
        text: label,
        size: AppTextScale.label,
        weight: AppWeights.semibold,
        color: enabled ? kSecondaryColor : kGreyTextColor,
        maxLines: 1,
        textOverflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
    final child = action == null
        ? pill
        : MyRippleEffect(radius: AppSizes.radiusMd, onTap: action,
            child: pill);
    return Semantics(
      button: true,
      enabled: enabled,
      label: hint == null ? label : '$label. $hint',
      child: hint == null
          ? child
          : Tooltip(message: hint, child: ExcludeSemantics(child: child)),
    );
  }
}

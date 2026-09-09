import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/electrician/provider_bookings_controller.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/view/screens/electrician/home/widgets/provider_booking_card.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Incoming callouts awaiting an answer — `GET /v1/bookings?status=PENDING`
/// for the signed-in provider.
///
/// This is the screen that unstranded the booking loop. Every booking a buyer
/// made sat at PENDING with no way out, because the route that advances one
/// existed but nothing could list the ids to advance.
///
/// The mock this replaces showed an Acceptance Rate and an Average Response
/// Time. Neither is computed anywhere — there is no acceptance counter and no
/// response-time column — so they are gone rather than rendered from
/// literals: a fabricated 94% on a provider's own dashboard is a number they
/// would reasonably act on.
class ElectricianBookingRequestPage extends StatefulWidget {
  const ElectricianBookingRequestPage({super.key});

  @override
  State<ElectricianBookingRequestPage> createState() =>
      _ElectricianBookingRequestPageState();
}

class _ElectricianBookingRequestPageState
    extends State<ElectricianBookingRequestPage> {
  final ProviderBookingsController c =
      ProviderBookingsController.ensure(initialFilter: BookingStatus.pending);

  @override
  void initState() {
    super.initState();
    c.refreshFirst();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(hasBackButton: false, title: 'Booking Requests'),
    body: Obx(() {
      final more = c.loadMoreError.value;
      return PagedListView<Booking>(
        state: c.state.value,
        loadingMore: c.loadingMore.value,
        loadMoreError: more == null ? null : userMessageFor(more),
        hasMore: c.hasMore,
        onLoadMore: c.loadMore,
        onRefresh: c.refreshFirst,
        emptyTitle: 'No new requests',
        emptyBody: 'Buyers who book you appear here.',
        itemBuilder: (_, b) => ProviderBookingCard(
          booking: b,
          onAdvance: () => _accept(b),
          onDecline: () => _decline(b),
        ),
      );
    }),
  );

  Future<void> _accept(Booking b) async {
    final next = ProviderBookingsController.nextStep(b.status);
    if (next == null) return;
    await c.advance(b, next);
  }

  /// Declining is a CANCELLATION with a reason — that is how the server models
  /// it, and the buyer is owed the reason either way.
  Future<void> _decline(Booking b) async {
    final note = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: MyText(text: 'Decline this callout?',
            size: AppTextScale.subtitle, weight: AppWeights.bold,
            color: kBlackColor),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          MyText(
            text: 'The buyer is told why, and the slot frees up for '
                'somebody else.',
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
            child: MyText(text: 'Decline', size: AppTextScale.body,
                color: kRedColor, weight: AppWeights.semibold),
          ),
        ],
      ),
    );

    final reason = note.text.trim();
    note.dispose();
    // An empty reason is a guaranteed 400 — caught here rather than spent on
    // a round trip.
    if (confirmed != true || reason.isEmpty || !mounted) return;
    await c.decline(b, reason);
  }
}

/// Shared date line, so the request card and the bookings list agree.
String bookingWhen(Booking b) {
  final at = b.scheduledAt.toLocal();
  return '${formatDayMonthYear(at)} · ${formatClock(at)}';
}

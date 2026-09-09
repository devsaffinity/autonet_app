import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/electrician/provider_bookings_controller.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/view/screens/electrician/home/widgets/provider_booking_card.dart';
import 'package:autonect/view/widget/choice_chips_field.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The provider's own diary — `GET /v1/bookings` for an ELECTRICIAN.
///
/// Same route the buyer's My Bookings uses; the server branches on role, so
/// this returns the work they were booked FOR rather than what they booked.
///
/// The mock this replaces rendered a hardcoded Column of five fixtures with a
/// balance figure above them. There is no earnings column anywhere — Booking
/// carries quotedPence and finalPence and nothing sums them — so the figure
/// is gone rather than invented.
class ElectricianMyBookingsPage extends StatefulWidget {
  const ElectricianMyBookingsPage({super.key});

  @override
  State<ElectricianMyBookingsPage> createState() =>
      _ElectricianMyBookingsPageState();
}

class _ElectricianMyBookingsPageState extends State<ElectricianMyBookingsPage> {
  final ProviderBookingsController c = ProviderBookingsController.ensure();

  /// PENDING is absent: those live on Booking Requests, which is a separate
  /// tab, and duplicating them here would mean two screens fighting over the
  /// same accept button.
  static const List<SelectOption<BookingStatus?>> _filters = [
    SelectOption<BookingStatus?>(null, 'All'),
    SelectOption<BookingStatus?>(BookingStatus.confirmed, 'Confirmed'),
    SelectOption<BookingStatus?>(BookingStatus.inProgress, 'In progress'),
    SelectOption<BookingStatus?>(BookingStatus.completed, 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    c.refreshFirst();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(hasBackButton: false, title: 'My Bookings'),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.s20, AppSizes.s8, AppSizes.s20, 0),
        child: Obx(() => ChoiceChipsField<BookingStatus?>(
          options: _filters,
          selected: c.filter.value,
          onSelect: c.setFilter,
        )),
      ),
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
          emptyBody: 'Accepted callouts appear here.',
          itemBuilder: (_, b) => ProviderBookingCard(
            booking: b,
            onAdvance: () {
              final next = ProviderBookingsController.nextStep(b.status);
              if (next != null) c.advance(b, next);
            },
          ),
        );
      })),
    ]),
  );
}

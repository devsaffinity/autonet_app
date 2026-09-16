import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/electrician/provider_bookings_controller.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/electrician/home/upcoming_booking_details.dart';
import 'package:autonect/view/screens/electrician/home/widgets/provider_booking_card.dart';
import 'package:autonect/view/screens/electrician/home/widgets/quote_dialog.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/paged_list_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The provider's own diary — `GET /v1/bookings` for an ELECTRICIAN.
///
/// Same route the buyer's My Bookings uses; the server branches on role, so
/// this returns the work they were booked FOR rather than what they booked.
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

  /// Name a price. The dialog converts pounds to pence in one place — money
  /// is integer pence end to end, and doing that arithmetic per screen is how
  /// one of them ends up off by a factor of a hundred.
  Future<void> _quote(Booking booking) async {
    final result = await showQuoteDialog(booking);
    if (result == null || !mounted) return;
    await c.quote(
      booking,
      quotedPence: result.isFinal ? null : result.pence,
      finalPence: result.isFinal ? result.pence : null,
    );
  }


  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GeneralAppBar(hasBackButton: false, title: 'My Bookings'),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle from Figma comp
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.s20, AppSizes.s4, AppSizes.s20, AppSizes.s8),
          child: MyText(
            text: 'Manage your service pipeline and client schedule.',
            size: 13,
            weight: FontWeight.w400,
            color: kGreyTextColor,
          ),
        ),

        // Figma styled horizontal pill tabs
        SizedBox(
          height: 38,
          child: Obx(() {
            final selectedFilter = c.filter.value;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final opt = _filters[i];
                final isSelected = selectedFilter == opt.value;
                return InkWell(
                  onTap: () => c.setFilter(opt.value),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? kSecondaryColor : const Color(0xffF2F4F7),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(
                      color: isSelected ? kSecondaryColor : const Color(0xffEAECF0),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? kWhiteColor : kBlackColor,
                    ),
                  ),
                ),
              );
            },
          );
        }),
        ),

        const SizedBox(height: AppSizes.s12),

        // Bookings list
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
              onQuote: () => _quote(b),
              onTap: () {
                Get.to(
                  () => ElectricianBookingDetailsPage(
                    booking: b,
                    onBookingUpdated: () => c.refreshFirst(),
                  ),
                );
              },
            ),
          );
        })),
      ],
    ),
  );
}

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// A tinted pill, promoted from SupplierStatusBadge.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s12, vertical: AppSizes.s4),
    decoration: AppStyling().myDecoration(
      color: color.withValues(alpha: .12),
      borderColor: kTransperentColor,
      radius: AppSizes.radiusPill,
    ),
    child: MyText(text: label, size: AppTextScale.label, color: color,
        weight: AppWeights.semibold),
  );
}

/// The status -> colour maps live HERE, not on the models: DRY rule 5 forbids
/// a Color on a data model. `null` means the wire carried a member this build
/// does not know, which is neutral, never alarming.
Color orderStatusColor(OrderStatus? s) => switch (s) {
  OrderStatus.placed => kInfoColor,
  OrderStatus.preparing => kWarningColor,
  OrderStatus.outForDelivery => kInfoColor,
  OrderStatus.delivered => kSuccessColor,
  OrderStatus.cancelled => kRedColor,
  null => kGreyTextColor,
};

/// Promoted out of my_bookings.dart when the booking DETAIL screen wanted
/// the same map. Two copies of a status colour is how one screen starts
/// calling CONFIRMED blue while the other calls it green.
Color bookingStatusColor(BookingStatus? s) => switch (s) {
  BookingStatus.pending => kWarningColor,
  BookingStatus.confirmed => kInfoColor,
  BookingStatus.inProgress => kInfoColor,
  BookingStatus.completed => kSuccessColor,
  BookingStatus.cancelled => kRedColor,
  null => kGreyTextColor,
};

Color requestStatusColor(RequestStatus? s) => switch (s) {
  RequestStatus.open => kSuccessColor,
  RequestStatus.closed => kGreyTextColor,
  RequestStatus.cancelled => kRedColor,
  null => kGreyTextColor,
};

Color urgencyColor(RequestUrgency? u) => switch (u) {
  RequestUrgency.urgent => kRedColor,
  RequestUrgency.standard => kInfoColor,
  RequestUrgency.low => kGreyTextColor,
  null => kGreyTextColor,
};

/// Widget-layer too: a displayName getter on OfferSupplier would put
/// presentation on a data model, which DRY rule 5 forbids.
String supplierDisplayName(OfferSupplier s) =>
    s.businessName ?? s.name ?? 'Supplier';

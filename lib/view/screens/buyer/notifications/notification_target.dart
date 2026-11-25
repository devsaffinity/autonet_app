import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/app_notification.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/view/screens/buyer/detail/order_status.dart';
import 'package:autonect/view/screens/buyer/notifications/notifications_page.dart';
import 'package:autonect/view/screens/buyer/providers/booking_detail.dart';
import 'package:autonect/view/screens/buyer/providers/my_bookings.dart';
import 'package:autonect/view/screens/buyer/request/request_detail.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/screens/electrician/home/upcoming_booking_details.dart';
import 'package:autonect/view/screens/electrician/profile/electrician_access_tier_page.dart';
import 'package:autonect/view/screens/electrician/review/review.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_offers.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_order_detail.dart';
import 'package:autonect/view/screens/supplier/profile/supplier_access_tier_page.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_request_detail.dart';
import 'package:get/get.dart';

String? _role() => Get.isRegistered<TokenStore>()
    ? Get.find<TokenStore>().user?.role
    : null;

/// Pushes the screen a notification's payload points at.
///
/// Returns false when the payload names nothing this build can open, so the
/// caller can decide what "nowhere" means — the notification centre row does
/// nothing (the row carried the whole message), a push tap opens the centre.
///
/// Shared by the in-app centre and by push taps, so both always land on the
/// same screen for the same event.
Future<bool> openNotificationTarget(AppNotification n) async {
  final role = _role();

  if (n.orderId case final id?) {
    if (role == 'SUPPLIER') {
      Get.to(() => SupplierOrderDetailPage(orderId: id));
    } else {
      Get.to(() => OrderStatusPage(orderId: id));
    }
    return true;
  }
  if (n.requestId case final id?) {
    if (role == 'SUPPLIER') {
      Get.to(() => SupplierRequestDetailPage(requestId: id));
    } else {
      Get.to(() => BuyerRequestDetailPage(requestId: id));
    }
    return true;
  }
  if (n.offerId != null && role == 'SUPPLIER') {
    Get.to(() => const SupplierOffersPage());
    return true;
  }
  if (n.bookingId case final id?) {
    if (role == 'ELECTRICIAN') {
      Get.to(() => ElectricianBookingDetailsPage(bookingId: id));
      return true;
    }
    if (Get.isRegistered<BookingsRepository>()) {
      final res = await Get.find<BookingsRepository>().byId(id);
      if (res is Ok<Booking>) {
        Get.to(() => BookingDetailPage(booking: res.value));
        return true;
      }
    }
    Get.to(() => const MyBookingsPage());
    return true;
  }
  if (n.conversationId case final id?) {
    final senderTitle = n.title.startsWith('New message from ')
        ? n.title.replaceFirst('New message from ', '').trim()
        : null;
    Get.to(
      () => ChatRoomPage(
        conversationId: id,
        contextId: n.bookingId ?? n.offerId,
        type: n.offerId != null
            ? ConversationType.offer
            : ConversationType.booking,
        title: senderTitle,
      ),
    );
    return true;
  }
  return false;
}

/// Where a tapped push goes, keyed on `data.type`.
///
/// Never throws and never dead-ends: a missing or unknown type — new event
/// types ship without an app release — opens the notification centre. The
/// `test` type opens nothing; it only proves the wiring.
Future<void> openPushTarget(Map<String, String> data) async {
  final type = data['type'] ?? '';
  if (type == 'test') return;

  final role = _role();

  switch (type) {
    case 'billing':
      if (role == 'SUPPLIER') {
        Get.to(() => const SupplierAccessTierPage());
        return;
      }
      if (role == 'ELECTRICIAN') {
        Get.to(() => const ElectricianAccessTierPage());
        return;
      }
    case 'kyc':
      // Re-reads approval from the server and routes on the answer — the one
      // place that already knows which holding screen or shell is right.
      if (role == 'SUPPLIER' || role == 'ELECTRICIAN') {
        if (Get.isRegistered<RoleController>()) {
          await RoleController.to.refreshProviderAccess();
          return;
        }
      }
    case 'review':
      if (role == 'ELECTRICIAN') {
        Get.to(() => const ElectricianReviewPage());
        return;
      }
    case 'chat' || 'booking' || 'request' || 'offer' || 'order':
      final opened = await openNotificationTarget(
        AppNotification(
          id: '',
          type: type,
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          read: false,
          createdAt: DateTime.now(),
          data: Map<String, dynamic>.from(data),
        ),
      );
      if (opened) return;
  }
  Get.to(() => const NotificationsPage());
}

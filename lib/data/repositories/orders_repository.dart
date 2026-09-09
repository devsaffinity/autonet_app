import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';

/// The offer -> order half of the buyer funnel: one offers route, one accept
/// route and the three `/v1/orders` routes.
abstract class OrdersRepository {
  /// A BARE, UNPAGINATED array — no `meta`, no cap. Deliberately not
  /// `Paged<Offer>`: a fabricated `PageMeta.empty` would assert a
  /// `hasNextPage:false` the server never said.
  Future<ApiResult<List<Offer>>> offersForRequest(String requestId);

  /// Every live offer across ALL of this buyer's requests, newest first —
  /// `GET /v1/buyer/offers`. Paged, unlike [offersForRequest], and each row
  /// carries `offer.request` so a card can say which car it is about.
  ///
  /// Mounted at /buyer/offers rather than /offers because `GET /v1/offers` is
  /// the SUPPLIER's own list and is role-gated to SUPPLIER — a buyer calling it
  /// gets a 403, not an empty list.
  Future<ApiResult<Paged<Offer>>> buyerOffers({int page = 1, int limit = 20});

  /// [deliveryLocation] is omitted when null or blank — `{}` is a valid body,
  /// but `""` fails the server's `min(1)` and 400s.
  Future<ApiResult<Order>> acceptOffer({
    required String offerId,
    String? deliveryLocation,
  });

  /// The filter enum here accepts all FIVE statuses, PLACED included — unlike
  /// the PATCH enum below.
  Future<ApiResult<Paged<Order>>> list({
    int page = 1,
    int limit = 20,
    OrderStatus? status,
  });

  Future<ApiResult<Order>> byId(String id);

  /// Throws [ArgumentError] BEFORE any request for the two bodies the server is
  /// certain to reject: `status == placed` (not in the PATCH enum) and a
  /// CANCELLED with no note (a `.refine` makes it mandatory).
  ///
  /// The response is the FULL re-fetched order including the appended event, so
  /// callers must not follow it with a GET.
  Future<ApiResult<Order>> changeStatus({
    required String orderId,
    required OrderStatus status,
    String? note,
  });
}

import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/repositories/orders_repository.dart';

class OrdersApiRepository implements OrdersRepository {
  /// [tokens] is accepted but not retained — see CatalogApiRepository for why
  /// every buyer repository takes the same pair.
  OrdersApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  /// The server rejects a limit above PAGINATION.MAX_LIMIT with a 400 rather
  /// than clamping, so the clamp happens here.
  static const int _maxLimit = 100;

  static Order _one(Object? d) =>
      Order.fromJson((d as Map).cast<String, dynamic>());

  /// `send`, not the paged path: this route is a bare array with no `meta`, no
  /// page/limit and no cap.
  @override
  Future<ApiResult<List<Offer>>> offersForRequest(String requestId) => _c.send(
    method: 'GET',
    path: '/v1/requests/$requestId/offers',
    decode: (d) => (d as List)
        .map((e) => Offer.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false),
  );

  /// No `status` filter is sent even though `listOrdersQuerySchema` allows one:
  /// its enum is the ORDER statuses, and an offer's status is a different enum
  /// entirely, so any value here would 400. The service already excludes
  /// WITHDRAWN server-side, which is the only exclusion a buyer needs.
  @override
  Future<ApiResult<Paged<Offer>>> buyerOffers({int page = 1, int limit = 20}) =>
      _c.sendEnvelope(
        method: 'GET',
        path: '/v1/buyer/offers',
        query: {
          'page': '${page < 1 ? 1 : page}',
          'limit': '${limit.clamp(1, _maxLimit)}',
        },
        decode: Paged.decoder(Offer.fromJson),
      );

  /// `{}` is a valid body; `{'deliveryLocation': ''}` is not — the schema is
  /// `z.string().min(1).max(300).optional()`, so a blank field must be omitted
  /// rather than sent empty.
  @override
  Future<ApiResult<Order>> acceptOffer({
    required String offerId,
    String? deliveryLocation,
  }) => _c.send(
    method: 'POST',
    path: '/v1/offers/$offerId/accept',
    body: {
      if (deliveryLocation != null && deliveryLocation.trim().isNotEmpty)
        'deliveryLocation': deliveryLocation.trim(),
    },
    decode: _one,
  );

  /// As on requests, the `status` key is omitted entirely when null: the filter
  /// is a bare optional enum, so a blank value is a 400 and not "no filter".
  /// Unlike the PATCH enum below, this one does accept PLACED.
  @override
  Future<ApiResult<Paged<Order>>> list({
    int page = 1,
    int limit = 20,
    OrderStatus? status,
  }) => _c.sendEnvelope(
    method: 'GET',
    path: '/v1/orders',
    query: {
      'page': '${page < 1 ? 1 : page}',
      'limit': '${limit.clamp(1, _maxLimit)}',
      if (status != null) 'status': status.wire,
    },
    decode: Paged.decoder(Order.fromJson),
  );

  @override
  Future<ApiResult<Order>> byId(String id) =>
      _c.send(method: 'GET', path: '/v1/orders/$id', decode: _one);

  /// Both guards throw BEFORE anything reaches the wire, because both bodies
  /// are guaranteed 400s and a round trip would only turn a programming error
  /// into a toast:
  ///   (a) `orderStatusBodySchema` is the four-value subset
  ///       ['PREPARING','OUT_FOR_DELIVERY','DELIVERED','CANCELLED'] — PLACED is
  ///       seeded by the accept, never PATCHed;
  ///   (b) its `.refine` makes `note` mandatory on CANCELLED.
  ///
  /// Deliberately NOT `async`: throwing synchronously is what lets a caller
  /// (and the test) prove no request was made at all.
  ///
  /// The response is the full re-fetched order with the new event appended —
  /// do not follow this with a GET.
  @override
  Future<ApiResult<Order>> changeStatus({
    required String orderId,
    required OrderStatus status,
    String? note,
  }) {
    if (status == OrderStatus.placed) {
      throw ArgumentError.value(
        status,
        'status',
        'PLACED is not accepted by PATCH /v1/orders/{id}/status',
      );
    }
    final trimmed = note?.trim() ?? '';
    if (status == OrderStatus.cancelled && trimmed.isEmpty) {
      throw ArgumentError.value(
        note,
        'note',
        'A note is required when cancelling',
      );
    }
    return _c.send(
      method: 'PATCH',
      path: '/v1/orders/$orderId/status',
      body: {'status': status.wire, if (trimmed.isNotEmpty) 'note': trimmed},
      decode: _one,
    );
  }
}

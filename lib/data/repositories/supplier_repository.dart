import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';

/// Supplier-side feed, unlock, dashboard and offer lifecycle.
abstract class SupplierRepository {
  /// Incoming matching requests (TEASER projection) — `GET /v1/supplier/requests`.
  Future<ApiResult<Paged<SupplierLead>>> feed({
    int page = 1,
    int limit = 20,
    String? partName,
    Region? region,
    PartCondition? condition,
    RequestUrgency? urgency,
    String? make,
    String? model,
    int? minOffers,
    int? maxOffers,
    String? sort,
  });

  /// Full request detail — subscribed: free; else debits 1 credit on server:
  /// `GET /v1/supplier/requests/{id}`.
  Future<ApiResult<SupplierLeadDetail>> leadDetail(String id);

  /// Real-time counters for supplier dashboard & home — `GET /v1/supplier/dashboard`.
  Future<ApiResult<SupplierDashboardData>> dashboard();

  /// Submit a quote/offer on an open request — `POST /v1/requests/{id}/offers`.
  Future<ApiResult<SupplierOffer>> createOffer({
    required String requestId,
    required int pricePence,
    required PartCondition condition,
    int? warrantyMonths,
    required DeliveryOption deliveryOption,
    int? deliveryTimeDays,
    required StockStatus stockStatus,
    required int quantity,
    String? notes,
  });

  /// Supplier's own submitted offers (paged, filterable by status) —
  /// `GET /v1/supplier/offers`.
  Future<ApiResult<Paged<SupplierOffer>>> listOffers({
    int page = 1,
    int limit = 20,
    OfferStatus? status,
  });

  /// Edit own PENDING offer — `PATCH /v1/offers/{id}`.
  Future<ApiResult<SupplierOffer>> editOffer({
    required String offerId,
    int? pricePence,
    PartCondition? condition,
    int? warrantyMonths,
    DeliveryOption? deliveryOption,
    int? deliveryTimeDays,
    StockStatus? stockStatus,
    int? quantity,
    String? notes,
  });

  /// Withdraw own PENDING offer — `POST /v1/offers/{id}/withdraw`.
  Future<ApiResult<SupplierOffer>> withdrawOffer(String offerId);
}

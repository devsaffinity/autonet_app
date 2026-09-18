import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';

class SupplierApiRepository implements SupplierRepository {
  SupplierApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;
  static const int _maxLimit = 100;

  @override
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
  }) {
    final query = <String, String>{
      'page': '${page < 1 ? 1 : page}',
      'limit': '${limit.clamp(1, _maxLimit)}',
      if (partName != null && partName.trim().isNotEmpty)
        'partName': partName.trim(),
      if (region != null) 'region': region.wire,
      if (condition != null) 'condition': condition.wire,
      if (urgency != null) 'urgency': urgency.wire,
      if (make != null && make.trim().isNotEmpty) 'make': make.trim(),
      if (model != null && model.trim().isNotEmpty) 'model': model.trim(),
      if (minOffers != null) 'minOffers': '$minOffers',
      if (maxOffers != null) 'maxOffers': '$maxOffers',
      if (sort != null) 'sort': sort,
    };

    return _c.sendEnvelope(
      method: 'GET',
      path: '/v1/supplier/requests',
      query: query,
      decode: Paged.decoder(SupplierLead.fromJson),
    );
  }

  @override
  Future<ApiResult<SupplierLeadDetail>> leadDetail(String id) => _c.send(
    method: 'GET',
    path: '/v1/supplier/requests/$id',
    decode: (d) => SupplierLeadDetail.fromJson((d as Map).cast<String, dynamic>()),
  );

  @override
  Future<ApiResult<SupplierDashboardData>> dashboard() => _c.send(
    method: 'GET',
    path: '/v1/supplier/dashboard',
    decode: (d) => SupplierDashboardData.fromJson((d as Map).cast<String, dynamic>()),
  );

  @override
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
  }) {
    final body = <String, dynamic>{
      'pricePence': pricePence,
      'condition': condition.wire,
      if (warrantyMonths != null) 'warrantyMonths': warrantyMonths,
      'deliveryOption': deliveryOption.wire,
      if (deliveryTimeDays != null) 'deliveryTimeDays': deliveryTimeDays,
      'stockStatus': stockStatus.wire,
      'quantity': quantity,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    return _c.send(
      method: 'POST',
      path: '/v1/requests/$requestId/offers',
      body: body,
      decode: (d) => SupplierOffer.fromJson((d as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<ApiResult<Paged<SupplierOffer>>> listOffers({
    int page = 1,
    int limit = 20,
    OfferStatus? status,
  }) => _c.sendEnvelope(
    method: 'GET',
    path: '/v1/supplier/offers',
    query: {
      'page': '${page < 1 ? 1 : page}',
      'limit': '${limit.clamp(1, _maxLimit)}',
      if (status != null) 'status': status.wire,
    },
    decode: Paged.decoder(SupplierOffer.fromJson),
  );

  @override
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
  }) {
    final body = <String, dynamic>{
      if (pricePence != null) 'pricePence': pricePence,
      if (condition != null) 'condition': condition.wire,
      if (warrantyMonths != null) 'warrantyMonths': warrantyMonths,
      if (deliveryOption != null) 'deliveryOption': deliveryOption.wire,
      if (deliveryTimeDays != null) 'deliveryTimeDays': deliveryTimeDays,
      if (stockStatus != null) 'stockStatus': stockStatus.wire,
      if (quantity != null) 'quantity': quantity,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    return _c.send(
      method: 'PATCH',
      path: '/v1/offers/$offerId',
      body: body,
      decode: (d) => SupplierOffer.fromJson((d as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<ApiResult<SupplierOffer>> withdrawOffer(String offerId) => _c.send(
    method: 'POST',
    path: '/v1/offers/$offerId/withdraw',
    decode: (d) => SupplierOffer.fromJson((d as Map).cast<String, dynamic>()),
  );
}

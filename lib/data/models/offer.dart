import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/request_enums.dart';

/// The supplier projection on an offer: offers are included with
/// `{id, name, supplierProfile: {businessName}}` (orders.service.ts:99), so
/// [businessName] is read out of that nested object and both names are
/// nullable. There is no `displayName` getter here — choosing which name to
/// show is presentation and lives in the widget layer (DRY rule 5).
class OfferSupplier {
  const OfferSupplier({required this.id, this.name, this.businessName});

  final String id;
  final String? name;
  final String? businessName;

  factory OfferSupplier.fromJson(Map<String, dynamic> j) {
    final profile = j['supplierProfile'];
    return OfferSupplier(
      id: jsonString(j, 'id'),
      name: j['name'] as String?,
      businessName: profile is Map ? profile['businessName'] as String? : null,
    );
  }
}

/// `GET /v1/requests/{id}/offers` — a bare, unpaginated array.
///
/// Money is integer pence throughout. There is no `price` string and no
/// `deliveryFee`: no such column exists anywhere in the schema.
class Offer {
  const Offer({
    required this.id,
    required this.requestId,
    required this.supplierId,
    required this.pricePence,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.supplier,
    this.condition,
    this.warrantyMonths,
    this.deliveryOption,
    this.deliveryTimeDays,
    this.stockStatus,
    this.notes,
    this.status,
  });

  final String id;
  final String requestId;
  final String supplierId;
  final int pricePence;
  final PartCondition? condition;
  final int? warrantyMonths;
  final DeliveryOption? deliveryOption;
  final int? deliveryTimeDays;
  final StockStatus? stockStatus;
  final int quantity;
  final String? notes;
  final OfferStatus? status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OfferSupplier supplier;

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
    id: jsonString(j, 'id'),
    requestId: jsonString(j, 'requestId'),
    supplierId: jsonString(j, 'supplierId'),
    pricePence: (j['pricePence'] as num?)?.toInt() ?? 0,
    condition: PartCondition.fromWire(j['condition'] as String?),
    warrantyMonths: (j['warrantyMonths'] as num?)?.toInt(),
    deliveryOption: DeliveryOption.fromWire(j['deliveryOption'] as String?),
    deliveryTimeDays: (j['deliveryTimeDays'] as num?)?.toInt(),
    stockStatus: StockStatus.fromWire(j['stockStatus'] as String?),
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
    notes: j['notes'] as String?,
    status: OfferStatus.fromWire(j['status'] as String?),
    createdAt: DateTime.parse(jsonString(j, 'createdAt')),
    updatedAt: DateTime.parse(jsonString(j, 'updatedAt')),
    supplier: OfferSupplier.fromJson(
      (j['supplier'] as Map).cast<String, dynamic>(),
    ),
  );
}

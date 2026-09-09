import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/part_request.dart' show RequestImage;
import 'package:autonect/data/models/request_enums.dart';

/// The supplier projection on an offer: offers are included with
/// `{id, name, supplierProfile: {businessName}}` (orders.service.ts:99), so
/// [businessName] is read out of that nested object and both names are
/// nullable. There is no `displayName` getter here — choosing which name to
/// show is presentation and lives in the widget layer (DRY rule 5).
class OfferSupplier {
  const OfferSupplier({
    required this.id,
    this.name,
    this.businessName,
    this.ratingAvg,
    this.ratingCount,
  });

  final String id;
  final String? name;
  final String? businessName;

  /// Only `GET /v1/buyer/offers` selects these; the per-request route projects
  /// `{businessName}` alone. Both null therefore means "this route did not ask
  /// for a rating", NOT "this supplier is unrated" — a card must omit the
  /// rating rather than render a zero.
  final double? ratingAvg;
  final int? ratingCount;

  factory OfferSupplier.fromJson(Map<String, dynamic> j) {
    final profile = j['supplierProfile'];
    final p = profile is Map ? profile : const {};
    return OfferSupplier(
      id: jsonString(j, 'id'),
      name: j['name'] as String?,
      businessName: p['businessName'] as String?,
      ratingAvg: (p['ratingAvg'] as num?)?.toDouble(),
      ratingCount: (p['ratingCount'] as num?)?.toInt(),
    );
  }
}

/// The request an offer answers, as projected by `GET /v1/buyer/offers`.
///
/// A cross-request feed needs it: an offer on its own carries a price and
/// nothing a buyer could match to a car or a part. Not the full [PartRequest]
/// — the route selects six fields and inventing the rest would mean a model
/// whose required fields the server never sends.
class OfferRequestRef {
  const OfferRequestRef({
    required this.id,
    required this.partName,
    required this.regNumber,
    this.status,
    this.make,
    this.model,
    this.categoryName,
    this.images = const <RequestImage>[],
  });

  final String id;
  final String partName;
  final String regNumber;
  final RequestStatus? status;

  /// Both nullable, and the vehicle itself is absent on a manual-reg request.
  final String? make;
  final String? model;
  final String? categoryName;

  /// The BUYER's own photos of the part they asked for, newest projection
  /// first. Empty rather than null, and empty is the normal case twice over: a
  /// request may genuinely carry no photos, and a server that has not yet added
  /// images to the buyer-offers projection sends the key at all — which is why
  /// nothing downstream may assume a first element.
  ///
  /// Reuses [RequestImage] rather than a second two-field class, so the
  /// url-is-a-short-presign / cache-against-the-KEY rule is documented once.
  final List<RequestImage> images;

  factory OfferRequestRef.fromJson(Map<String, dynamic> j) {
    final vehicle = j['vehicle'];
    final category = j['category'];
    final images = j['images'];
    return OfferRequestRef(
      id: jsonString(j, 'id'),
      partName: jsonString(j, 'partName'),
      regNumber: jsonString(j, 'regNumber'),
      status: RequestStatus.fromWire(j['status'] as String?),
      make: vehicle is Map ? vehicle['make'] as String? : null,
      model: vehicle is Map ? vehicle['model'] as String? : null,
      categoryName: category is Map ? category['name'] as String? : null,
      images: images is List
          ? images
                .map((e) =>
                    RequestImage.fromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false)
          : const <RequestImage>[],
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
    this.request,
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

  /// Present ONLY on the cross-request feed. Null from
  /// `GET /v1/requests/:id/offers`, where the caller already holds the request
  /// it asked about.
  final OfferRequestRef? request;

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
    request: j['request'] is Map
        ? OfferRequestRef.fromJson((j['request'] as Map).cast<String, dynamic>())
        : null,
  );
}

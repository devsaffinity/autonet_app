import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/vehicle.dart';

/// The teaser projection returned by `GET /v1/supplier/requests`.
///
/// Notice the paid details (`buyer`, `regNumber`, `images`) are deliberately
/// omitted server-side in TEASER_SELECT so they do not leak into the feed.
class SupplierLead {
  const SupplierLead({
    required this.id,
    required this.partName,
    required this.offerCount,
    required this.createdAt,
    this.region,
    this.condition,
    this.urgency,
    this.category,
    this.vehicleMake,
    this.vehicleYear,
    this.isUnlocked = false,
  });

  final String id;
  final String partName;
  final int offerCount;
  final DateTime createdAt;
  final Region? region;
  final PartCondition? condition;
  final RequestUrgency? urgency;
  final RequestCategoryRef? category;
  final String? vehicleMake;
  final int? vehicleYear;
  final bool isUnlocked;

  SupplierLead copyWith({bool? isUnlocked}) => SupplierLead(
    id: id,
    partName: partName,
    offerCount: offerCount,
    createdAt: createdAt,
    region: region,
    condition: condition,
    urgency: urgency,
    category: category,
    vehicleMake: vehicleMake,
    vehicleYear: vehicleYear,
    isUnlocked: isUnlocked ?? this.isUnlocked,
  );

  factory SupplierLead.fromJson(Map<String, dynamic> j) {
    final cat = j['category'];
    final veh = j['vehicle'];
    return SupplierLead(
      id: jsonString(j, 'id'),
      partName: jsonString(j, 'partName'),
      offerCount: (j['offerCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(jsonString(j, 'createdAt')),
      region: Region.fromWire(j['region'] as String?),
      condition: PartCondition.fromWire(j['condition'] as String?),
      urgency: RequestUrgency.fromWire(j['urgency'] as String?),
      category: cat is Map
          ? RequestCategoryRef.fromJson(cat.cast<String, dynamic>())
          : null,
      vehicleMake: veh is Map ? veh['make'] as String? : null,
      vehicleYear: veh is Map ? (veh['year'] as num?)?.toInt() : null,
    );
  }
}

/// The buyer projection embedded in full request detail (`supplierFeedService.requestDetail`).
class SupplierLeadBuyer {
  const SupplierLeadBuyer({
    required this.id,
    this.name,
    this.memberSince,
  });

  final String id;
  final String? name;
  final DateTime? memberSince;

  factory SupplierLeadBuyer.fromJson(Map<String, dynamic> j) =>
      SupplierLeadBuyer(
        id: jsonString(j, 'id'),
        name: j['name'] as String?,
        memberSince: j['memberSince'] != null
            ? DateTime.tryParse(j['memberSince'] as String)
            : null,
      );
}

/// Full unlocked request detail returned by `GET /v1/supplier/requests/:id`.
class SupplierLeadDetail {
  const SupplierLeadDetail({
    required this.id,
    required this.buyerId,
    required this.regNumber,
    required this.partName,
    required this.offerCount,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.buyer,
    required this.images,
    this.partNumber,
    this.condition,
    this.urgency,
    this.description,
    this.region,
    this.vehicle,
  });

  final String id;
  final String buyerId;
  final String regNumber;
  final String partName;
  final String? partNumber;
  final PartCondition? condition;
  final RequestUrgency? urgency;
  final String? description;
  final Region? region;
  final int offerCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RequestCategoryRef category;
  final Vehicle? vehicle;
  final List<String> images;
  final SupplierLeadBuyer buyer;

  factory SupplierLeadDetail.fromJson(Map<String, dynamic> j) {
    final cat = j['category'];
    final veh = j['vehicle'];
    final b = j['buyer'];
    final imgs = j['images'];
    return SupplierLeadDetail(
      id: jsonString(j, 'id'),
      buyerId: jsonString(j, 'buyerId'),
      regNumber: jsonString(j, 'regNumber'),
      partName: jsonString(j, 'partName'),
      partNumber: j['partNumber'] as String?,
      condition: PartCondition.fromWire(j['condition'] as String?),
      urgency: RequestUrgency.fromWire(j['urgency'] as String?),
      description: j['description'] as String?,
      region: Region.fromWire(j['region'] as String?),
      offerCount: (j['offerCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(jsonString(j, 'createdAt')),
      updatedAt: DateTime.parse(jsonString(j, 'updatedAt')),
      category: RequestCategoryRef.fromJson(
        (cat as Map).cast<String, dynamic>(),
      ),
      vehicle: veh is Map
          ? Vehicle.fromJson(veh.cast<String, dynamic>())
          : null,
      images: imgs is List
          ? imgs.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      buyer: SupplierLeadBuyer.fromJson(
        (b as Map).cast<String, dynamic>(),
      ),
    );
  }
}

/// Metrics counters returned by `GET /v1/supplier/dashboard`.
class SupplierDashboardData {
  const SupplierDashboardData({
    required this.incomingRequests,
    required this.activeNegotiations,
    required this.creditBalance,
    required this.subscribed,
    required this.todaysEarningsPence,
  });

  final int incomingRequests;
  final int activeNegotiations;
  final int creditBalance;
  final bool subscribed;
  final int todaysEarningsPence;

  factory SupplierDashboardData.fromJson(Map<String, dynamic> j) =>
      SupplierDashboardData(
        incomingRequests: (j['incomingRequests'] as num?)?.toInt() ?? 0,
        activeNegotiations: (j['activeNegotiations'] as num?)?.toInt() ?? 0,
        creditBalance: (j['creditBalance'] as num?)?.toInt() ?? 0,
        subscribed: j['subscribed'] as bool? ?? false,
        todaysEarningsPence: (j['todaysEarningsPence'] as num?)?.toInt() ?? 0,
      );
}

/// The request summary attached to a supplier offer (`GET /v1/supplier/offers`).
class SupplierOfferRequestRef {
  const SupplierOfferRequestRef({
    required this.id,
    required this.partName,
    required this.offerCount,
    this.status,
    this.region,
  });

  final String id;
  final String partName;
  final RequestStatus? status;
  final Region? region;
  final int offerCount;

  factory SupplierOfferRequestRef.fromJson(Map<String, dynamic> j) =>
      SupplierOfferRequestRef(
        id: jsonString(j, 'id'),
        partName: jsonString(j, 'partName'),
        status: RequestStatus.fromWire(j['status'] as String?),
        region: Region.fromWire(j['region'] as String?),
        offerCount: (j['offerCount'] as num?)?.toInt() ?? 0,
      );
}

/// A supplier's own submitted offer (`GET /v1/supplier/offers`).
class SupplierOffer {
  const SupplierOffer({
    required this.id,
    required this.requestId,
    required this.supplierId,
    required this.pricePence,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    this.condition,
    this.warrantyMonths,
    this.deliveryOption,
    this.deliveryTimeDays,
    this.stockStatus,
    this.notes,
    this.status,
    this.request,
  });

  final String id;
  final String requestId;
  final String supplierId;
  final int pricePence;
  final int quantity;
  final PartCondition? condition;
  final int? warrantyMonths;
  final DeliveryOption? deliveryOption;
  final int? deliveryTimeDays;
  final StockStatus? stockStatus;
  final String? notes;
  final OfferStatus? status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SupplierOfferRequestRef? request;

  factory SupplierOffer.fromJson(Map<String, dynamic> j) {
    final req = j['request'];
    return SupplierOffer(
      id: jsonString(j, 'id'),
      requestId: jsonString(j, 'requestId'),
      supplierId: jsonString(j, 'supplierId'),
      pricePence: (j['pricePence'] as num?)?.toInt() ?? 0,
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      condition: PartCondition.fromWire(j['condition'] as String?),
      warrantyMonths: (j['warrantyMonths'] as num?)?.toInt(),
      deliveryOption: DeliveryOption.fromWire(j['deliveryOption'] as String?),
      deliveryTimeDays: (j['deliveryTimeDays'] as num?)?.toInt(),
      stockStatus: StockStatus.fromWire(j['stockStatus'] as String?),
      notes: j['notes'] as String?,
      status: OfferStatus.fromWire(j['status'] as String?),
      createdAt: DateTime.parse(jsonString(j, 'createdAt')),
      updatedAt: DateTime.parse(jsonString(j, 'updatedAt')),
      request: req is Map
          ? SupplierOfferRequestRef.fromJson(req.cast<String, dynamic>())
          : null,
    );
  }
}

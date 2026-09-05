import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/vehicle.dart';

/// One photo attached to a request — the `{s3Key}` projection at
/// requests.service.ts:20.
///
/// There is deliberately NO `url`: requests.service.ts never calls
/// `storage.createDownloadUrl`, so a buyer cannot render their own photos yet.
/// It stays a class rather than collapsing to a bare `List<String>` because the
/// supplier feed signs the same images and returns a second field; a flattened
/// list would force a re-model the moment that lands.
class RequestImage {
  const RequestImage({required this.s3Key});

  final String s3Key;

  factory RequestImage.fromJson(Map<String, dynamic> j) =>
      RequestImage(s3Key: jsonString(j, 's3Key'));
}

/// A buyer's part request: the shape returned by `POST /v1/requests`,
/// `GET /v1/requests`, `GET /v1/requests/{id}` and `PATCH /v1/requests/{id}`,
/// all of which share REQUEST_INCLUDE.
class PartRequest {
  const PartRequest({
    required this.id,
    required this.buyerId,
    required this.regNumber,
    required this.categoryId,
    required this.partName,
    required this.offerCount,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.images,
    this.vehicleId,
    this.region,
    this.partNumber,
    this.condition,
    this.urgency,
    this.description,
    this.status,
    this.vehicle,
  });

  final String id;
  final String buyerId;

  /// Server-normalised (uppercase, no whitespace) by `normalizeReg`. Do not
  /// normalise again on read — the display value is the stored value.
  final String regNumber;
  final String? vehicleId;
  final String categoryId;
  final Region? region;
  final String partName;
  final String? partNumber;
  final PartCondition? condition;
  final RequestUrgency? urgency;
  final String? description;
  final RequestStatus? status;

  /// Maintained by the backend on every offer write — the "Requests with
  /// offers" section reads this, never an N+1 fan-out over the offers route.
  final int offerCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Vehicle? vehicle;
  final RequestCategoryRef category;
  final List<RequestImage> images;

  bool get isOpen => status == RequestStatus.open;

  factory PartRequest.fromJson(Map<String, dynamic> j) {
    final vehicle = j['vehicle'];
    final images = j['images'];
    return PartRequest(
      id: jsonString(j, 'id'),
      buyerId: jsonString(j, 'buyerId'),
      regNumber: jsonString(j, 'regNumber'),
      vehicleId: j['vehicleId'] as String?,
      categoryId: jsonString(j, 'categoryId'),
      region: Region.fromWire(j['region'] as String?),
      partName: jsonString(j, 'partName'),
      partNumber: j['partNumber'] as String?,
      condition: PartCondition.fromWire(j['condition'] as String?),
      urgency: RequestUrgency.fromWire(j['urgency'] as String?),
      description: j['description'] as String?,
      status: RequestStatus.fromWire(j['status'] as String?),
      offerCount: (j['offerCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(jsonString(j, 'createdAt')),
      updatedAt: DateTime.parse(jsonString(j, 'updatedAt')),
      vehicle: vehicle is Map
          ? Vehicle.fromJson(vehicle.cast<String, dynamic>())
          : null,
      category: RequestCategoryRef.fromJson(
        (j['category'] as Map).cast<String, dynamic>(),
      ),
      images: images is List
          ? images
                .map((e) => RequestImage.fromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false)
          : const <RequestImage>[],
    );
  }
}

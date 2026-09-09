import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/vehicle.dart';

/// One photo attached to a request — the `{s3Key, url}` projection
/// `withSignedImages` produces in requests.service.ts.
///
/// The url arrived late: the service returned bare keys against a private
/// bucket for the whole of phase 1, so a buyer could not render the photos they
/// had themselves uploaded while a supplier who unlocked the lead could. Both
/// fields are kept rather than flattening to a url string, because the KEY is
/// what a cache must be keyed on — see [url].
class RequestImage {
  const RequestImage({required this.s3Key, this.url});

  final String s3Key;

  /// A PRESIGNED GET, short-lived. Nullable because a server older than the
  /// signing change sends only the key, and a buyer on a new build must degrade
  /// to the placeholder rather than crash.
  ///
  /// Cache decoded images against [s3Key], never against this: the url changes
  /// on every read, so keying on it re-downloads every time and serves 403s
  /// from anything that held onto an expired one.
  final String? url;

  bool get isRenderable => url != null && url!.isNotEmpty;

  factory RequestImage.fromJson(Map<String, dynamic> j) => RequestImage(
    s3Key: jsonString(j, 's3Key'),
    url: j['url'] as String?,
  );
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

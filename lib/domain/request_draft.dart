import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/pending_image.dart';
import 'package:autonect/domain/reg_number.dart';

/// The wizard's whole state, and the ONE place a create body is built.
class RequestDraft {
  RequestDraft({
    this.regNumber = '',
    this.categoryId,
    this.categoryName,
    this.region,
    this.partName = '',
    this.partNumber,
    this.condition,
    this.urgency,
    this.description,
    this.vehicleModel,
    this.vehicleMake,
    this.vehicleYear,
    this.vehicleFuel,
    this.vehicleColour,
    this.isCustomVehicle = false,
    this.manualModelRequired = false,
    List<PendingImage>? images,
    this.step = 0,
    DateTime? updatedAt,
  }) : images = images ?? <PendingImage>[],
       updatedAt = updatedAt ?? DateTime.now();

  String regNumber;
  String? categoryId;

  /// Shown on the confirm step so it needs no second fetch; never sent.
  String? categoryName;
  Region? region;
  String partName;
  String? partNumber;
  PartCondition? condition;
  RequestUrgency? urgency;
  String? description;
  String? vehicleModel;
  String? vehicleMake;
  int? vehicleYear;
  String? vehicleFuel;
  String? vehicleColour;
  bool isCustomVehicle;
  bool manualModelRequired;
  List<PendingImage> images;
  int step;
  DateTime updatedAt;

  /// Older than this the draft is discarded: a day-old wizard is a different
  /// intent, and its S3 keys may already have been swept.
  static const Duration maxRestoreAge = Duration(hours: 24);

  bool isRestorableAt(DateTime now) =>
      now.difference(updatedAt) < maxRestoreAge;

  /// The draft keys each wizard step is answerable for.
  ///
  /// [validate] checks the WHOLE draft, which is right at submit and wrong at a
  /// step gate: step 2 must not refuse to advance over a registration typed on
  /// step 1, and step 1 must not refuse over a category the buyer has not been
  /// shown yet. Together these two sets are every key [validate] can emit — a
  /// key in neither would be unreachable at any gate and still fail at submit.
  static const Set<String> vehicleStepKeys = {'regNumber', 'vehicleModel'};
  static const Set<String> partStepKeys = {
    'partName', 'partNumber', 'categoryId', 'region', 'condition', 'urgency',
    'description',
  };

  /// The subset of [validate] belonging to [keys] — the gate for one step.
  Map<String, String> validateStep(Set<String> keys) => {
    for (final e in validate().entries)
      if (keys.contains(e.key)) e.key: e.value,
  };

  /// Errors keyed by THE SERVER'S OWN path strings, so a local error and a
  /// `details[]` error land in one map that one form renders.
  Map<String, String> validate() {
    final e = <String, String>{};
    if (!isValidReg(regNumber)) e['regNumber'] = 'Enter a valid UK registration';
    final category = categoryId?.trim() ?? '';
    if (category.isEmpty) e['categoryId'] = 'Choose a part category';
    if (region == null) e['region'] = 'Choose your region';
    final name = partName.trim();
    if (name.length < 2) {
      e['partName'] = 'Part name must be at least 2 characters';
    } else if (name.length > 150) {
      e['partName'] = 'Part name must be 150 characters or fewer';
    }
    final number = partNumber?.trim() ?? '';
    if (number.isNotEmpty && number.length > 80) {
      e['partNumber'] = 'Part number must be 80 characters or fewer';
    }
    if ((description?.trim().length ?? 0) > 2000) {
      e['description'] = 'Description must be 2000 characters or fewer';
    }
    if (condition == null) e['condition'] = 'Choose a part condition';
    if (urgency == null) e['urgency'] = 'Choose how urgent this is';
    if (isCustomVehicle) {
      final make = vehicleMake?.trim() ?? '';
      if (make.isEmpty) {
        e['vehicleMake'] = 'Enter the vehicle make';
      }
      final model = vehicleModel?.trim() ?? '';
      if (model.isEmpty) {
        e['vehicleModel'] = 'Enter the vehicle model';
      }
    } else if (manualModelRequired) {
      final model = vehicleModel?.trim() ?? '';
      if (model.isEmpty) {
        e['vehicleModel'] = 'Enter the vehicle model';
      } else if (model.length > 80) {
        e['vehicleModel'] = 'Vehicle model must be 80 characters or fewer';
      }
    }
    return e;
  }

  /// The ONE place `POST /v1/requests` body is constructed; call it only when
  /// [validate] returned an empty map.
  Map<String, dynamic> toBody() {
    final categoryId = this.categoryId;
    final region = this.region;
    final condition = this.condition;
    final urgency = this.urgency;
    if (categoryId == null || region == null || condition == null ||
        urgency == null) {
      throw StateError('toBody() on an invalid draft: ${validate().keys}');
    }
    final number = partNumber?.trim() ?? '';
    final desc = description?.trim() ?? '';
    final model = vehicleModel?.trim() ?? '';
    final make = vehicleMake?.trim() ?? '';
    final fuel = vehicleFuel?.trim() ?? '';
    final colour = vehicleColour?.trim() ?? '';
    return {
      'regNumber': normaliseReg(regNumber),
      'categoryId': categoryId,
      'region': region.wire,
      'partName': partName.trim(),
      'condition': condition.wire,
      'urgency': urgency.wire,
      if (number.isNotEmpty) 'partNumber': number,
      if (desc.isNotEmpty) 'description': desc,
      if ((manualModelRequired || isCustomVehicle) && model.isNotEmpty) 'vehicleModel': model,
      if (isCustomVehicle && make.isNotEmpty) 'vehicleMake': make,
      if (isCustomVehicle && vehicleYear != null) 'vehicleYear': vehicleYear,
      if (isCustomVehicle && fuel.isNotEmpty) 'vehicleFuel': fuel,
      if (isCustomVehicle && colour.isNotEmpty) 'vehicleColour': colour,
      'imageKeys': uploadedKeys,
    };
  }

  /// Only `uploaded` slots contribute; a failed slot must not send a key.
  List<String> get uploadedKeys => [
    for (final i in images)
      if (i.status == ImageUploadStatus.uploaded) ?i.s3Key,
  ];

  Map<String, dynamic> toJson() => {
    'regNumber': regNumber,
    if (categoryId != null) 'categoryId': categoryId,
    if (categoryName != null) 'categoryName': categoryName,
    if (region != null) 'region': region?.wire,
    
    'partName': partName,
    if (partNumber != null) 'partNumber': partNumber,
    if (condition != null) 'condition': condition?.wire,
    if (urgency != null) 'urgency': urgency?.wire,
    if (description != null) 'description': description,
    if (vehicleModel != null) 'vehicleModel': vehicleModel,
    if (vehicleMake != null) 'vehicleMake': vehicleMake,
    if (vehicleYear != null) 'vehicleYear': vehicleYear,
    if (vehicleFuel != null) 'vehicleFuel': vehicleFuel,
    if (vehicleColour != null) 'vehicleColour': vehicleColour,
    'isCustomVehicle': isCustomVehicle,
    'manualModelRequired': manualModelRequired,
    'images': [for (final i in images) i.toJson()],
    'step': step,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory RequestDraft.fromJson(Map<String, dynamic> j) {
    final rawImages = j['images'];
    final rawUpdatedAt = j['updatedAt'];
    return RequestDraft(
      regNumber: (j['regNumber'] as String?) ?? '',
      categoryId: j['categoryId'] as String?,
      categoryName: j['categoryName'] as String?,
      region: Region.fromWire(j['region'] as String?),
      partName: (j['partName'] as String?) ?? '',
      partNumber: j['partNumber'] as String?,
      condition: PartCondition.fromWire(j['condition'] as String?),
      urgency: RequestUrgency.fromWire(j['urgency'] as String?),
      description: j['description'] as String?,
      vehicleModel: j['vehicleModel'] as String?,
      vehicleMake: j['vehicleMake'] as String?,
      vehicleYear: (j['vehicleYear'] as num?)?.toInt(),
      vehicleFuel: j['vehicleFuel'] as String?,
      vehicleColour: j['vehicleColour'] as String?,
      isCustomVehicle: j['isCustomVehicle'] == true,
      manualModelRequired: j['manualModelRequired'] == true,
      images: rawImages is List
          ? [
              for (final i in rawImages)
                PendingImage.fromJson((i as Map).cast<String, dynamic>()),
            ]
          : <PendingImage>[],
      step: (j['step'] as num?)?.toInt() ?? 0,
      updatedAt: rawUpdatedAt is String
          ? (DateTime.tryParse(rawUpdatedAt) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

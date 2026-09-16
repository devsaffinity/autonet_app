import 'package:autonect/constants/app_images.dart';
import 'package:autonect/data/models/booking_enums.dart';

class ElectricianService {
  const ElectricianService({
    required this.id,
    required this.electricianId,
    required this.name,
    required this.price,
    this.pricePence,
    required this.pricingType,
    this.serviceType,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String electricianId;
  final String name;
  final String price;
  final int? pricePence;
  final String pricingType;
  final BookingServiceType? serviceType;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Returns the matching SVG asset icon based on service category/keywords
  String get iconAsset {
    final lower = name.toLowerCase();
    if (serviceType == BookingServiceType.ecuCoding ||
        lower.contains('ecu') ||
        lower.contains('remap') ||
        lower.contains('tuning') ||
        lower.contains('tune') ||
        lower.contains('coding')) {
      return Assets.imagesMsA;
    }
    if (serviceType == BookingServiceType.diagnostic ||
        lower.contains('diagnostic') ||
        lower.contains('sweep') ||
        lower.contains('scan') ||
        lower.contains('fault') ||
        lower.contains('code')) {
      return Assets.imagesMsB;
    }
    return Assets.imagesMsC;
  }

  factory ElectricianService.fromJson(Map<String, dynamic> json) {
    return ElectricianService(
      id: json['id'] as String? ?? '',
      electricianId: json['electricianId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: json['price'] as String? ?? '',
      pricePence: (json['pricePence'] as num?)?.toInt(),
      pricingType: json['pricingType'] as String? ?? 'Fixed Price',
      serviceType: BookingServiceType.fromWire(json['serviceType'] as String?),
      description: json['description'] as String?,
      isActive: json['isActive'] != false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'electricianId': electricianId,
    'name': name,
    'price': price,
    if (pricePence != null) 'pricePence': pricePence,
    'pricingType': pricingType,
    if (serviceType != null) 'serviceType': serviceType!.wire,
    if (description != null) 'description': description,
    'isActive': isActive,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  ElectricianService copyWith({
    String? id,
    String? electricianId,
    String? name,
    String? price,
    int? pricePence,
    String? pricingType,
    BookingServiceType? serviceType,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ElectricianService(
      id: id ?? this.id,
      electricianId: electricianId ?? this.electricianId,
      name: name ?? this.name,
      price: price ?? this.price,
      pricePence: pricePence ?? this.pricePence,
      pricingType: pricingType ?? this.pricingType,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

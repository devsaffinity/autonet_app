import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/electrician_service.dart';
import 'package:autonect/data/models/request_enums.dart';

/// An approved electrician from `GET /v1/providers`.
///
/// Named ServiceProvider, not Electrician: the comp calls the section 'Service
/// Providers', and the row it is backed by is ElectricianProfile. Keeping the
/// UI's word here means the section, the model and the repository all say the
/// same thing.
///
/// Only `id` and `fullName` are non-null on the wire. DVLA-style optionality
/// runs right through this table — a provider can register without a location,
/// without brands and without ever being reviewed — so every widget reading
/// this must degrade rather than blank.
class ServiceProvider {
  const ServiceProvider({
    required this.id,
    required this.fullName,
    required this.brands,
    required this.ratingAvg,
    required this.ratingCount,
    required this.skills,
    required this.services,
    this.customServices = const [],
    this.tier = 'FREE',
    this.headline,
    this.bio,
    this.vehiclesServiced,
    this.location,
    this.region,
    this.yearsExperience,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String tier;

  /// Manufacturers serviced. Empty is normal, not an error.
  final List<String> brands;

  /// Server default is 0 for both, so these are non-null — but a 0/0 pair means
  /// UNRATED, not 'rated zero'. [isRated] is the only correct way to ask.
  final double ratingAvg;
  final int ratingCount;

  final String? location;
  final Region? region;
  final int? yearsExperience;

  /// The trade line under the name — 'ECU Specialist'. Free text, and absent
  /// on every provider who registered before the column existed.
  final String? headline;

  /// The profile's 'Expertise Profile' paragraph.
  final String? bio;

  /// What they DO — 'Coding', 'Remapping'. Distinct from [brands], which is
  /// what they do it TO. Empty is normal.
  final List<String> skills;

  /// The '1240+ Vehicles Serviced' counter. Null means they have not said,
  /// which is not the same as none.
  final int? vehiclesServiced;

  /// Which callouts they take. This is what the directory's service chips
  /// filter on, and what separates a 'Coder' (ecuCoding) from a plain
  /// electrician — one provider table, filtered, not two populations.
  final List<BookingServiceType> services;

  /// Real custom services added by this provider, with active pricing, custom
  /// titles and descriptions. Empty for providers who haven't added custom services.
  final List<ElectricianService> customServices;

  /// A PRESIGNED GET when the provider uploaded a photo, a plain external url
  /// on older rows, and null when they have neither. Short-lived either way, so
  /// cache it against [id] rather than the url.
  final String? avatarUrl;

  /// A rating is only meaningful once something is behind it. The card shows
  /// nothing rather than '0.0/5.0' for a provider nobody has reviewed.
  bool get isRated => ratingCount > 0;

  /// Whether the provider is currently on the PRO subscription tier.
  bool get isPro => tier.toUpperCase() == 'PRO';

  factory ServiceProvider.fromJson(Map<String, dynamic> j) => ServiceProvider(
    id: jsonString(j, 'id'),
    fullName: jsonString(j, 'fullName'),
    brands: switch (j['brands']) {
      final List<dynamic> list => list.whereType<String>().toList(growable: false),
      _ => const <String>[],
    },
    ratingAvg: (j['ratingAvg'] as num?)?.toDouble() ?? 0,
    ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
    headline: j['headline'] as String?,
    bio: j['bio'] as String?,
    skills: switch (j['skills']) {
      final List<dynamic> list => list.whereType<String>().toList(growable: false),
      _ => const <String>[],
    },
    vehiclesServiced: (j['vehiclesServiced'] as num?)?.toInt(),
    // Unknown enum members are DROPPED, not crashed on: /v1 lets enums grow,
    // so a server that adds a sixth callout must not break an older client.
    services: switch (j['services']) {
      final List<dynamic> list => list
          .whereType<String>()
          .map(BookingServiceType.fromWire)
          .whereType<BookingServiceType>()
          .toList(growable: false),
      _ => const <BookingServiceType>[],
    },
    customServices: switch (j['customServices']) {
      final List<dynamic> list => list
          .whereType<Map>()
          .map((m) => ElectricianService.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false),
      _ => const <ElectricianService>[],
    },
    location: j['location'] as String?,
    region: Region.fromWire(j['region'] as String?),
    yearsExperience: (j['yearsExperience'] as num?)?.toInt(),
    avatarUrl: j['avatarUrl'] as String?,
    tier: (j['tier'] as String?) ?? 'FREE',
  );
}

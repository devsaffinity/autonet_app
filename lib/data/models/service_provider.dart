import 'package:autonect/data/models/auth_user.dart' show jsonString;
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
    this.location,
    this.region,
    this.yearsExperience,
    this.avatarUrl,
  });

  final String id;
  final String fullName;

  /// Manufacturers serviced. Empty is normal, not an error.
  final List<String> brands;

  /// Server default is 0 for both, so these are non-null — but a 0/0 pair means
  /// UNRATED, not 'rated zero'. [isRated] is the only correct way to ask.
  final double ratingAvg;
  final int ratingCount;

  final String? location;
  final Region? region;
  final int? yearsExperience;

  /// A PRESIGNED GET when the provider uploaded a photo, a plain external url
  /// on older rows, and null when they have neither. Short-lived either way, so
  /// cache it against [id] rather than the url.
  final String? avatarUrl;

  /// A rating is only meaningful once something is behind it. The card shows
  /// nothing rather than '0.0/5.0' for a provider nobody has reviewed.
  bool get isRated => ratingCount > 0;

  factory ServiceProvider.fromJson(Map<String, dynamic> j) => ServiceProvider(
    id: jsonString(j, 'id'),
    fullName: jsonString(j, 'fullName'),
    brands: switch (j['brands']) {
      final List<dynamic> list => list.whereType<String>().toList(growable: false),
      _ => const <String>[],
    },
    ratingAvg: (j['ratingAvg'] as num?)?.toDouble() ?? 0,
    ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
    location: j['location'] as String?,
    region: Region.fromWire(j['region'] as String?),
    yearsExperience: (j['yearsExperience'] as num?)?.toInt(),
    avatarUrl: j['avatarUrl'] as String?,
  );
}

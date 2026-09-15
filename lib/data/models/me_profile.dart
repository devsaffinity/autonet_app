import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/auth_user.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/request_enums.dart';

/// Where a provider sits in review. Drives which screen a supplier lands on, so
/// an unknown value must NOT silently read as approved.
enum KycStatus {
  pending('PENDING', 'Pending'),
  submitted('SUBMITTED', 'Under review'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected');

  const KycStatus(this.wire, this.label);
  final String wire;
  final String label;

  static KycStatus? fromWire(String? v) =>
      enumFromWire(values, v, (e) => e.wire);
}

/// The supplier half of `GET /v1/me`.
///
/// Present only once `POST /v1/supplier/business` has been called. Its absence
/// is the signal that a supplier has an account but has never registered a
/// business — which is a different state from "registered, awaiting approval",
/// and the two land on different screens.
class SupplierProfile {
  const SupplierProfile({
    required this.businessName,
    required this.address,
    required this.regionsServed,
    required this.brands,
    required this.categories,
    required this.kycStatus,
    required this.approved,
    this.specialization,
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });

  final String businessName;
  final String address;
  final List<Region> regionsServed;
  final List<String> brands;
  final List<PartCategory> categories;

  /// Null when the server sent a value this build does not know. Treated as
  /// not-approved everywhere, never as approved — see [canEnterShell].
  final KycStatus? kycStatus;

  /// The ONLY field that grants shell access. `kycStatus == APPROVED` is not a
  /// substitute: an admin can revoke `approved` without moving the status.
  final bool approved;

  final String? specialization;
  final double ratingAvg;
  final int ratingCount;

  /// Server truth, and the only thing that should gate the supplier shell.
  bool get canEnterShell => approved;

  factory SupplierProfile.fromJson(Map<String, dynamic> j) {
    final regions = j['regionsServed'];
    final brands = j['brands'];
    final categories = j['categories'];
    return SupplierProfile(
      businessName: jsonString(j, 'businessName'),
      address: jsonString(j, 'address'),
      // An unrecognised region is dropped rather than failing the whole
      // profile: a server that adds a 13th region must not lock every existing
      // supplier out of the app until they update.
      regionsServed: regions is List
          ? [for (final r in regions) ?Region.fromWire(r as String?)]
          : const [],
      brands: brands is List ? brands.whereType<String>().toList() : const [],
      categories: categories is List
          ? [
              for (final c in categories)
                PartCategory.fromJson((c as Map).cast<String, dynamic>()),
            ]
          : const [],
      kycStatus: KycStatus.fromWire(j['kycStatus'] as String?),
      approved: j['approved'] == true,
      specialization: j['specialization'] as String?,
      ratingAvg: (j['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The electrician's side of `GET /v1/me`.
///
/// A SEPARATE class from [SupplierProfile] rather than a shared one: they
/// answer the same question — may this provider work — from different columns,
/// and a merged type would carry `businessName` and `categories` that an
/// electrician never has.
///
/// Decoded in full, because the provider now EDITS this. It used to carry only
/// the fields the client gated on, which was fine while nothing could author a
/// profile — an edit screen that cannot pre-fill makes a provider retype what
/// the server already holds.
class ElectricianProfile {
  const ElectricianProfile({
    required this.fullName,
    required this.approved,
    this.kycStatus,
    this.headline,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.bio,
    this.phone,
    this.location,
    this.region,
    this.yearsExperience,
    this.vehiclesServiced,
    this.tier = 'FREE',
    this.brands = const [],
    this.skills = const [],
    this.services = const [],
  });

  final String fullName;
  final String tier;

  /// The ONLY field that grants shell access, exactly as on the supplier side.
  /// `kycStatus == APPROVED` is not a substitute: an admin can revoke
  /// `approved` without moving the status.
  final bool approved;

  /// Null when the server sent a value this build does not know. Treated as
  /// not-approved everywhere, never as approved.
  final KycStatus? kycStatus;

  final String? headline;
  final double ratingAvg;
  final int ratingCount;

  /// EVERYTHING BELOW IS WHAT THE PROVIDER AUTHORS ABOUT THEMSELVES, and it is
  /// decoded so an edit screen can pre-fill from the server rather than making
  /// them retype a profile they already have. `/v1/me` has always returned the
  /// whole row; the client simply never read past the fields it gated on.
  final String? bio;
  final String? phone;
  final String? location;
  final Region? region;
  final int? yearsExperience;
  final int? vehiclesServiced;

  /// What they work ON.
  final List<String> brands;

  /// What they DO, in their own words.
  final List<String> skills;

  /// The callouts they take — the enum the buyer's filters use. Unknown wire
  /// values are dropped rather than rendered, so a value shipped server-side
  /// cannot put a broken chip on an older client.
  final List<BookingServiceType> services;

  bool get canEnterShell => approved;

  static List<String> _strings(Object? v) => ((v as List?) ?? const [])
      .map((e) => e?.toString())
      .whereType<String>()
      .toList();

  factory ElectricianProfile.fromJson(Map<String, dynamic> j) =>
      ElectricianProfile(
        fullName: jsonString(j, 'fullName'),
        approved: j['approved'] == true,
        kycStatus: KycStatus.fromWire(j['kycStatus'] as String?),
        headline: j['headline'] as String?,
        ratingAvg: (j['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
        bio: j['bio'] as String?,
        phone: j['phone'] as String?,
        location: j['location'] as String?,
        region: Region.fromWire(j['region'] as String?),
        yearsExperience: (j['yearsExperience'] as num?)?.toInt(),
        vehiclesServiced: (j['vehiclesServiced'] as num?)?.toInt(),
        tier: (j['tier'] as String?) ?? 'FREE',
        brands: _strings(j['brands']),
        skills: _strings(j['skills']),
        services: _strings(j['services'])
            .map(BookingServiceType.fromWire)
            .whereType<BookingServiceType>()
            .toList(),
      );
}

/// `GET /v1/me`.
///
/// Distinct from [AuthUser], which is decoded from the LOGIN payload and is
/// deliberately minimal. This is the fuller record, and it is the only source
/// of `avatarUrl` and of the supplier's approval state.
class MeProfile {
  const MeProfile({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.phone,
    this.location,
    this.avatarUrl,
    this.supplierProfile,
    this.electricianProfile,
  });

  final String id;
  final String email;

  /// RAW wire string, matching [AuthUser.role]: narrowing to AppRole here would
  /// make an ADMIN look like a corrupt payload.
  final String role;

  final String? name;
  final String? phone;
  final String? location;

  /// A PRESIGNED url with a short TTL, not a stable address. Cache the decoded
  /// image against the user id; caching against this string re-downloads on
  /// every read and serves 403s once it expires.
  final String? avatarUrl;

  /// Null for a buyer, and also for a supplier who has not registered a
  /// business yet.
  final SupplierProfile? supplierProfile;

  /// The server has always returned this; the client simply never decoded it,
  /// which is why an electrician entered the app on a LOCAL flag with no
  /// server-side approval check at all.
  final ElectricianProfile? electricianProfile;

  /// Whichever provider profile this account has, or null for a buyer.
  ///
  /// Exists so the routing and the awaiting-approval screen ask 'may this
  /// provider work' once, rather than branching on role at every call site.
  bool? get providerApproved =>
      supplierProfile?.canEnterShell ?? electricianProfile?.canEnterShell;

  /// True when a provider profile row exists at all — which is what
  /// 'onboarded' actually means, as against a local wizard-completed flag.
  bool get hasProviderProfile =>
      supplierProfile != null || electricianProfile != null;

  /// The KYC status of whichever provider profile exists.
  KycStatus? get providerKycStatus =>
      supplierProfile?.kycStatus ?? electricianProfile?.kycStatus;

  factory MeProfile.fromJson(Map<String, dynamic> j) {
    final supplier = j['supplierProfile'];
    return MeProfile(
      id: jsonString(j, 'id'),
      email: jsonString(j, 'email'),
      role: jsonString(j, 'role'),
      name: j['name'] as String?,
      phone: j['phone'] as String?,
      location: j['location'] as String?,
      avatarUrl: j['avatarUrl'] as String?,
      supplierProfile: supplier is Map
          ? SupplierProfile.fromJson(supplier.cast<String, dynamic>())
          : null,
      electricianProfile: j['electricianProfile'] is Map
          ? ElectricianProfile.fromJson(
              (j['electricianProfile'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}

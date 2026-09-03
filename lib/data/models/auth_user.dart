import 'package:autonect/constants/app_role.dart';

/// Strict on purpose: decodeEnvelope catches the FormatException and yields
/// ApiError.malformed rather than silently storing an empty token.
String jsonString(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v is String) return v;
  throw FormatException('Expected string at "$k", got ${v.runtimeType}');
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.name,
  });

  final String id;
  final String email;

  /// RAW wire string: BUYER|SUPPLIER|ELECTRICIAN|ADMIN. Deliberately NOT
  /// AppRole — AppRole.fromWire returns null for ADMIN (app_role.dart:19-25),
  /// and narrowing here would make an admin login look like a corrupt payload.
  final String role;

  /// PENDING_VERIFICATION|ACTIVE|SUSPENDED|BANNED|DELETED
  final String status;
  final String? name;

  bool get isPendingVerification => status == 'PENDING_VERIFICATION';

  AppRole? get appRole => AppRole.fromWire(role);

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: jsonString(j, 'id'),
    email: jsonString(j, 'email'),
    role: jsonString(j, 'role'),
    status: jsonString(j, 'status'),
    name: j['name'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'role': role,
    'status': status,
    'name': name,
  };
}

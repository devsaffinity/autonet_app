/// Mirrors the backend `enum Role` in prisma/schema.prisma
/// (BUYER | SUPPLIER | ELECTRICIAN | ADMIN). ADMIN is a web-console tier
/// and deliberately has no case here, so every switch over AppRole is
/// exhaustive with no `default:`.
///
/// This file imports nothing on purpose: routes, the controller and a future
/// lib/data/ API layer all need it, and any import here would create a cycle.
enum AppRole {
  buyer('BUYER', 'Buyer'),
  supplier('SUPPLIER', 'Supplier'),
  electrician('ELECTRICIAN', 'Electrician/ Coder');

  const AppRole(this.wire, this.label);

  /// Exact string the API sends and expects.
  final String wire;
  final String label;

  /// Returns null for an unknown value or for ADMIN, which has no app shell.
  static AppRole? fromWire(String? v) {
    for (final r in AppRole.values) {
      if (r.wire == v) return r;
    }
    return null;
  }
}

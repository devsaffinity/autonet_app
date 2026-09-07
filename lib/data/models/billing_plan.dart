import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/request_enums.dart' show enumFromWire;
import 'package:autonect/domain/money_format.dart';

/// How a plan is billed. Mirrors the backend `PlanInterval` enum.
enum PlanInterval {
  month('MONTH', '/mo'),
  year('YEAR', '/yr'),
  oneTime('ONE_TIME', ''),
  perLead('PER_LEAD', '/lead');

  const PlanInterval(this.wire, this.suffix);
  final String wire;

  /// Appended to the price, as the design does.
  final String suffix;

  static PlanInterval? fromWire(String? v) =>
      enumFromWire(values, v, (e) => e.wire);
}

/// One row of `GET /v1/billing/plans`.
class BillingPlan {
  const BillingPlan({
    required this.id,
    required this.lookupKey,
    required this.name,
    required this.pricePence,
    required this.interval,
    this.credits,
  });

  final String id;
  final String lookupKey;
  final String name;

  /// GBP, integer pence. The system is UK-only; there is no currency field on
  /// the wire because there is only one.
  final int pricePence;

  final PlanInterval? interval;

  /// Credits granted per purchase — credit packs only, null on subscriptions.
  final int? credits;

  bool get isCreditPack => credits != null && credits! > 0;

  /// '£299.00/mo', or '£10.00' for a one-off pack.
  String get displayPrice =>
      '${formatPence(pricePence)}${interval?.suffix ?? ''}';

  /// What one lead actually costs on a credit pack.
  ///
  /// The pack price is NOT the per-lead price: 'credits-10' is £10.00 for TEN
  /// credits, so a lead is £1.00. Showing the pack price per lead would
  /// overstate it tenfold.
  String? get displayPerCredit {
    final c = credits;
    if (c == null || c <= 0) return null;
    return '${formatPence(pricePence ~/ c)} per credit';
  }

  factory BillingPlan.fromJson(Map<String, dynamic> j) => BillingPlan(
    id: jsonString(j, 'id'),
    lookupKey: jsonString(j, 'lookupKey'),
    name: jsonString(j, 'name'),
    pricePence: (j['pricePence'] as num?)?.toInt() ?? 0,
    interval: PlanInterval.fromWire(j['interval'] as String?),
    credits: (j['credits'] as num?)?.toInt(),
  );
}

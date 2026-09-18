import 'package:autonect/data/models/billing_plan.dart' show PlanInterval;

/// `display.state` from `GET /v1/billing/status` — the one line the plan
/// screen shows under the plan name. Unknown values read as [none], which
/// shows nothing rather than something untrue.
enum BillingDisplayState {
  none('NONE'),
  processing('PROCESSING'),
  activeRenewing('ACTIVE_RENEWING'),
  activeCancelling('ACTIVE_CANCELLING'),
  pastDue('PAST_DUE'),
  trialing('TRIALING');

  const BillingDisplayState(this.wire);
  final String wire;

  static BillingDisplayState fromWire(Object? v) =>
      values.firstWhere((s) => s.wire == v, orElse: () => none);
}

/// What buying a plan does, as the SERVER decided it — the app never derives
/// the ladder itself.
enum PlanAction {
  subscribe('SUBSCRIBE'),
  upgrade('UPGRADE'),
  buyCredits('BUY_CREDITS');

  const PlanAction(this.wire);
  final String wire;

  static PlanAction? fromWire(Object? v) {
    for (final a in values) {
      if (a.wire == v) return a;
    }
    return null;
  }
}

/// A rung of the ladder: rank 0 base (Free/Standard), 1 credits, 2 subscription.
class BillingLevel {
  const BillingLevel({required this.code, required this.rank, required this.name});

  final String code;
  final int rank;
  final String name;

  static const BillingLevel unknown = BillingLevel(code: '', rank: 0, name: '');

  factory BillingLevel.fromJson(Object? j) {
    if (j is! Map) return unknown;
    return BillingLevel(
      code: j['code'] as String? ?? '',
      rank: (j['rank'] as num?)?.toInt() ?? 0,
      name: j['name'] as String? ?? '',
    );
  }
}

class BillingSubscriptionInfo {
  const BillingSubscriptionInfo({
    required this.id,
    required this.status,
    required this.comped,
    required this.cancelAtPeriodEnd,
    required this.planLookupKey,
    required this.planName,
    required this.pricePence,
    this.interval,
    this.currentPeriodEnd,
    this.cancelAt,
    this.graceUntil,
  });

  final String id;
  final String status;
  final bool comped;
  final bool cancelAtPeriodEnd;
  final String planLookupKey;
  final String planName;
  final int pricePence;
  final PlanInterval? interval;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelAt;
  final DateTime? graceUntil;

  static BillingSubscriptionInfo? fromJson(Object? j) {
    if (j is! Map) return null;
    final plan = j['plan'] is Map ? j['plan'] as Map : const {};
    return BillingSubscriptionInfo(
      id: j['id'] as String? ?? '',
      status: j['status'] as String? ?? '',
      comped: j['comped'] == true,
      cancelAtPeriodEnd: j['cancelAtPeriodEnd'] == true,
      planLookupKey: plan['lookupKey'] as String? ?? '',
      planName: plan['name'] as String? ?? '',
      pricePence: (plan['pricePence'] as num?)?.toInt() ?? 0,
      interval: PlanInterval.fromWire(plan['interval'] as String?),
      currentPeriodEnd: _date(j['currentPeriodEnd']),
      cancelAt: _date(j['cancelAt']),
      graceUntil: _date(j['graceUntil']),
    );
  }
}

/// One plan as the server offers it to THIS user, with its verdict attached.
class BillingOffer {
  const BillingOffer({
    required this.lookupKey,
    required this.name,
    required this.pricePence,
    required this.rank,
    required this.isSubscription,
    required this.current,
    required this.allowed,
    this.interval,
    this.credits,
    this.action,
    this.reason,
  });

  final String lookupKey;
  final String name;
  final int pricePence;
  final PlanInterval? interval;
  final int? credits;
  final int rank;
  final bool isSubscription;
  final bool current;
  final PlanAction? action;

  /// Whether buying it is possible right now — false with a [reason] otherwise.
  final bool allowed;
  final String? reason;

  bool get isCreditPack => !isSubscription && (credits ?? 0) > 0;

  static BillingOffer? tryFromJson(Object? j) {
    if (j is! Map || j['lookupKey'] is! String || j['pricePence'] is! num) return null;
    return BillingOffer(
      lookupKey: j['lookupKey'] as String,
      name: j['name'] as String? ?? '',
      pricePence: (j['pricePence'] as num).toInt(),
      interval: PlanInterval.fromWire(j['interval'] as String?),
      credits: (j['credits'] as num?)?.toInt(),
      rank: (j['rank'] as num?)?.toInt() ?? 0,
      isSubscription: j['level'] == 'SUBSCRIPTION',
      current: j['current'] == true,
      action: PlanAction.fromWire(j['action']),
      allowed: j['allowed'] == true,
      reason: j['reason'] as String?,
    );
  }
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

/// `GET /v1/billing/status` — everything the plan screen renders, decided by
/// the server: the user's level, their subscription, what may be bought.
class BillingStatus {
  const BillingStatus({
    required this.level,
    required this.baseLevel,
    required this.credits,
    required this.displayState,
    required this.offers,
    this.displayDate,
    this.subscription,
    this.pendingKind,
    this.pendingLookupKey,
    this.canCancel = false,
    this.canResume = false,
    this.canRetryPayment = false,
  });

  final BillingLevel level;
  final BillingLevel baseLevel;
  final int credits;
  final BillingSubscriptionInfo? subscription;
  final BillingDisplayState displayState;
  final DateTime? displayDate;

  /// A payment Stripe is still processing — 'CREDITS' or 'SUBSCRIPTION'.
  final String? pendingKind;
  final String? pendingLookupKey;
  final bool canCancel;
  final bool canResume;
  final bool canRetryPayment;
  final List<BillingOffer> offers;

  bool get isSubscribed => level.rank >= 2;
  bool get isProcessing => displayState == BillingDisplayState.processing;

  /// The subscription plan the Pro card sells: the current one, else the
  /// lowest-ranked subscription on offer.
  BillingOffer? get subscriptionOffer {
    final subs = offers.where((o) => o.isSubscription).toList()..sort((a, b) => a.rank.compareTo(b.rank));
    return subs.where((o) => o.current).firstOrNull ?? subs.firstOrNull;
  }

  /// Credit packs, smallest first.
  List<BillingOffer> get creditPacks =>
      offers.where((o) => o.isCreditPack).toList()..sort((a, b) => (a.credits ?? 0).compareTo(b.credits ?? 0));

  BillingOffer? offer(String lookupKey) => offers.where((o) => o.lookupKey == lookupKey).firstOrNull;

  factory BillingStatus.fromJson(Map<String, dynamic> j) {
    final display = j['display'] is Map ? j['display'] as Map : const {};
    final pending = j['pending'] is Map ? j['pending'] as Map : null;
    final actions = j['actions'] is Map ? j['actions'] as Map : const {};
    return BillingStatus(
      level: BillingLevel.fromJson(j['level']),
      baseLevel: BillingLevel.fromJson(j['baseLevel']),
      credits: (j['credits'] as num?)?.toInt() ?? 0,
      subscription: BillingSubscriptionInfo.fromJson(j['subscription']),
      displayState: BillingDisplayState.fromWire(display['state']),
      displayDate: _date(display['date']),
      pendingKind: pending?['kind'] as String?,
      pendingLookupKey: pending?['lookupKey'] as String?,
      canCancel: actions['canCancel'] == true,
      canResume: actions['canResume'] == true,
      canRetryPayment: actions['canRetryPayment'] == true,
      // A malformed plan row is dropped, not allowed to fail the whole screen.
      offers: [
        for (final o in (j['plans'] is List ? j['plans'] as List : const []))
          ?BillingOffer.tryFromJson(o),
      ],
    );
  }
}

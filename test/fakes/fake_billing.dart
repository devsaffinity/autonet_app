import 'dart:async';

import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_checkout.dart';
import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/services/payment_sheet_gateway.dart';

/// In-memory billing for controller and screen tests: no ApiClient, no
/// platform channel. Records `calls`, because what these tests mostly assert
/// is WHETHER the server was asked — a double tap must not create two
/// PaymentIntents, a cancelled sheet must not sync.
ApiResult<T> _none<T>(String what) => Err<T>(ApiError.malformed('no $what scripted'));

class FakeBillingRepository implements BillingRepository {
  final List<String> calls = [];

  ApiResult<List<BillingPlan>> plansResult = const Ok([]);
  ApiResult<BillingConfig> configResult = const Ok(testBillingConfig);

  /// `/status` answers: [statusQueue] drains first, then [statusResult].
  ApiResult<BillingStatus>? statusResult;
  final List<ApiResult<BillingStatus>> statusQueue = [];

  /// `/sync` — left null, it answers like the next `/status`.
  ApiResult<BillingStatus>? syncResult;
  ({String? paymentIntentId, String? subscriptionId})? lastSync;

  ApiResult<PaymentSheetSession>? creditsIntentResult;
  ApiResult<PaymentSheetSession>? subscriptionResult;
  ApiResult<PaymentSheetSession>? retryResult;
  ApiResult<BillingStatus>? cancelResult;
  ApiResult<BillingStatus>? resumeResult;
  String? lastLookupKey;

  List<Map<String, dynamic>> ledger = [];
  int walletCredits = 0;

  int countOf(String call) => calls.where((c) => c == call).length;

  ApiResult<BillingStatus> _nextStatus() =>
      statusQueue.isNotEmpty ? statusQueue.removeAt(0) : statusResult ?? _none('status');

  @override
  Future<ApiResult<List<BillingPlan>>> plans() async {
    calls.add('plans');
    return plansResult;
  }

  @override
  Future<ApiResult<BillingConfig>> config() async {
    calls.add('config');
    return configResult;
  }

  @override
  Future<ApiResult<BillingStatus>> status() async {
    calls.add('status');
    return _nextStatus();
  }

  @override
  Future<ApiResult<BillingStatus>> sync({String? paymentIntentId, String? subscriptionId}) async {
    calls.add('sync');
    lastSync = (paymentIntentId: paymentIntentId, subscriptionId: subscriptionId);
    return syncResult ?? _nextStatus();
  }

  @override
  Future<ApiResult<PaymentSheetSession>> createCreditsIntent(String lookupKey) async {
    calls.add('createCreditsIntent');
    lastLookupKey = lookupKey;
    return creditsIntentResult ?? _none('credits intent');
  }

  @override
  Future<ApiResult<PaymentSheetSession>> createSubscription(String lookupKey) async {
    calls.add('createSubscription');
    lastLookupKey = lookupKey;
    return subscriptionResult ?? _none('subscription');
  }

  @override
  Future<ApiResult<PaymentSheetSession>> retryPayment() async {
    calls.add('retryPayment');
    return retryResult ?? _none('retry');
  }

  @override
  Future<ApiResult<BillingStatus>> cancelSubscription() async {
    calls.add('cancel');
    return cancelResult ?? _none('cancel');
  }

  @override
  Future<ApiResult<BillingStatus>> resumeSubscription() async {
    calls.add('resume');
    return resumeResult ?? _none('resume');
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> wallet() async {
    calls.add('wallet');
    return Ok({'credits': walletCredits, 'hasActiveSubscription': false, 'subscription': null, 'ledger': ledger});
  }
}

/// The payment sheet, scripted. [hold] keeps it "open" until the test
/// completes it — how a test observes the app while the customer is paying.
class FakePaymentSheetGateway implements PaymentSheetGateway {
  FakePaymentSheetGateway({this.isSupported = true});

  @override
  bool isSupported;

  bool configureOk = true;
  PaymentSheetOutcome outcome = const PaymentCompleted();
  Completer<PaymentSheetOutcome>? hold;

  final List<PaymentSheetSession> presented = [];
  int configured = 0;

  @override
  Future<bool> configure(BillingConfig config) async {
    configured++;
    return configureOk;
  }

  @override
  Future<PaymentSheetOutcome> present(PaymentSheetSession session, BillingConfig config) async {
    presented.add(session);
    final h = hold;
    return h == null ? outcome : h.future;
  }
}

const BillingConfig testBillingConfig = BillingConfig(publishableKey: 'pk_test_fake');

// ── Wire fixtures, shaped exactly like `GET /v1/billing/status` ──────────────

const String kElectricianPro = 'electrician-pro-monthly';
const String kLead1 = 'electrician-lead-1';
const String kLeads5 = 'electrician-leads-5';
const String kSupplierPro = 'supplier-monthly';
const String kSupplierPack = 'credits-10';

Map<String, dynamic> planJson(
  String lookupKey, {
  required String name,
  required int pricePence,
  int? credits,
  bool subscription = false,
  bool current = false,
  bool allowed = true,
  String? action,
  String? reason,
}) => {
  'lookupKey': lookupKey,
  'name': name,
  'pricePence': pricePence,
  'interval': subscription ? 'MONTH' : 'ONE_TIME',
  'credits': credits,
  'level': subscription ? 'SUBSCRIPTION' : 'CREDITS',
  'rank': subscription ? 10 : 0,
  'current': current,
  'action': allowed ? (action ?? (subscription ? 'SUBSCRIBE' : 'BUY_CREDITS')) : null,
  'allowed': allowed,
  'reasonCode': allowed ? null : 'DOWNGRADE_NOT_ALLOWED',
  'reason': allowed ? null : reason,
};

const _electricianLevels = ['FREE', 'PAY_PER_LEAD', 'PRO'];
const _electricianNames = ['Free', 'Pay-Per-Lead', 'Pro'];
const _supplierLevels = ['NONE', 'CREDITS', 'SUBSCRIPTION'];
const _supplierNames = ['Standard', 'Pay-Per-Lead', 'Pro Unlimited'];

Map<String, dynamic> _level(bool supplier, int rank) => {
  'code': (supplier ? _supplierLevels : _electricianLevels)[rank],
  'rank': rank,
  'name': (supplier ? _supplierNames : _electricianNames)[rank],
};

/// The plans a user at [rank] is offered: packs are refused while subscribed
/// (Pro → pack is a downgrade), Pro is refused once subscribed.
List<Map<String, dynamic>> defaultPlans({required bool supplier, required int rank}) {
  final subscribed = rank >= 2;
  const packReason = 'Your plan already includes unlimited leads.';
  if (supplier) {
    return [
      planJson(kSupplierPro, name: 'Supplier Unlimited (Monthly)', pricePence: 29900, subscription: true, current: subscribed, allowed: !subscribed, reason: 'You already have this plan.'),
      planJson(kSupplierPack, name: '10 Credit Pack', pricePence: 1000, credits: 10, allowed: !subscribed, reason: packReason),
    ];
  }
  return [
    planJson(kElectricianPro, name: 'Electrician Pro (Monthly)', pricePence: 14900, subscription: true, current: subscribed, allowed: !subscribed, reason: 'You already have this plan.'),
    planJson(kLead1, name: '1 Lead Credit', pricePence: 1200, credits: 1, allowed: !subscribed, reason: packReason),
    planJson(kLeads5, name: '5 Lead Credits', pricePence: 5500, credits: 5, allowed: !subscribed, reason: packReason),
  ];
}

/// `display.state` → the subscription row the server would send with it.
Map<String, dynamic>? _subscriptionFor(String display, {required bool supplier, required String periodEnd}) {
  final (status, cancelling) = switch (display) {
    'ACTIVE_RENEWING' => ('ACTIVE', false),
    'ACTIVE_CANCELLING' => ('ACTIVE', true),
    'PAST_DUE' => ('PAST_DUE', false),
    'TRIALING' => ('TRIALING', false),
    _ => (null, false),
  };
  if (status == null) return null;
  return {
    'id': 'sub_1',
    'status': status,
    'comped': display == 'TRIALING',
    'currentPeriodEnd': periodEnd,
    'cancelAtPeriodEnd': cancelling,
    'cancelAt': cancelling ? periodEnd : null,
    'graceUntil': display == 'PAST_DUE' ? periodEnd : null,
    'plan': supplier
        ? {'lookupKey': kSupplierPro, 'name': 'Supplier Unlimited (Monthly)', 'pricePence': 29900, 'interval': 'MONTH'}
        : {'lookupKey': kElectricianPro, 'name': 'Electrician Pro (Monthly)', 'pricePence': 14900, 'interval': 'MONTH'},
  };
}

/// A whole status body. [display] drives the subscription row and actions, so
/// a test names the state it is about and gets a consistent payload.
Map<String, dynamic> statusJson({
  bool supplier = false,
  int rank = 0,
  int baseRank = 0,
  int credits = 0,
  String display = 'NONE',
  String periodEnd = '2026-10-18T12:00:00.000Z',
  Map<String, dynamic>? pending,
  List<Map<String, dynamic>>? plans,
}) {
  final subscription = _subscriptionFor(display, supplier: supplier, periodEnd: periodEnd);
  return {
    'role': supplier ? 'SUPPLIER' : 'ELECTRICIAN',
    'level': _level(supplier, rank),
    'baseLevel': _level(supplier, baseRank),
    'credits': credits,
    'ladder': [for (var r = 0; r < 3; r++) _level(supplier, r)],
    'subscription': subscription,
    'display': {'state': display, 'date': subscription == null ? null : periodEnd},
    'pending': pending,
    'actions': {
      'canCancel': display == 'ACTIVE_RENEWING' || display == 'PAST_DUE',
      'canResume': display == 'ACTIVE_CANCELLING',
      'canRetryPayment': display == 'PAST_DUE',
      'baseLevelOptions': const <String>[],
    },
    'plans': plans ?? defaultPlans(supplier: supplier, rank: rank),
  };
}

BillingStatus billingStatus({
  bool supplier = false,
  int rank = 0,
  int baseRank = 0,
  int credits = 0,
  String display = 'NONE',
  String periodEnd = '2026-10-18T12:00:00.000Z',
  Map<String, dynamic>? pending,
  List<Map<String, dynamic>>? plans,
}) => BillingStatus.fromJson(
  statusJson(
    supplier: supplier,
    rank: rank,
    baseRank: baseRank,
    credits: credits,
    display: display,
    periodEnd: periodEnd,
    pending: pending,
    plans: plans,
  ),
);

PaymentSheetSession sheetSession({
  bool subscription = false,
  bool requiresPayment = true,
  String lookupKey = kLeads5,
  String planName = '5 Lead Credits',
  int amountPence = 5500,
}) => PaymentSheetSession(
  isSubscription: subscription,
  requiresPayment: requiresPayment,
  clientSecret: requiresPayment ? 'pi_1_secret_x' : null,
  paymentIntentId: subscription ? null : 'pi_1',
  subscriptionId: subscription ? 'sub_1' : null,
  customerId: 'cus_1',
  customerSessionClientSecret: 'cuss_secret_1',
  planLookupKey: lookupKey,
  planName: planName,
  amountPence: amountPence,
);

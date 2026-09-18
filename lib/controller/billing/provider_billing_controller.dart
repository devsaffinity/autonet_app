import 'dart:async';

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/billing_checkout.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/domain/billing_confirmation.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/services/payment_sheet_gateway.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

const String kPaymentsUnsupportedCopy = 'Payments are only available in the Autonect mobile app.';
const String kProcessingSlowCopy =
    "Your payment is still being confirmed. We'll update your plan as soon as it lands.";

/// The plans screen's brain, for BOTH provider roles.
///
/// PURCHASE = server verdict → payment sheet → read back from the server.
/// The sheet saying "done" only means the card was accepted; the purchase is
/// confirmed when `/sync` or `/status` says so, polled on a short backoff.
/// Nothing here decides what may be bought — each offer carries the server's
/// verdict, so an upgrade-only rule change needs no app release.
///
/// Scoped to the plans route (not permanent), so it is disposed on leaving —
/// polling stops, and one account's billing never survives into the next.
class ProviderBillingController extends ApiController with WidgetsBindingObserver {
  ProviderBillingController(
    this._repo,
    this._sheet, {
    super.toast,
    super.showBusy,
    super.hideBusy,
    List<Duration> confirmSchedule = kConfirmSchedule,
    DateTime Function() clock = DateTime.now,
  }) : _schedule = confirmSchedule,
       _clock = clock;

  static ProviderBillingController ensure() => Get.isRegistered<ProviderBillingController>()
      ? Get.find<ProviderBillingController>()
      : Get.put(ProviderBillingController(Get.find<BillingRepository>(), Get.find<PaymentSheetGateway>()));

  final BillingRepository _repo;
  final PaymentSheetGateway _sheet;
  final List<Duration> _schedule;
  final DateTime Function() _clock;

  static const StateSlot _statusSlot = StateSlot('billingStatus');

  final Rx<ViewState<BillingStatus>> status = Rx<ViewState<BillingStatus>>(const Loading());

  /// The offer (lookup key) or action ('cancel', 'resume', 'retry') in
  /// progress; null when idle. While set, every billing button is inert.
  final RxnString working = RxnString();

  /// Paid in the sheet, not yet confirmed by the server.
  final Rxn<PendingConfirmation> awaiting = Rxn<PendingConfirmation>();

  /// Something changed on this visit — the caller refreshes profile/dashboard on leaving.
  bool changedThisVisit = false;

  BillingConfig? _config;
  bool _inSheet = false;
  int _pollGen = 0;
  Timer? _timer;
  DateTime? _lastRefresh;

  BillingStatus? get current => switch (status.value) {
    Data<BillingStatus>(:final value) => value,
    _ => null,
  };

  bool get isWorking => working.value != null;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.onClose();
  }

  /// Back from Google Pay, a bank app, or the background: re-read. Ignored
  /// while the sheet is open — on Android it is its own activity, and its
  /// comings and goings are not the user returning.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _inSheet || isWorking) return;
    final last = _lastRefresh;
    if (awaiting.value != null || last == null || _clock().difference(last) > const Duration(seconds: 5)) {
      unawaited(reload());
      if (awaiting.value != null && _timer == null) _startPolling();
    }
  }

  Future<void> load() async {
    if (current == null) status.value = const Loading<BillingStatus>();
    await reload();
    if (current?.isProcessing ?? false) _startPolling();
  }

  /// Not `refresh`: that is GetxController's own, and GetBuilder relies on it.
  Future<void> reload() => runRead(_statusSlot, _repo.status, _onStatus);

  void _onStatus(ApiResult<BillingStatus> r) {
    _lastRefresh = _clock();
    switch (r) {
      case Ok(:final value):
        _publish(value);
      case Err(:final error):
        if (error.code == ApiErrorCode.sessionExpired) absorb(error);
        // A failed REFRESH keeps what is on screen; only a first load shows it.
        if (current == null) status.value = Failed<BillingStatus>(error);
    }
  }

  void _publish(BillingStatus s) {
    status.value = Data<BillingStatus>(s);
    final pending = awaiting.value;
    if (pending == null) return;
    if (pending.isSatisfiedBy(s)) {
      awaiting.value = null;
      _stopPolling();
      toast(_confirmedCopy(pending, s));
    } else if (pending.isExpired(_clock())) {
      awaiting.value = null;
      _stopPolling();
    }
  }

  Future<void> buyCredits(String lookupKey) =>
      _purchase(PurchaseKind.credits, lookupKey, () => _repo.createCreditsIntent(lookupKey));

  /// New subscription or an upgrade — the server decides which.
  Future<void> subscribe(String lookupKey) =>
      _purchase(PurchaseKind.subscription, lookupKey, () => _repo.createSubscription(lookupKey));

  /// Past due: pay the failed renewal (and save a new card) in the sheet.
  Future<void> retryPayment() => _purchase(PurchaseKind.recovery, 'retry', _repo.retryPayment);

  Future<void> _purchase(
    PurchaseKind kind,
    String key,
    Future<ApiResult<PaymentSheetSession>> Function() create,
  ) async {
    // One at a time, decided synchronously: a double tap is a no-op.
    if (isWorking || awaiting.value != null) return;
    if (!_sheet.isSupported) return toast(kPaymentsUnsupportedCopy);
    final before = current;
    if (kind != PurchaseKind.recovery) {
      final offer = before?.offer(key);
      if (offer == null || !offer.allowed) return toast(offer?.reason ?? "That plan isn't available right now.");
    }
    working.value = key;
    try {
      final config = await _ensureConfig();
      if (config == null) return;
      final created = await create();
      final PaymentSheetSession session;
      switch (created) {
        case Err(:final error):
          _surface(error);
          if (error.code == ApiErrorCode.conflict) await reload(); // the screen was stale
          return;
        case Ok(:final value):
          session = value;
      }
      if (session.requiresPayment) {
        _inSheet = true;
        final outcome = await _sheet.present(session, config);
        _inSheet = false;
        switch (outcome) {
          case PaymentCancelled():
            return toast('Payment cancelled — you have not been charged.');
          case PaymentFailed(:final message):
            return toast(message ?? 'The payment did not go through. Please try again or use another card.');
          case PaymentCompleted():
            break;
        }
      }
      changedThisVisit = true;
      awaiting.value = PendingConfirmation(
        kind: kind,
        lookupKey: session.planLookupKey.isNotEmpty ? session.planLookupKey : key,
        planName: session.planName,
        baselineCredits: before?.credits ?? 0,
        startedAt: _clock(),
      );
      await runRead(
        _statusSlot,
        () => _repo.sync(
          paymentIntentId: session.isSubscription ? null : session.paymentIntentId,
          subscriptionId: session.subscriptionId,
        ),
        _onStatus,
      );
      if (awaiting.value != null) _startPolling();
    } finally {
      _inSheet = false;
      working.value = null;
    }
  }

  Future<void> cancelSubscription() => _lifecycle('cancel', _repo.cancelSubscription, (s) {
    final end = s.subscription?.cancelAt ?? s.subscription?.currentPeriodEnd;
    return end == null ? 'Your plan has been cancelled.' : 'Cancelled — you keep your plan until ${formatLongDate(end)}.';
  });

  Future<void> resumeSubscription() => _lifecycle('resume', _repo.resumeSubscription, (s) {
    final next = s.subscription?.currentPeriodEnd;
    return next == null ? 'Your plan is active again.' : 'Your plan is active again and renews on ${formatLongDate(next)}.';
  });

  Future<void> _lifecycle(
    String key,
    Future<ApiResult<BillingStatus>> Function() call,
    String Function(BillingStatus) done,
  ) async {
    if (isWorking) return;
    working.value = key;
    try {
      await runWrite<BillingStatus, void>(_statusSlot, call, (r, claim) {
        switch (r) {
          case Ok(:final value):
            claim.publish(() => _publish(value));
            changedThisVisit = true;
            toast(done(value));
          case Err(:final error):
            _surface(error);
        }
      }, silent: true);
    } finally {
      working.value = null;
    }
  }

  Future<BillingConfig?> _ensureConfig() async {
    var config = _config;
    if (config == null) {
      switch (await _repo.config()) {
        case Err(:final error):
          _surface(error);
          return null;
        case Ok(:final value):
          config = value;
      }
    }
    if (!await _sheet.configure(config)) {
      toast('Payments could not start on this device. Please try again.');
      return null;
    }
    return _config = config;
  }

  void _surface(ApiError error) {
    if (error.code == ApiErrorCode.sessionExpired) return absorb(error);
    toast(userMessageFor(error));
  }

  String _confirmedCopy(PendingConfirmation p, BillingStatus s) => switch (p.kind) {
    PurchaseKind.credits => 'Payment received — ${s.credits} credit${s.credits == 1 ? '' : 's'} available.',
    PurchaseKind.subscription => '${p.planName.isEmpty ? 'Your plan' : p.planName} is active. Thank you!',
    PurchaseKind.recovery => 'Payment received — your plan is back in good standing.',
  };

  void _startPolling() {
    _stopPolling();
    _pollStep(_pollGen, 0);
  }

  void _pollStep(int gen, int i) {
    if (gen != _pollGen || isClosed) return;
    if (i >= _schedule.length) {
      _timer = null;
      if (awaiting.value != null) toast(kProcessingSlowCopy);
      return;
    }
    _timer = Timer(_schedule[i], () async {
      if (gen != _pollGen || isClosed) return;
      await reload();
      final stillWaiting = awaiting.value != null || (current?.isProcessing ?? false);
      if (!stillWaiting) {
        _timer = null;
        return;
      }
      _pollStep(gen, i + 1);
    });
  }

  void _stopPolling() {
    _pollGen++;
    _timer?.cancel();
    _timer = null;
  }
}

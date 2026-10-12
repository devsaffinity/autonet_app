import 'dart:async';

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/billing_checkout.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/domain/billing_confirmation.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/services/purchase_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

const String kPurchasesUnsupportedCopy = 'Purchases are only available in the Autonect mobile app.';
const String kProcessingSlowCopy =
    "Your purchase is still being confirmed. We'll update your plan as soon as it lands.";
const String kStoreManagedCopy = 'Your subscription is managed by the store that charges you.';

/// The plans screen's brain, for BOTH provider roles.
///
/// PURCHASE = server verdict → store sheet → read back from the server. The
/// store saying "done" only means it took the money; the purchase is
/// confirmed when `/sync` or `/status` says so, polled on a short backoff.
/// Nothing here decides what may be bought — each offer carries the server's
/// verdict, so a rule change needs no app release.
///
/// Cancelling and resuming are NOT here: Google and Apple own the
/// subscription, so the screen deep-links to the store instead of pretending.
///
/// Scoped to the plans route (not permanent), so it is disposed on leaving —
/// polling stops, and one account's billing never survives into the next.
class ProviderBillingController extends ApiController with WidgetsBindingObserver {
  ProviderBillingController(
    this._repo,
    this._store,
    this._tokens, {
    super.toast,
    super.showBusy,
    super.hideBusy,
    List<Duration> confirmSchedule = kConfirmSchedule,
    DateTime Function() clock = DateTime.now,
    bool Function()? isIos,
    Future<bool> Function(Uri)? launch,
  }) : _schedule = confirmSchedule,
       _clock = clock,
       _isIos = isIos ?? (() => defaultTargetPlatform == TargetPlatform.iOS),
       _launch = launch ?? ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

  static ProviderBillingController ensure() => Get.isRegistered<ProviderBillingController>()
      ? Get.find<ProviderBillingController>()
      : Get.put(
          ProviderBillingController(
            Get.find<BillingRepository>(),
            Get.find<PurchaseGateway>(),
            Get.find<TokenStore>(),
          ),
        );

  final BillingRepository _repo;
  final PurchaseGateway _store;
  final TokenStore _tokens;
  final List<Duration> _schedule;
  final DateTime Function() _clock;
  final bool Function() _isIos;
  final Future<bool> Function(Uri) _launch;

  static const StateSlot _statusSlot = StateSlot('billingStatus');

  final Rx<ViewState<BillingStatus>> status = Rx<ViewState<BillingStatus>>(const Loading());

  /// The offer (lookup key) or action ('restore') in progress; null when
  /// idle. While set, every billing button is inert.
  final RxnString working = RxnString();

  /// Bought in the store, not yet confirmed by the server.
  final Rxn<PendingConfirmation> awaiting = Rxn<PendingConfirmation>();

  /// Something changed on this visit — the caller refreshes profile/dashboard on leaving.
  bool changedThisVisit = false;

  BillingConfig? _config;
  bool _inStore = false;
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

  /// Back from the store, or from managing a subscription in it: re-read.
  /// Ignored while the store sheet is up — it is its own activity, and its
  /// comings and goings are not the user returning.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _inStore || isWorking) return;
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

  /// Buy a plan — a credit pack or a subscription; the store sheet decides which.
  Future<void> buy(String lookupKey) async {
    // One at a time, decided synchronously: a double tap is a no-op.
    if (isWorking || awaiting.value != null) return;
    if (!_store.isSupported) return toast(kPurchasesUnsupportedCopy);
    final before = current;
    final offer = before?.offer(lookupKey);
    if (offer == null || !offer.allowed) {
      return toast(offer?.reason ?? "That plan isn't available right now.");
    }
    final productId = offer.storeProductId(ios: _isIos());
    if (productId == null || productId.isEmpty) {
      return toast("That plan isn't on sale in your store yet.");
    }
    working.value = lookupKey;
    try {
      if (!await _ensureConfigured()) return;
      _inStore = true;
      final outcome = await _store.buy(productId);
      _inStore = false;
      switch (outcome) {
        case PurchaseCancelled():
          return toast('Purchase cancelled — you have not been charged.');
        case PurchaseFailed(:final message):
          return toast(message ?? 'The purchase did not go through. Please try again.');
        case PurchaseUnavailable(:final message):
          return toast(message ?? "That plan isn't available in your store account yet.");
        case PurchaseCompleted():
          break;
      }
      await _confirm(
        PendingConfirmation(
          kind: offer.isSubscription ? PurchaseKind.subscription : PurchaseKind.credits,
          lookupKey: lookupKey,
          planName: offer.name,
          baselineCredits: before?.credits ?? 0,
          baselineSubscribed: before?.isSubscribed ?? false,
          startedAt: _clock(),
        ),
      );
    } finally {
      _inStore = false;
      working.value = null;
    }
  }

  /// Bring back what this store account already owns: a reinstall, a new
  /// phone, or a purchase the webhook never delivered. Apple requires it.
  Future<void> restorePurchases() async {
    if (isWorking || awaiting.value != null) return;
    if (!_store.isSupported) return toast(kPurchasesUnsupportedCopy);
    final before = current;
    working.value = 'restore';
    try {
      if (!await _ensureConfigured()) return;
      _inStore = true;
      final outcome = await _store.restore();
      _inStore = false;
      switch (outcome) {
        case PurchaseCompleted():
          break;
        case PurchaseCancelled():
          return;
        case PurchaseFailed(:final message):
          return toast(message ?? 'Could not reach the store. Please try again.');
        case PurchaseUnavailable(:final message):
          return toast(message ?? kPurchasesUnsupportedCopy);
      }
      await _confirm(
        PendingConfirmation(
          kind: PurchaseKind.restore,
          lookupKey: '',
          planName: '',
          baselineCredits: before?.credits ?? 0,
          baselineSubscribed: before?.isSubscribed ?? false,
          startedAt: _clock(),
        ),
        quietCopy: 'Nothing to restore on this store account.',
      );
    } finally {
      _inStore = false;
      working.value = null;
    }
  }

  /// Send the customer to the store page that owns their subscription.
  ///
  /// This is the whole of "cancel", "resume" and "update card" now: Google
  /// and Apple do not let a server do any of it, so the honest thing is to
  /// open their page. The lifecycle hook re-reads status when they come back.
  Future<void> openStoreManagement() async {
    final url = current?.manageUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null) return toast(kStoreManagedCopy);
    _inStore = true;
    try {
      if (!await _launch(uri)) {
        toast('Could not open the store. Open it and look under Subscriptions.');
      }
    } finally {
      _inStore = false;
    }
  }

  /// Tell the server to re-read the store, then wait for it to agree.
  Future<void> _confirm(PendingConfirmation pending, {String? quietCopy}) async {
    changedThisVisit = true;
    awaiting.value = pending;
    await runRead(_statusSlot, _repo.sync, _onStatus);
    if (awaiting.value == null) return;
    if (quietCopy != null && !(current?.isProcessing ?? false)) {
      // Restore found nothing: say so instead of spinning for 30 seconds.
      awaiting.value = null;
      return toast(quietCopy);
    }
    _startPolling();
  }

  Future<bool> _ensureConfigured() async {
    var config = _config;
    if (config == null) {
      switch (await _repo.config()) {
        case Err(:final error):
          _surface(error);
          return false;
        case Ok(:final value):
          config = value;
      }
    }
    final userId = _tokens.user?.id;
    if (userId == null) {
      toast('Please sign in again to make a purchase.');
      return false;
    }
    // The App User ID is our user id, so entitlements follow the ACCOUNT, not
    // the phone — a reinstall or a new device finds the same subscription.
    if (!await _store.configure(config, appUserId: userId)) {
      toast('Purchases could not start on this device. Please try again.');
      return false;
    }
    _config = config;
    return true;
  }

  void _surface(ApiError error) {
    if (error.code == ApiErrorCode.sessionExpired) return absorb(error);
    toast(userMessageFor(error));
  }

  String _confirmedCopy(PendingConfirmation p, BillingStatus s) => switch (p.kind) {
    PurchaseKind.credits => 'Purchase received — ${s.credits} credit${s.credits == 1 ? '' : 's'} available.',
    PurchaseKind.subscription => '${p.planName.isEmpty ? 'Your plan' : p.planName} is active. Thank you!',
    PurchaseKind.restore => 'Your purchases have been restored.',
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

import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/base/superseding_reads.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Re-exported so a controller imports ONE base file, not two.
export 'package:autonect/controller/base/superseding_reads.dart'
    show SlotClaim, StateSlot;

void _defaultToast(String m) => displayToast(msg: m);

/// The buyer funnel's base controller: one busy latch, one dialog, one error
/// funnel.
///
/// It is a SIBLING of AuthController, not a parent of it. AuthController is the
/// only tested controller that shipped in phase 0 and it keeps its own
/// `absorb`, because its routing (invalid credentials -> banner, otpExpired ->
/// un-gate resend) is a different bounded context from the buyer funnel's. The
/// part that would genuinely drift — the copy and the retry affordance — is
/// shared through `domain/failure_copy.dart`, which both switches consume.
///
/// Owns NO TextEditingController and NEVER navigates: screens own controllers,
/// form keys and dispose(), and screens push (routes.dart:1-5).
///
/// THREE funnels: [run] for a WRITE, which DROPS a re-entrant call,
/// [SupersedingReads.runRead] for an idempotent READ, which supersedes it, and
/// [SupersedingReads.runWrite] for a write that publishes what it gets back.
abstract class ApiController extends GetxController with SupersedingReads {
  ApiController({
    this.toast = _defaultToast,
    this.showBusy = showLoadingDialog,
    this.hideBusy = hideLoadingDialog,
  });

  /// Injectable ONLY so a unit test runs with no GetMaterialApp and no
  /// Fluttertoast platform channel.
  final void Function(String) toast;
  final VoidCallback showBusy;
  final VoidCallback hideBusy;

  final RxBool busy = false.obs;
  final RxnString formError = RxnString();
  final RxMap<String, String> fieldErrors = <String, String>{}.obs;

  /// Falls back to a PREFIX match so an indexed server path ('imageKeys.0',
  /// which zod emits for an array element) still lands on the 'imageKeys'
  /// control rather than being silently invisible.
  String? fieldErrorFor(String path) {
    final exact = fieldErrors[path];
    if (exact != null) return exact;
    final prefix = '$path.';
    for (final e in fieldErrors.entries) {
      if (e.key.startsWith(prefix)) return e.value;
    }
    return null;
  }

  void clearErrors() {
    formError.value = null;
    fieldErrors.clear();
  }

  /// Call from onChanged: a server complaint must not stick to a field the user
  /// has since corrected.
  void clearFieldError(String path) => fieldErrors.remove(path);

  /// THE PER-ENTITY RESET RULE — call it FIRST from every method that points
  /// this controller at a DIFFERENT entity.
  ///
  /// Every controller here is a session-long `Get` singleton built by
  /// `ensure()`: ONE instance serves every request, order and offer the buyer
  /// opens. So whatever it holds that describes ONE of them — a [formError], a
  /// stale notice, a conflict latch, a spent draft — is a lie about the next
  /// one, and the lie costs most exactly where it is hardest to undo: state
  /// that DISABLES a control is normally cleared only by that control, so
  /// entity A's failure can hand entity B a dead button and no way back.
  ///
  /// Returns true when the entity actually CHANGED, for callers that must also
  /// blank a ViewState. Same id in, nothing is reset — re-opening the same
  /// entity keeps an answer still true of it, and dropping that would only
  /// hide a failure the buyer has not resolved yet.
  ///
  /// Moving the entity also invalidates every answer already IN FLIGHT, with no
  /// second mechanism: a [SlotClaim] records the entity it was taken under.
  /// That is the half a synchronous reset alone left undone — B was reset
  /// clean, and A's response landed on it a moment later.
  @protected
  bool beginEntity(String id) {
    if (entityId == id) return false;
    entityId = id;
    clearErrors();
    resetForEntity();
    return true;
  }

  /// The per-entity state this controller holds BEYOND [formError] and
  /// [fieldErrors], which [beginEntity] clears for everybody. Override it and
  /// the next entity starts clean; leave it and the controller is declaring it
  /// has none. Called by [beginEntity] and only on a real switch.
  @protected
  void resetForEntity() {}

  /// THE WRITE funnel. [silent] suppresses the modal dialog for pull-to-refresh
  /// and for loads whose progress the ViewState already renders. The drop stays
  /// — the double-submit guard — but never as a dead end: [droppedReentry]
  /// is the one error `failure_copy` always offers a retry on.
  ///
  /// A write that also PUBLISHES what it gets back goes through
  /// [SupersedingReads.runWrite], which is this drop decision and the slot
  /// claim taken together rather than one after the other.
  Future<R> run<T, R>(
    GlobalKey<FormState>? form,
    Future<ApiResult<T>> Function() call,
    R Function(ApiResult<T>) then, {
    bool silent = false,
  }) async {
    if (isBusy) return then(const Err(droppedReentry));
    return runLatched(call, then, silent: silent);
  }

  @override
  @protected
  bool get isBusy => busy.value;

  /// Everything AFTER the drop decision, so [run] and
  /// [SupersedingReads.runWrite] share one latch and one dialog and each
  /// refuses in its own way exactly once.
  @override
  @protected
  Future<R> runLatched<T, R>(
    Future<ApiResult<T>> Function() call,
    R Function(ApiResult<T>) then, {
    required bool silent,
  }) async {
    clearErrors();
    busy.value = true;
    if (!silent) showBusy();
    try {
      return then(await call());
    } finally {
      // BOTH branches, and always before the caller navigates: Get.offAllNamed
      // strips the dialog route and leaves Get.isDialogOpen stale-true forever.
      busy.value = false;
      if (!silent) hideBusy();
    }
  }

  /// The ONLY part of a SUPERSEDED answer that may still act. Everything else
  /// it carries describes a screen the buyer has left — but a dead session does
  /// not: swallowing it strands them in a shell where every later request 401s.
  @protected
  void absorbSuperseded(ApiError e) {
    if (e.code == ApiErrorCode.sessionExpired) absorb(e);
  }

  /// THE one place a buyer-side ApiError becomes UI. Exhaustive with no
  /// `default:` on purpose — a 16th backend code must be a compile error here
  /// and nowhere else. `@protected` rather than `@visibleForTesting` because
  /// every subclass that branches on a 409 first falls back to it, and each of
  /// those calls would otherwise be an analyzer warning.
  @protected
  void absorb(ApiError e, [GlobalKey<FormState>? form]) {
    switch (e.code) {
      case ApiErrorCode.validationError:
        fieldErrors.addAll(e.fieldErrors);
        form?.currentState?.validate();
        // The hand-written AppError details are OBJECTS, not arrays, so
        // FieldError.listFrom yields []. Those must still say something.
        if (fieldErrors.isEmpty) formError.value = userMessageFor(e);
      case ApiErrorCode.network:
      case ApiErrorCode.timeout:
        toast(userMessageFor(e));
      case ApiErrorCode.sessionExpired:
        RoleController.to.forceSignOut();
      case ApiErrorCode.unauthorized:
      case ApiErrorCode.forbidden:
      case ApiErrorCode.notFound:
      case ApiErrorCode.conflict:
      case ApiErrorCode.rateLimited:
      case ApiErrorCode.internal:
      case ApiErrorCode.invalidCredentials:
      case ApiErrorCode.verificationRequired:
      case ApiErrorCode.accountSuspended:
      case ApiErrorCode.otpInvalid:
      case ApiErrorCode.otpExpired:
      case ApiErrorCode.tooManyAttempts:
      case ApiErrorCode.insufficientCredits:
      case ApiErrorCode.notApproved:
      case ApiErrorCode.malformedResponse:
      case ApiErrorCode.unknown:
        formError.value = userMessageFor(e);
    }
  }
}

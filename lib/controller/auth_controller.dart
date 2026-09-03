import 'package:autonect/constants/app_role.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/message_ack.dart';
import 'package:autonect/data/models/token_pair.dart';
import 'package:autonect/data/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// What the SCREEN must do next. The controller deliberately never navigates
/// (bar a forced sign-out): pushes stay in the screens per routes.dart:1-5.
enum AuthOutcome { success, verificationRequired, failed }

void _defaultToast(String m) => displayToast(msg: m);

/// Owns NO TextEditingController. Screens own their controllers, form keys and
/// dispose(); values arrive as arguments. That removes the disposal hazard of a
/// shared controller and keeps every method callable from a unit test.
///
/// The three side-effect hooks are injectable ONLY so unit tests can run
/// without a GetMaterialApp or the Fluttertoast platform channel.
class AuthController extends GetxController {
  AuthController(
    this._repo,
    this._role, {
    this.toast = _defaultToast,
    this.showBusy = showLoadingDialog,
    this.hideBusy = hideLoadingDialog,
  });

  final AuthRepository _repo;
  final RoleController _role;
  final void Function(String) toast;
  final VoidCallback showBusy;
  final VoidCallback hideBusy;

  static AuthController get to => Get.find<AuthController>();

  /// What every auth screen calls in initState. It must be find-or-create, NOT
  /// a plain Get.put: put() replaces the registered instance, and the auth flow
  /// spans four screens that hand `pendingEmail` / `pendingCode` forward across
  /// a push. A fresh instance on VerifyOtpPage would post an empty email to
  /// /v1/auth/otp/verify. Not permanent — it dies with the last auth screen.
  static AuthController ensure() => Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(Get.find<AuthRepository>(), RoleController.to));

  final RxBool busy = false.obs;
  final RxnString formError = RxnString();
  final RxMap<String, String> fieldErrors = <String, String>{}.obs;

  /// signup -> OTP, forgot -> reset. Survives the push because the auth screens
  /// do not delete the controller between pages.
  final RxString pendingEmail = ''.obs;
  final RxString pendingCode = ''.obs;

  String? fieldErrorFor(String path) => fieldErrors[path];

  void clearErrors() {
    formError.value = null;
    fieldErrors.clear();
  }

  /// Call from onChanged: a server complaint must not stick to a field the user
  /// has since corrected.
  void clearFieldError(String path) => fieldErrors.remove(path);

  Future<AuthOutcome> login(
    String email,
    String password, [
    GlobalKey<FormState>? form,
  ]) => _run(form, () => _repo.login(email: email, password: password), (r) {
    // VERIFICATION_REQUIRED is 403, not 401 (auth.service.ts:95-97). Branch on
    // the CODE: this is a detour to the OTP screen, not an error banner.
    if (r case Err(:final error)
        when error.code == ApiErrorCode.verificationRequired) {
      pendingEmail.value = _norm(email);
      return AuthOutcome.verificationRequired;
    }
    return _afterTokens(r, form);
  });

  /// Returns NO tokens: the account stays PENDING_VERIFICATION until the OTP is
  /// verified, so the caller must push the OTP screen, not the app shell.
  Future<AuthOutcome> signup({
    required String email,
    required String password,
    required String name,
    required AppRole role,
    GlobalKey<FormState>? form,
  }) => _run(
    form,
    () => _repo.signup(email: email, password: password, role: role, name: name),
    (r) => _ack(r, form, () => pendingEmail.value = _norm(email)),
  );

  /// [isReset] true means the code belongs to the forgot-password flow, where
  /// /v1/auth/reset consumes it together with the new password. Calling
  /// otp/verify there would burn the code, so it is only stashed.
  Future<AuthOutcome> verifyOtp(
    String code, {
    bool isReset = false,
    GlobalKey<FormState>? form,
  }) async {
    if (isReset) {
      clearErrors();
      pendingCode.value = code.trim();
      return AuthOutcome.success;
    }
    return _run(
      form,
      () => _repo.verifyOtp(email: pendingEmail.value, code: code),
      (r) => _afterTokens(r, form),
    );
  }

  Future<AuthOutcome> resendOtp() =>
      _run(null, () => _repo.resendOtp(pendingEmail.value), (r) => _ack(r, null));

  Future<AuthOutcome> forgot(String email, [GlobalKey<FormState>? form]) =>
      _run(form, () => _repo.forgot(email), (r) {
        // ALWAYS 200 by design (no user enumeration), so success here means
        // "we tried", never "that account exists".
        return _ack(r, form, () => pendingEmail.value = _norm(email));
      });

  Future<AuthOutcome> reset(
    String code,
    String password, [
    GlobalKey<FormState>? form,
  ]) => _run(
    form,
    () =>
        _repo.reset(email: pendingEmail.value, code: code, password: password),
    (r) => _ack(r, form),
  );

  AuthOutcome _ack(
    ApiResult<MessageAck> r,
    GlobalKey<FormState>? form, [
    VoidCallback? onOk,
  ]) {
    if (r case Err(:final error)) {
      absorb(error, form);
      return AuthOutcome.failed;
    }
    onOk?.call();
    return AuthOutcome.success;
  }

  AuthOutcome _afterTokens(ApiResult<TokenPair> r, GlobalKey<FormState>? form) {
    switch (r) {
      case Err(:final error):
        absorb(error, form);
        return AuthOutcome.failed;
      case Ok(:final value):
        if (!_role.signInFromSession(value.user)) {
          // ADMIN: AppRole.fromWire is null and there is no app shell for it.
          _repo.logout();
          formError.value = 'Admin accounts sign in on the web console.';
          return AuthOutcome.failed;
        }
        _role.resetForceSignOutLatch();
        return AuthOutcome.success;
    }
  }

  /// One busy latch, one dialog, one error funnel. NEVER auto-retries:
  /// authRateLimit is 20 requests per 15 minutes across the WHOLE /v1/auth
  /// router, refresh included.
  Future<AuthOutcome> _run<T>(
    GlobalKey<FormState>? form,
    Future<ApiResult<T>> Function() call,
    AuthOutcome Function(ApiResult<T>) then,
  ) async {
    if (busy.value) return AuthOutcome.failed;
    clearErrors();
    busy.value = true;
    showBusy();
    try {
      return then(await call());
    } finally {
      // BOTH branches, and always before the caller navigates: Get.offAllNamed
      // strips the dialog route and leaves Get.isDialogOpen stale-true forever.
      busy.value = false;
      hideBusy();
    }
  }

  static String _norm(String v) => v.trim().toLowerCase();

  /// THE one place an ApiError becomes UI. Exhaustive with no `default:` on
  /// purpose — a 16th backend code must be a compile error here and nowhere
  /// else.
  @visibleForTesting
  void absorb(ApiError e, GlobalKey<FormState>? form) {
    switch (e.code) {
      case ApiErrorCode.validationError:
        fieldErrors.addAll(e.fieldErrors);
        form?.currentState?.validate();
        if (fieldErrors.isEmpty) formError.value = e.message;
      case ApiErrorCode.invalidCredentials:
        formError.value = 'Invalid email or password';
      case ApiErrorCode.conflict:
        fieldErrors['email'] = 'An account with this email already exists';
      case ApiErrorCode.otpInvalid:
        fieldErrors['code'] = 'That code is not correct';
      case ApiErrorCode.otpExpired:
        // Screens un-gate Resend on this one instead of making the user wait.
        fieldErrors['code'] = 'That code expired — request a new one';
      // tooManyAttempts and rateLimited carry the server's own wording and MUST
      // NOT be retried automatically.
      case ApiErrorCode.tooManyAttempts:
      case ApiErrorCode.rateLimited:
      case ApiErrorCode.verificationRequired:
      case ApiErrorCode.accountSuspended:
      case ApiErrorCode.forbidden:
      case ApiErrorCode.notApproved:
      case ApiErrorCode.notFound:
      case ApiErrorCode.insufficientCredits:
      case ApiErrorCode.unauthorized:
      case ApiErrorCode.internal:
      case ApiErrorCode.malformedResponse:
      case ApiErrorCode.unknown:
        formError.value = e.message;
      case ApiErrorCode.network:
      case ApiErrorCode.timeout:
        toast(e.message);
      case ApiErrorCode.sessionExpired:
        _role.forceSignOut();
    }
  }
}

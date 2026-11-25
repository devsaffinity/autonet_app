import 'package:autonect/constants/app_role.dart';
import 'package:autonect/controller/auth_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/auth_user.dart';
import 'package:autonect/data/models/token_pair.dart';
import 'package:autonect/services/session_store.dart';
import 'package:autonect/services/social_sign_in_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_social_sign_in.dart';

/// forceSignOut() navigates and toasts, neither of which exists in a unit test,
/// so it is stubbed to a counter here.
class SpyRoleController extends RoleController {
  int forced = 0;
  int latchResets = 0;

  @override
  void forceSignOut() => forced++;

  @override
  void resetForceSignOutLatch() => latchResets++;
}

TokenPair pairFor(String role, {String status = 'ACTIVE'}) => TokenPair(
  accessToken: 'A1',
  refreshToken: 'R1',
  user: AuthUser(id: 'u1', email: 'a@b.com', role: role, status: status),
);

void main() {
  late FakeAuthRepository repo;
  late SpyRoleController role;
  late AuthController c;
  late List<String> toasts;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStore.init();
    repo = FakeAuthRepository();
    role = SpyRoleController();
    toasts = [];
    c = AuthController(
      repo,
      role,
      toast: toasts.add,
      showBusy: () {},
      hideBusy: () {},
    );
  });

  ApiError err(ApiErrorCode code, {int? status, List<FieldError> f = const []}) =>
      ApiError(code: code, message: 'server copy', statusCode: status, fields: f);

  group('absorb covers every code', () {
    test('VALIDATION_ERROR fills per-field errors from details[]', () {
      c.absorb(
        err(ApiErrorCode.validationError, status: 400, f: const [
          FieldError('email', 'Invalid email address'),
          FieldError('password', 'Required'),
        ]),
        null,
      );
      expect(c.fieldErrorFor('email'), 'Invalid email address');
      expect(c.fieldErrorFor('password'), 'Required');
      expect(c.formError.value, isNull);
    });

    test('VALIDATION_ERROR with no details falls back to a banner', () {
      c.absorb(err(ApiErrorCode.validationError, status: 400), null);
      expect(c.formError.value, 'server copy');
    });

    test('INVALID_CREDENTIALS uses our own copy, not the server string', () {
      c.absorb(err(ApiErrorCode.invalidCredentials, status: 401), null);
      expect(c.formError.value, 'Invalid email or password');
    });

    test('CONFLICT lands on the email field', () {
      c.absorb(err(ApiErrorCode.conflict, status: 409), null);
      expect(c.fieldErrorFor('email'),
          'An account with this email already exists');
    });

    test('OTP_INVALID and OTP_EXPIRED land on the code field', () {
      c.absorb(err(ApiErrorCode.otpInvalid, status: 400), null);
      expect(c.fieldErrorFor('code'), 'That code is not correct');
      c.clearErrors();
      c.absorb(err(ApiErrorCode.otpExpired, status: 400), null);
      expect(c.fieldErrorFor('code'), contains('expired'));
    });

    const banners = [
      ApiErrorCode.tooManyAttempts,
      ApiErrorCode.rateLimited,
      ApiErrorCode.verificationRequired,
      ApiErrorCode.accountSuspended,
      ApiErrorCode.forbidden,
      ApiErrorCode.notApproved,
      ApiErrorCode.notFound,
      ApiErrorCode.insufficientCredits,
      ApiErrorCode.unauthorized,
      ApiErrorCode.internal,
      ApiErrorCode.malformedResponse,
      ApiErrorCode.unknown,
    ];
    for (final code in banners) {
      test('${code.wire} shows the server message as a banner', () {
        c.clearErrors();
        c.absorb(err(code), null);
        expect(c.formError.value, 'server copy');
        expect(toasts, isEmpty);
      });
    }

    test('network and timeout toast instead of blocking the form', () {
      c.absorb(err(ApiErrorCode.network), null);
      c.absorb(err(ApiErrorCode.timeout), null);
      expect(toasts.length, 2);
      expect(c.formError.value, isNull);
    });

    test('sessionExpired delegates to RoleController.forceSignOut', () {
      c.absorb(err(ApiErrorCode.sessionExpired), null);
      expect(role.forced, 1);
    });
  });

  group('google sign-in', () {
    late FakeSocialSignInGateway social;
    late AuthController g;

    setUp(() {
      social = FakeSocialSignInGateway();
      g = AuthController(
        repo,
        role,
        toast: toasts.add,
        showBusy: () {},
        hideBusy: () {},
        social: social,
      );
    });

    test('sends the Firebase token and the picked role, then signs in',
        () async {
      social.result = const SocialSignInSuccess('FB-TOKEN');
      repo.tokenResult = Ok(pairFor('SUPPLIER'));
      expect(await g.google(role: AppRole.supplier), AuthOutcome.success);
      expect(repo.calls.single, 'social:GOOGLE:FB-TOKEN:SUPPLIER');
      expect(role.role.value, AppRole.supplier);
      expect(role.isLoggedIn.value, isTrue);
      expect(role.latchResets, 1);
      expect(g.busy.value, isFalse);
    });

    test('login sends no role', () async {
      social.result = const SocialSignInSuccess('FB-TOKEN');
      repo.tokenResult = Ok(pairFor('BUYER'));
      await g.google();
      expect(repo.calls.single, 'social:GOOGLE:FB-TOKEN:null');
    });

    test('a cancelled picker is silent and sends nothing', () async {
      social.result = const SocialSignInCancelled();
      expect(await g.google(), AuthOutcome.failed);
      expect(repo.calls, isEmpty);
      expect(g.formError.value, isNull);
      expect(toasts, isEmpty);
    });

    test('a failed sign-in shows its message and sends nothing', () async {
      social.result = const SocialSignInFailed('Google went wrong');
      expect(await g.google(), AuthOutcome.failed);
      expect(repo.calls, isEmpty);
      expect(g.formError.value, 'Google went wrong');
    });

    test('an unknown Google address with no role points to Sign Up', () async {
      social.result = const SocialSignInSuccess('FB-TOKEN');
      repo.tokenResult = Err(
        err(
          ApiErrorCode.validationError,
          status: 400,
          f: const [FieldError('role', 'Required')],
        ),
      );
      expect(await g.google(), AuthOutcome.failed);
      expect(g.formError.value, contains('Sign Up'));
      expect(g.fieldErrorFor('role'), isNull);
      // Not left signed in to Google, so the next tap shows the picker.
      expect(social.signOuts, 1);
    });

    test('a server rejection shows its message and drops the Google session',
        () async {
      social.result = const SocialSignInSuccess('FB-TOKEN');
      repo.tokenResult = Err(err(ApiErrorCode.accountSuspended, status: 403));
      expect(await g.google(), AuthOutcome.failed);
      expect(g.formError.value, 'server copy');
      expect(role.isLoggedIn.value, isFalse);
      expect(social.signOuts, 1);
    });

    test('ADMIN cannot sign in with Google either', () async {
      social.result = const SocialSignInSuccess('FB-TOKEN');
      repo.tokenResult = Ok(pairFor('ADMIN'));
      expect(await g.google(), AuthOutcome.failed);
      expect(role.isLoggedIn.value, isFalse);
      expect(g.formError.value, contains('web console'));
    });

    test('unavailable gateway reports it instead of doing nothing', () async {
      social.supported = false;
      expect(g.googleAvailable, isFalse);
      expect(await g.google(), AuthOutcome.failed);
      expect(social.picks, 0);
      expect(g.formError.value, contains('not available'));
    });

    test('no gateway at all is also unavailable', () async {
      expect(c.googleAvailable, isFalse);
      expect(await c.google(), AuthOutcome.failed);
    });
  });

  group('flows', () {
    test('login success signs in and resets the force-sign-out latch', () async {
      repo.tokenResult = Ok(pairFor('SUPPLIER'));
      expect(await c.login('A@B.com', 'Passw0rd'), AuthOutcome.success);
      expect(role.role.value, AppRole.supplier);
      expect(role.isLoggedIn.value, isTrue);
      expect(role.latchResets, 1);
      expect(c.busy.value, isFalse);
    });

    test('ADMIN cannot sign in — it has no app shell', () async {
      repo.tokenResult = Ok(pairFor('ADMIN'));
      expect(await c.login('a@b.com', 'Passw0rd'), AuthOutcome.failed);
      expect(role.isLoggedIn.value, isFalse);
      expect(c.formError.value, contains('web console'));
      expect(repo.calls, contains('logout'));
    });

    test('VERIFICATION_REQUIRED is a detour, not a banner', () async {
      repo.tokenResult = Err(err(ApiErrorCode.verificationRequired, status: 403));
      expect(await c.login(' A@B.com ', 'Passw0rd'),
          AuthOutcome.verificationRequired);
      expect(c.pendingEmail.value, 'a@b.com');
      expect(c.formError.value, isNull);
    });

    test('signup stashes the normalised email and returns no session', () async {
      expect(
        await c.signup(
          email: ' A@B.com ',
          password: 'Passw0rd',
          name: 'A',
          role: AppRole.buyer,
        ),
        AuthOutcome.success,
      );
      expect(c.pendingEmail.value, 'a@b.com');
      expect(role.isLoggedIn.value, isFalse);
      // Normalising the wire body is the repository's job, not the
      // controller's — see auth_repository_test.
      expect(repo.calls.single, endsWith(':BUYER'));
    });

    test('verifyOtp(isReset: true) only stashes the code — /reset consumes it',
        () async {
      expect(await c.verifyOtp('123456', isReset: true), AuthOutcome.success);
      expect(c.pendingCode.value, '123456');
      expect(repo.calls, isEmpty);
    });

    test('forgot never reveals whether the account exists', () async {
      expect(await c.forgot('A@B.com'), AuthOutcome.success);
      expect(c.pendingEmail.value, 'a@b.com');
      expect(c.formError.value, isNull);
    });

    test('a busy controller refuses a second call — auth is rate limited',
        () async {
      repo.tokenResult = Ok(pairFor('BUYER'));
      final first = c.login('a@b.com', 'Passw0rd');
      final second = await c.login('a@b.com', 'Passw0rd');
      expect(second, AuthOutcome.failed);
      await first;
      expect(repo.calls.where((x) => x.startsWith('login')).length, 1);
    });

    test('clearFieldError drops one message as the user retypes', () {
      c.absorb(err(ApiErrorCode.conflict, status: 409), null);
      c.clearFieldError('email');
      expect(c.fieldErrorFor('email'), isNull);
    });
  });
}

import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_role.dart';
import 'package:autonect/controller/auth_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/repositories/chat_repository.dart';
import 'package:autonect/data/models/auth_user.dart';
import 'package:autonect/data/models/token_pair.dart';
import 'package:autonect/data/repositories/auth_repository.dart';
import 'package:autonect/services/session_store.dart';
import 'package:autonect/view/screens/auth/login.dart';
import 'package:autonect/view/screens/auth/register.dart';
import 'package:autonect/view/screens/auth/reset_password.dart';
import 'package:autonect/view/screens/auth/verify_otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_auth_repository.dart';

/// The screens' own guarantee. The auth pages were INERT before this phase:
/// login.dart had no controllers, no form key and no validator, so "Sign In"
/// succeeded on empty fields and walked straight into the app shell. These
/// tests exist so that cannot come back.
void main() {
  late FakeAuthRepository repo;
  late AuthController auth;

  const buyer = AuthUser(
    id: 'u1',
    email: 'a@b.com',
    role: 'BUYER',
    status: 'ACTIVE',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStore.init();
    Get.reset();
    repo = FakeAuthRepository();
    Get.put<AuthRepository>(repo);
    Get.put(RoleController());
    // The screens call AuthController.ensure(), which is find-or-create, so
    // this is the instance they will pick up.
    auth = Get.put(
      AuthController(
        repo,
        RoleController.to,
        // Fluttertoast is a platform channel and showLoadingDialog needs a
        // navigator that outlives the pump; both are stubbed out.
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      ),
    );
  });

  tearDown(Get.reset);

  /// Advances a couple of frames WITHOUT draining timers, so a screen that owns
  /// a countdown can still be observed mid-cooldown.
  Future<void> tick(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }

  /// Two things on VerifyOtpPage keep a frame scheduled forever: the 1-second
  /// periodic countdown, and the blinking cursor of the autofocused OTP field.
  /// The countdown cancels itself at zero, so jumping past the whole 60-second
  /// cooldown kills it; the cursor needs an explicit unfocus. Only then can the
  /// tree settle.
  Future<void> drain(WidgetTester tester) async {
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
  }

  /// Stand-ins for the real shells: this exercises the routing decision without
  /// dragging BuyerNavBar and its own state into an auth test.
  Widget app(Widget home) => GetMaterialApp(
    home: home,
    getPages: [
      GetPage(name: AppLinks.login, page: () => LoginPage()),
      GetPage(name: AppLinks.role, page: () => const _Stub('ROLE PICKER')),
      GetPage(name: AppLinks.buyerShell, page: () => const _Stub('BUYER SHELL')),
      GetPage(
        name: AppLinks.electricianOnboarding,
        page: () => const _Stub('ELECTRICIAN ONBOARDING'),
      ),
    ],
  );

  Finder emailField() => find.ancestor(
    of: find.text('example@domain.com'),
    matching: find.byType(TextFormField),
  );
  Finder passwordField() => find.ancestor(
    of: find.text('Enter your password'),
    matching: find.byType(TextFormField),
  );

  group('login screen', () {
    Future<void> pumpLogin(WidgetTester tester) async {
      await tester.pumpWidget(app(LoginPage()));
      await tester.pumpAndSettle();
    }

    /// Deliberately does not settle: one case lands on VerifyOtpPage, whose
    /// countdown keeps a frame scheduled forever. Each test settles the way its
    /// own destination allows.
    Future<void> fillAndSubmit(
      WidgetTester tester,
      String email,
      String password,
    ) async {
      await tester.enterText(emailField(), email);
      await tester.enterText(passwordField(), password);
      await tester.tap(find.text('Sign In'));
      await tick(tester);
    }

    testWidgets('empty fields do NOT reach the network', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // THE regression this whole phase exists to kill.
      expect(repo.calls, isEmpty);
      expect(find.text('Email cannot be empty'), findsOneWidget);
      expect(find.text('Password cannot be empty'), findsOneWidget);
    });

    testWidgets('a malformed email is rejected client-side', (tester) async {
      await pumpLogin(tester);
      await fillAndSubmit(tester, 'not-an-email', 'Password1');
      await tester.pumpAndSettle();

      // Never spend one of authRateLimit's 20-per-15-minutes on a value the
      // server would only bounce with VALIDATION_ERROR.
      expect(repo.calls, isEmpty);
      // Exactly once: MyTextField's TextFormField sits inside
      // ClipRRect(radius 100), which eats the built-in error text, so the
      // message is drawn below the clip instead. It must not ALSO be emitted
      // (invisibly) inside it, or a screen reader announces it twice.
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('bad credentials FAIL and stay on the form', (tester) async {
      repo.tokenResult = const Err(
        ApiError(
          code: ApiErrorCode.invalidCredentials,
          message: 'Invalid email or password',
          statusCode: 401,
        ),
      );
      await pumpLogin(tester);
      await fillAndSubmit(tester, 'nobody@example.invalid', 'Password1');
      await tester.pumpAndSettle();

      expect(repo.calls, ['login:nobody@example.invalid']);
      expect(auth.formError.value, 'Invalid email or password');
      expect(find.text('Invalid email or password'), findsOneWidget);
      // Still on the login page: no session was established.
      expect(find.byType(LoginPage), findsOneWidget);
      expect(RoleController.to.isLoggedIn.value, isFalse);
    });

    testWidgets('the raw field value is handed to the repository seam', (
      tester,
    ) async {
      repo.tokenResult = const Err(ApiError.timeout());
      await pumpLogin(tester);
      await fillAndSubmit(tester, '  User@Example.COM ', 'Password1');
      await tester.pumpAndSettle();

      // Trimming and lowercasing belong to AuthApiRepository._n (auth.dto.ts
      // uses z.email().toLowerCase()). Screens deliberately do NOT re-normalise
      // — two places doing it is two places to drift.
      expect(repo.calls, ['login:  User@Example.COM ']);
    });

    testWidgets('VERIFICATION_REQUIRED resends and pushes the OTP screen', (
      tester,
    ) async {
      repo.tokenResult = const Err(
        ApiError(
          code: ApiErrorCode.verificationRequired,
          message: 'Verify your email',
          statusCode: 403,
        ),
      );
      await pumpLogin(tester);
      await fillAndSubmit(tester, 'pending@example.com', 'Password1');
      await tester.pump(const Duration(milliseconds: 500));

      // A detour, not a dead-end error banner (403, not 401).
      expect(repo.calls, [
        'login:pending@example.com',
        'resend:pending@example.com',
      ]);
      expect(find.byType(VerifyOtpPage), findsOneWidget);
      expect(auth.formError.value, isNull);
      await drain(tester);
    });

    testWidgets('a successful login routes on the SERVER role', (tester) async {
      // The picker says electrician; the token payload says buyer. The server
      // must win — that is the whole point of retiring signIn(AppRole).
      RoleController.to.selectRole(AppRole.electrician);
      repo.tokenResult = const Ok(
        TokenPair(accessToken: 'a', refreshToken: 'r', user: buyer),
      );
      await pumpLogin(tester);
      await fillAndSubmit(tester, 'a@b.com', 'Password1');
      await tester.pumpAndSettle();

      expect(RoleController.to.role.value, AppRole.buyer);
      expect(RoleController.to.isLoggedIn.value, isTrue);
      // Landed on the BUYER shell, not the electrician onboarding the local
      // pick would have produced.
      expect(find.text('BUYER SHELL'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('the button is inert while a call is in flight', (
      tester,
    ) async {
      auth.busy.value = true;
      await pumpLogin(tester);

      expect(find.text('Signing in…'), findsOneWidget);
      await tester.tap(find.text('Signing in…'));
      await tester.pumpAndSettle();

      // No blind retry: authRateLimit is 20 per 15 minutes across the WHOLE
      // /v1/auth router, refresh included.
      expect(repo.calls, isEmpty);
    });
  });

  group('register screen', () {
    // EditableText order: name, email, password, confirm.
    Future<void> pumpRegister(WidgetTester tester) async {
      await tester.pumpWidget(app(RegisterPage()));
      await tester.pumpAndSettle();
    }

    Future<void> fill(WidgetTester tester, String password) async {
      await tester.enterText(find.byType(EditableText).at(0), 'Jane');
      await tester.enterText(find.byType(EditableText).at(1), 'new@example.com');
      await tester.enterText(find.byType(EditableText).at(2), password);
      await tester.enterText(find.byType(EditableText).at(3), password);
      await tester.pumpAndSettle();
    }

    /// The signup form is taller than the 800x600 test viewport, so the button
    /// and the checkbox have to be scrolled into view before they can be hit.
    Future<void> tapVisible(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    testWidgets('the T&C checkbox gates the button', (tester) async {
      await pumpRegister(tester);
      await fill(tester, 'Password1');

      // Un-ticked: MyButton.onTap is null, so the InkWell takes no hit at all.
      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);

      // Ticked: the same tap now reaches the network. Not settled fully —
      // a successful signup pushes VerifyOtpPage, whose countdown would keep
      // pumpAndSettle spinning.
      await tapVisible(tester, find.byType(Checkbox));
      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tick(tester);

      expect(repo.calls, isNotEmpty);
      await drain(tester);
    });

    testWidgets('a weak password never reaches /v1/auth/signup', (
      tester,
    ) async {
      await pumpRegister(tester);
      await fill(tester, 'alllowercase');
      await tapVisible(tester, find.byType(Checkbox));
      await tapVisible(tester, find.text('Sign Up'));

      expect(repo.calls, isEmpty);
      expect(
        find.text('Password must contain a capital letter'),
        findsOneWidget,
      );
    });

    testWidgets('signup sends the PICKED role and does NOT sign in', (
      tester,
    ) async {
      // The account does not exist yet, so this is the one moment the local
      // pick is legitimately authoritative.
      RoleController.to.selectRole(AppRole.supplier);
      await pumpRegister(tester);
      await fill(tester, 'Password1');
      await tapVisible(tester, find.byType(Checkbox));

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.calls, ['signup:new@example.com:SUPPLIER']);
      // Signup returns NO tokens: the account is PENDING_VERIFICATION, so the
      // user must land on the OTP screen and must NOT be logged in.
      expect(find.byType(VerifyOtpPage), findsOneWidget);
      expect(RoleController.to.isLoggedIn.value, isFalse);
      expect(auth.pendingEmail.value, 'new@example.com');
      await drain(tester);
    });
  });

  group('otp screen', () {
    Future<void> pumpOtp(WidgetTester tester) async {
      auth.pendingEmail.value = 'pending@example.com';
      await tester.pumpWidget(
        app(const VerifyOtpPage(email: 'pending@example.com')),
      );
      await tick(tester);
    }

    Future<void> submitCode(WidgetTester tester, String code) async {
      await tester.enterText(find.byType(EditableText).first, code);
      await tick(tester);
      await tester.tap(find.text('Verify'));
      // Only after the tap: _verify() unfocuses, and drain then clears the
      // countdown before settling.
      await drain(tester);
    }

    testWidgets('a short code never reaches otp/verify', (tester) async {
      await pumpOtp(tester);
      await submitCode(tester, '123');

      expect(repo.calls, isEmpty);
      expect(find.text('The code is 6 digits'), findsOneWidget);
    });

    testWidgets('resend is gated by the 60s server cooldown', (tester) async {
      await pumpOtp(tester);

      // OTP.RESEND_COOLDOWN_SEC is 60 (constants.ts:19). Letting the user tap
      // freely is how they manufacture a RATE_LIMITED for themselves.
      expect(find.text('Resend in 60s'), findsOneWidget);
      // warnIfMissed: false because the miss IS the assertion — the label's
      // onTap is null while the cooldown runs, so it takes no hit at all.
      await tester.tap(find.text('Resend in 60s'), warnIfMissed: false);
      await tick(tester);
      expect(repo.calls, isEmpty);

      // The countdown is live, not a static label.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend in 59s'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('resend fires once the cooldown expires', (tester) async {
      await pumpOtp(tester);

      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Resend'), findsOneWidget);

      await tester.tap(find.text('Resend'));
      await tick(tester);

      expect(repo.calls, ['resend:pending@example.com']);
      // And the clock restarts, so the next tap cannot immediately follow.
      expect(find.text('Resend in 60s'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('a valid code verifies and establishes the session', (
      tester,
    ) async {
      repo.tokenResult = const Ok(
        TokenPair(accessToken: 'a', refreshToken: 'r', user: buyer),
      );
      await pumpOtp(tester);
      await submitCode(tester, '123456');

      expect(repo.calls, ['verify:pending@example.com:123456']);
      expect(RoleController.to.isLoggedIn.value, isTrue);
      // The account-created sheet belongs HERE, not on signup: signup returns
      // no tokens, so celebrating there announces a session that does not
      // exist yet.
      expect(find.text('Account Creation successful!'), findsOneWidget);
    });

    testWidgets('OTP_EXPIRED lands on the code field, not a banner', (
      tester,
    ) async {
      repo.tokenResult = const Err(
        ApiError(
          code: ApiErrorCode.otpExpired,
          message: 'expired',
          statusCode: 400,
        ),
      );
      await pumpOtp(tester);
      await submitCode(tester, '123456');

      expect(find.text('That code expired — request a new one'), findsOneWidget);
      expect(auth.formError.value, isNull);
    });
  });

  group('reset screen', () {
    // EditableText 0 is the Pinput (one editable backs all six boxes), then the
    // new password and its confirmation.
    Future<void> pumpReset(WidgetTester tester) async {
      auth.pendingEmail.value = 'a@b.com';
      await tester.pumpWidget(app(const ResetPasswordPage()));
      await tester.pumpAndSettle();
    }

    Future<void> fill(
      WidgetTester tester,
      String code,
      String password,
      String confirm,
    ) async {
      await tester.enterText(find.byType(EditableText).first, code);
      await tester.enterText(find.byType(EditableText).at(1), password);
      await tester.enterText(find.byType(EditableText).at(2), confirm);
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();
    }

    testWidgets('a weak new password never reaches /v1/auth/reset', (
      tester,
    ) async {
      await pumpReset(tester);
      await fill(tester, '123456', 'alllowercase', 'alllowercase');

      // auth.dto.ts demands a capital; mirroring it client-side saves the user
      // a round-trip and saves one of the 20 allowed requests.
      expect(repo.calls, isEmpty);
      expect(
        find.text('Password must contain a capital letter'),
        findsOneWidget,
      );
    });

    testWidgets('a mismatched confirmation is caught client-side', (
      tester,
    ) async {
      await pumpReset(tester);
      await fill(tester, '123456', 'Password1', 'Password2');

      expect(repo.calls, isEmpty);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('a good reset posts email+code+password together', (
      tester,
    ) async {
      await pumpReset(tester);
      await fill(tester, '123456', 'Password1', 'Password1');

      // ONE request. The code is never pre-verified against otp/verify, which
      // would consume it and make this call fail.
      expect(repo.calls, ['reset:a@b.com:123456']);
    });
  });
}

class _Stub extends StatelessWidget {
  const _Stub(this.label);
  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

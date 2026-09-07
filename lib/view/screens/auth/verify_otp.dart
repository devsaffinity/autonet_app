import 'dart:async';

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/auth_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/screens/auth/login.dart';
import 'package:autonect/view/screens/auth/register.dart';
import 'package:autonect/view/screens/auth/reset_password.dart';
import 'package:autonect/view/widget/animation_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/otp_fields.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum OtpPurpose {
  /// POST /v1/auth/otp/verify — returns TOKENS and completes the sign-up.
  signup,

  /// The code belongs to the forgot-password flow. /v1/auth/reset consumes it
  /// TOGETHER WITH the new password, so verifying it here would burn it.
  passwordReset,
}

/// A PUSH, not a named route: routes.dart:1-5 is binding and the table stays at
/// 11 entries. Reached with `Get.to(() => VerifyOtpPage(email: ...))`.
class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({
    super.key,
    required this.email,
    this.purpose = OtpPurpose.signup,
  });

  final String email;
  final OtpPurpose purpose;

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  /// OTP.RESEND_COOLDOWN_SEC (constants.ts:19). The button is dead until this
  /// reaches zero, so the user cannot manufacture a RATE_LIMITED by tapping.
  static const _cooldownSec = 60;

  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();

  late final AuthController c;
  Timer? _timer;
  int _secondsLeft = _cooldownSec;

  @override
  void initState() {
    super.initState();
    c = AuthController.ensure();
    // The caller may have pushed here from login's 403 branch, where
    // pendingEmail was set from the login field rather than from signup.
    if (widget.email.isNotEmpty) c.pendingEmail.value = widget.email;
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSec);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;

    final isReset = widget.purpose == OtpPurpose.passwordReset;
    final outcome = await c.verifyOtp(
      _code.text,
      isReset: isReset,
      form: _form,
    );
    if (!mounted || outcome != AuthOutcome.success) return;

    if (isReset) {
      // No network call was made; the code is stashed for /v1/auth/reset.
      Get.to(() => const ResetPasswordPage());
      return;
    }

    // Tokens are in hand and RoleController already took the SERVER's role.
    // This is where the account-created sheet belongs — signup itself returns
    // no tokens, so showing it there would celebrate a session that is not yet
    // established.
    Get.bottomSheet(
      AccountCreatedBSheet(
        onContinue: () async {
          Get.back();
          // Server truth before routing, same as login. A brand new supplier
          // has no profile yet, so this correctly lands them on the wizard.
          await RoleController.to.syncProviderAccess();
          Get.offAllNamed(RoleController.to.landingRoute);
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || c.busy.value) return;
    final outcome = await c.resendOtp();
    if (!mounted) return;
    if (outcome == AuthOutcome.success) {
      _code.clear();
      displayToast(msg: "We sent a new code to ${c.pendingEmail.value}");
    }
    // Restart the clock either way: a failed resend that leaves the button live
    // is exactly how a user walks into TOO_MANY_ATTEMPTS.
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeSlideTransition(
          child: SingleChildScrollView(
            padding: AppSizes.DEFAULT,
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MyBackButton(),

                  MyText(
                    paddingBottom: 10,
                    text: "Verify your email",
                    size: 24,
                    weight: FontWeight.w700,
                    color: kSecondaryColor,
                  ),
                  Obx(
                    () => MyText(
                      paddingBottom: 32,
                      text:
                          "Enter the 6-digit code we sent to ${c.pendingEmail.value}.",
                      size: 16,
                      weight: FontWeight.w400,
                      maxLines: 3,
                    ),
                  ),

                  Obx(
                    () => OtpFields(
                      controller: _code,
                      errorText: c.fieldErrorFor('code'),
                      validator: (v) =>
                          c.fieldErrorFor('code') ?? validateOtpCode(v),
                      // Deliberately NOT auto-submitting: a mistyped code would
                      // spend an attempt the moment the sixth digit lands.
                      onCompleted: (_) => c.clearFieldError('code'),
                    ),
                  ),

                  const AuthFormError(),

                  SizedBox(height: 24),
                  _ResendRow(
                    secondsLeft: _secondsLeft,
                    onResend: _resend,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
        child: Obx(
          () => MyButton(
            onTap: c.busy.value ? null : _verify,
            backgroundColor: c.busy.value
                ? kSecondaryColor.withValues(alpha: .6)
                : kSecondaryColor,
            buttonText: c.busy.value ? "Verifying…" : "Verify",
          ),
        ),
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.secondsLeft, required this.onResend});

  final int secondsLeft;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final waiting = secondsLeft > 0;
    return Row(
      children: [
        MyText(
          text: "Didn't get the code? ",
          size: 14,
          weight: FontWeight.w400,
          color: kGreyTextColor,
        ),
        MyText(
          text: waiting ? "Resend in ${secondsLeft}s" : "Resend",
          size: 14,
          weight: FontWeight.w700,
          color: waiting ? kGreyTextColor : kSecondaryColor,
          onTap: waiting ? null : onResend,
        ),
      ],
    );
  }
}

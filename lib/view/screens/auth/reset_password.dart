import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/auth_controller.dart';
import 'package:autonect/view/screens/auth/login.dart';
import 'package:autonect/view/widget/animation_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/otp_fields.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// POST /v1/auth/reset takes {email, code, password} in ONE request: the code
/// is consumed together with the new password. That is why this screen carries
/// the OTP boxes itself rather than sitting behind /v1/auth/otp/verify —
/// verifying first would burn the code and the reset would then fail.
///
/// A PUSH (routes.dart:1-5), so `Get.to(() => const ResetPasswordPage())`.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool isObSecure = false;
  late final AuthController c;

  @override
  void initState() {
    super.initState();
    c = AuthController.ensure();
    // Populated when the user came via VerifyOtpPage(purpose: passwordReset),
    // which stashes the code without spending it.
    if (c.pendingCode.value.isNotEmpty) _code.text = c.pendingCode.value;
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;

    final outcome = await c.reset(_code.text, _password.text, _form);
    if (!mounted || outcome != AuthOutcome.success) return;

    // A reset revokes EVERY session server-side, so there is nothing to sign
    // the user into here — the repository has already cleared the token store.
    displayToast(msg: "Password updated — please log in");
    Get.offAllNamed(AppLinks.login);
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
                    text: "Set a new password",
                    size: 24,
                    weight: FontWeight.w700,
                    color: kSecondaryColor,
                  ),
                  Obx(
                    () => MyText(
                      paddingBottom: 28,
                      text: c.pendingEmail.value.isEmpty
                          ? "Enter the 6-digit code from your email, then choose a new password."
                          : "Enter the 6-digit code sent to ${c.pendingEmail.value}, then choose a new password.",
                      size: 16,
                      weight: FontWeight.w400,
                      maxLines: 3,
                    ),
                  ),

                  Obx(
                    () => OtpFields(
                      controller: _code,
                      autofocus: false,
                      errorText: c.fieldErrorFor('code'),
                      validator: (v) =>
                          c.fieldErrorFor('code') ?? validateOtpCode(v),
                      onCompleted: (_) => c.clearFieldError('code'),
                    ),
                  ),

                  SizedBox(height: 28),

                  Obx(
                    () => PasswordTextField(
                      controller: _password,
                      labelText: "New Password",
                      isObSecure: isObSecure,
                      errorText: c.fieldErrorFor('password'),
                      validator: (v) =>
                          c.fieldErrorFor('password') ??
                          validateStrongPassword(v),
                      onChanged: (_) => c.clearFieldError('password'),
                      onTap: () => setState(() => isObSecure = !isObSecure),
                    ),
                  ),
                  PasswordTextField(
                    controller: _confirm,
                    labelText: "Confirm New Password",
                    hintText: "Re-enter your new password",
                    isObSecure: isObSecure,
                    textInputAction: TextInputAction.done,
                    validator: (v) =>
                        (v != _password.text) ? 'Passwords do not match' : null,
                    onTap: () => setState(() => isObSecure = !isObSecure),
                  ),

                  const AuthFormError(),
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
            onTap: c.busy.value ? null : _submit,
            backgroundColor: c.busy.value
                ? kSecondaryColor.withValues(alpha: .6)
                : kSecondaryColor,
            buttonText: c.busy.value ? "Updating…" : "Reset Password",
          ),
        ),
      ),
    );
  }
}

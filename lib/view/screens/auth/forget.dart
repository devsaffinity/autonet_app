import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/auth_controller.dart';
import 'package:autonect/view/screens/auth/login.dart';
import 'package:autonect/view/screens/auth/reset_password.dart';
import 'package:autonect/view/widget/animation_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPage extends StatefulWidget {
  @override
  State<ForgetPage> createState() => _ForgetPageState();
}

class _ForgetPageState extends State<ForgetPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  late final AuthController c;

  @override
  void initState() {
    super.initState();
    c = AuthController.ensure();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;

    final outcome = await c.forgot(_email.text, _form);
    if (!mounted || outcome != AuthOutcome.success) return;

    // /v1/auth/forgot ALWAYS returns 200 — the server deliberately refuses to
    // leak whether an account exists. So this copy must stay conditional:
    // "we sent you a code" would be a user-enumeration oracle in the UI that
    // the API was written to avoid.
    displayToast(msg: "If an account exists for that email, we sent a code.");
    Get.to(() => const ResetPasswordPage());
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The screen previously had NO back affordance and no working
                  // button, so it was a hard dead end.
                  const MyBackButton(),

                  Header(
                    heading: "Forgot your Password?",
                    title1:
                        "Enter your email address and we will send an OTP to create a new password.",
                    title: " ",
                    subTitle: "",
                    onTap: () {},
                  ),

                  SizedBox(height: 20),

                  Obx(
                    () => MyTextField(
                      controller: _email,
                      labelText: "Email Address",
                      hintText: "example@domain.com",
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      textInputAction: TextInputAction.done,
                      errorText: c.fieldErrorFor('email'),
                      validator: (v) =>
                          c.fieldErrorFor('email') ?? validateEmail(v),
                      onChanged: (_) => c.clearFieldError('email'),
                    ),
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
            buttonText: c.busy.value ? "Sending…" : "Continue",
          ),
        ),
      ),
    );
  }
}

import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/auth_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/screens/auth/forget.dart';
import 'package:autonect/view/screens/auth/verify_otp.dart';
import 'package:autonect/view/widget/animation_widget.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_checkbox.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool isSelected = false;
  bool isObSecure = false;

  final RoleController roleController = Get.find<RoleController>();
  late final AuthController c;

  @override
  void initState() {
    super.initState();
    c = AuthController.ensure();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    // Client-side first, so an obviously bad email never spends one of the 20
    // requests authRateLimit allows per 15 minutes.
    if (!(_form.currentState?.validate() ?? false)) return;

    final outcome = await c.login(_email.text, _password.text, _form);
    if (!mounted) return;

    switch (outcome) {
      case AuthOutcome.success:
        // Ask the server where a supplier belongs BEFORE routing: landingRoute
        // reads flags that otherwise come from this device's storage, which is
        // cleared on every sign-out. No-op for other roles.
        await roleController.syncProviderAccess();
        if (!mounted) return;
        // landingRoute is the ONLY role -> destination mapping in the app, and
        // the role inside it now came from the server's token payload.
        Get.offAllNamed(roleController.landingRoute);
      case AuthOutcome.verificationRequired:
        // 403 VERIFICATION_REQUIRED (auth.service.ts:95-97) is a detour, not a
        // dead end: the account exists but never confirmed its OTP.
        await c.resendOtp();
        if (!mounted) return;
        Get.to(() => VerifyOtpPage(email: c.pendingEmail.value));
      case AuthOutcome.failed:
        break; // formError / fieldErrors are already bound below.
    }
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
                  Header(
                    heading: "Log In",
                    title1: "Log in to continue your journey.",
                    title: "Don’t have an account? ",
                    subTitle: "Sign Up",
                    onTap: () {
                      Get.toNamed(AppLinks.register);
                    },
                  ),

                  SizedBox(height: 40),

                  Obx(
                    () => MyTextField(
                      controller: _email,
                      labelText: "Email Address",
                      hintText: "example@domain.com",
                      keyboardType: TextInputType.emailAddress,
                      // The server lowercases every email; letting the soft
                      // keyboard capitalise it makes the OTP row lookup miss.
                      textCapitalization: TextCapitalization.none,
                      errorText: c.fieldErrorFor('email'),
                      validator: (v) => c.fieldErrorFor('email') ?? validateEmail(v),
                      onChanged: (_) => c.clearFieldError('email'),
                    ),
                  ),

                  Obx(
                    () => PasswordTextField(
                      controller: _password,
                      labelText: "Password",
                      hintText: "Enter your password",
                      isObSecure: isObSecure,
                      textInputAction: TextInputAction.done,
                      errorText: c.fieldErrorFor('password'),
                      // LOGIN ONLY: loginBodySchema is z.string().min(1), so a
                      // strength rule here would lock out any account whose
                      // password predates the current policy.
                      validator: (v) =>
                          c.fieldErrorFor('password') ??
                          ((v == null || v.isEmpty)
                              ? 'Password cannot be empty'
                              : null),
                      onChanged: (_) => c.clearFieldError('password'),
                      onTap: () {
                        setState(() => isObSecure = !isObSecure);
                      },
                    ),
                  ),
                  SizedBox(height: 12),

                  Row(
                    children: [
                      MyCheckBox(
                        isChecked: isSelected,
                        onChanged: (value) {
                          setState(() {
                            isSelected = value!;
                          });
                        },
                      ),
                      MyText(
                        paddingLeft: 4,
                        text: "Remember me",
                        size: 14,
                        weight: FontWeight.w400,
                        color: kGreyTextColor,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                      Spacer(),
                      MyText(
                        text: "Forgot password?",
                        size: 14,
                        weight: FontWeight.w500,
                        color: kSecondaryColor,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                        onTap: () {
                          Get.to(() => ForgetPage());
                        },
                      ),
                    ],
                  ),

                  const AuthFormError(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsetsGeometry.only(left: 20, right: 20, bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => MyButton(
                mBottom: 12,
                // MyButton.onTap is VoidCallback? and InkWell goes inert on
                // null, so this is a real gate, not just a label change. No
                // blind retry: every /v1/auth route is rate-limited.
                onTap: c.busy.value ? null : _submit,
                backgroundColor: c.busy.value
                    ? kSecondaryColor.withValues(alpha: .6)
                    : kSecondaryColor,
                buttonText: c.busy.value ? "Signing in…" : "Sign In",
              ),
            ),

            MyText(
              paddingBottom: 20,
              paddingTop: 10,
              text: "OR",
              size: 14,
              weight: FontWeight.w500,
              color: kGreyTextColor,
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                List<String> icons = [
                  Assets.imagesGoogleIcon,
                  Assets.imagesAppleLogo,
                ];
                return Padding(
                  padding: EdgeInsetsGeometry.only(bottom: 10),
                  child: SocialBtn(
                    icon: icons[index],
                    color: kWhiteColor,
                    // Was inverted against the icons: index 0 is the Google
                    // asset and read "Continue With Apple".
                    title: (index == 0)
                        ? "Continue With Google"
                        : "Continue With Apple",
                    // POST /v1/auth/social needs a real idToken from the
                    // Google/Apple SDKs, which are not wired this phase.
                    onTap: () {},
                  ),
                );
              }),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// The form-level error banner, shared by all four auth screens. Anything the
/// server says that is not attributable to one field lands here — bad
/// credentials, RATE_LIMITED, a 500 — rather than in a toast that scrolls away.
class AuthFormError extends StatelessWidget {
  const AuthFormError({super.key, this.paddingTop = 16});

  final double paddingTop;

  @override
  Widget build(BuildContext context) {
    // Get.offAllNamed can rebuild a departing auth page one last time AFTER
    // the controller has been disposed with its route, and a bare Get.find
    // there would throw during the exit transition.
    if (!Get.isRegistered<AuthController>()) return const SizedBox.shrink();
    final c = AuthController.to;
    return Obx(() {
      final msg = c.formError.value;
      if (msg == null || msg.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: paddingTop),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: AppStyling().myDecoration(
          radius: 12,
          color: kRedColor.withValues(alpha: .08),
          borderColor: kRedColor.withValues(alpha: .4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: kRedColor),
            Expanded(
              child: MyText(
                paddingLeft: 8,
                text: msg,
                size: 13,
                weight: FontWeight.w500,
                color: kRedColor,
                maxLines: 4,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ignore: must_be_immutable
class SocialBtn extends StatelessWidget {
  SocialBtn({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
  });
  String icon;
  String title;
  VoidCallback onTap;
  Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      // width: 48,
      decoration: AppStyling().myDecoration(
        radius: 100,
        borderColor: kSecondaryColor,
        color: color,
        thickness: 1,
      ),
      child: MyRippleEffect(
        radius: 5,
        onTap: onTap,
        splashColor: kSecondaryColor.withValues(alpha: .5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CommonImageView(width: 24, imagePath: icon),

            MyText(
              paddingLeft: 10,
              // Was hardcoded "Continue With Apple", ignoring its own `title`.
              text: title,
              size: 16,
              weight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  String heading, title, title1, subTitle;
  final VoidCallback onTap;
  Header({
    super.key,
    required this.heading,
    required this.title,
    required this.title1,
    required this.subTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          paddingTop: 23,
          paddingBottom: 10,
          text: heading,
          size: 24,
          weight: FontWeight.w700,
          color: kSecondaryColor,
        ),
        MyText(text: title1, size: 16, weight: FontWeight.w400),

        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            MyText(text: title, size: 16, weight: FontWeight.w400),
            MyText(
              text: subTitle,
              size: 16,
              weight: FontWeight.w700,
              color: kSecondaryColor,
              onTap: onTap,
            ),
          ],
        ),
      ],
    );
  }
}

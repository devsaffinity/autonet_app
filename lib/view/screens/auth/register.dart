import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_role.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/auth_controller.dart';
import 'package:autonect/view/screens/auth/login.dart';
import 'package:autonect/view/screens/auth/verify_otp.dart';
import 'package:autonect/view/widget/animation_widget.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_checkbox.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Sign-up, step two: the account details, for the role picked one screen back.
///
/// [role] is REQUIRED and arrives as an argument, never read from shared state:
/// the account does not exist yet, so the only role there is is the one the
/// user just chose on the screen underneath this one. Back returns to that
/// picker with the choice still selected, so changing it is one tap.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.role});

  final AppRole role;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool isSelected = false;
  bool isObSecure1 = false;

  late final AuthController c;

  @override
  void initState() {
    super.initState();
    c = AuthController.ensure();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;

    final outcome = await c.signup(
      email: _email.text,
      password: _password.text,
      name: _name.text,
      // The ONE place a locally picked role is legitimately authoritative: the
      // account does not exist yet, so there is no server role to defer to.
      // From here on the token payload's role wins.
      role: widget.role,
      form: _form,
    );
    if (!mounted || outcome != AuthOutcome.success) return;

    // Signup returns NO TOKENS — the account is left PENDING_VERIFICATION and
    // the server emails a 6-digit OTP. So this goes to the OTP screen, never to
    // a home shell, and AccountCreatedBSheet moves to after verification.
    Get.to(() => VerifyOtpPage(email: c.pendingEmail.value));
  }

  /// "Already have an account? Log In" — straight back to Login, past the role
  /// picker, which has nothing to offer someone who is not signing up.
  ///
  /// Pops to the Login route when it is underneath, which it is on every real
  /// path here. If it is not, the stack is replaced with Login rather than
  /// popped to an empty navigator.
  void _backToLogin() {
    var found = false;
    Get.until((route) {
      if (route.settings.name == AppLinks.login) {
        found = true;
        return true;
      }
      return route.isFirst;
    });
    if (!found) Get.offAllNamed(AppLinks.login);
  }

  @override
  Widget build(BuildContext context) {
    // Every way OFF this form backwards — the arrow, the system back gesture,
    // "Log In" — clears the auth errors it may have raised. The controller is
    // shared, so otherwise "An account with this email already exists" is
    // still sitting on Login when the user gets there.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) c.clearErrors();
      },
      child: _page(),
    );
  }

  Widget _page() {
    return Scaffold(
      body: FadeSlideTransition(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSizes.DEFAULT,
            child: Form(
              key: _form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back to the role picker, with the current role still
                  // selected there.
                  const MyBackButton(),

                  Header(
                    heading: "Create an Account",
                    title1: "Log in to continue your journey",
                    title: "Already have an account? ",
                    subTitle: "Log In",
                    onTap: _backToLogin,
                  ),

                  SizedBox(height: 40),

                  Obx(
                    () => MyTextField(
                      controller: _name,
                      labelText: "Name",
                      isRequired: true,
                      hintText: "e.g John",
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      errorText: c.fieldErrorFor('name'),
                      validator: (v) =>
                          c.fieldErrorFor('name') ?? validateName(v),
                      onChanged: (_) => c.clearFieldError('name'),
                    ),
                  ),
                  Obx(
                    () => MyTextField(
                      controller: _email,
                      labelText: "Email Address",
                      isRequired: true,
                      hintText: "example@domain.com",
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      errorText: c.fieldErrorFor('email'),
                      validator: (v) =>
                          c.fieldErrorFor('email') ?? validateEmail(v),
                      onChanged: (_) => c.clearFieldError('email'),
                    ),
                  ),
                  Obx(
                    () => PasswordTextField(
                      controller: _password,
                      labelText: "Password",
                      isRequired: true,
                      isObSecure: isObSecure1,
                      errorText: c.fieldErrorFor('password'),
                      // Mirrors auth.dto.ts so the user is not round-tripped
                      // to the server to be told about a capital letter.
                      validator: (v) =>
                          c.fieldErrorFor('password') ??
                          validateStrongPassword(v),
                      onChanged: (_) => c.clearFieldError('password'),
                      onTap: () {
                        setState(() => isObSecure1 = !isObSecure1);
                      },
                    ),
                  ),
                  PasswordTextField(
                    controller: _confirm,
                    labelText: "Confirm Password",
                    isRequired: true,
                    hintText: "Re-enter your password",
                    isObSecure: isObSecure1,
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v != _password.text)
                        ? 'Passwords do not match'
                        : null,
                    onTap: () {
                      setState(() => isObSecure1 = !isObSecure1);
                    },
                  ),

                  SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MyCheckBox(
                        isChecked: isSelected,
                        onChanged: (value) {
                          isSelected = value!;
                          setState(() {});
                        },
                      ),
                      Expanded(
                        child: MyText(
                          paddingLeft: 10,
                          text: "I agree to the Terms and Conditions.",
                          size: 12,
                          weight: FontWeight.w400,
                          color: kGreyTextColor,
                          textOverflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const AuthFormError(),

                  Obx(
                    () => MyButton(
                      mTop: 30,
                      mBottom: 12,
                      // The T&C checkbox GATES the button, and busy re-gates it
                      // during the call: no blind retry against authRateLimit.
                      onTap: (!isSelected || c.busy.value) ? null : _submit,
                      backgroundColor: (!isSelected || c.busy.value)
                          ? kSecondaryColor.withValues(alpha: .5)
                          : kSecondaryColor,
                      buttonText: c.busy.value
                          ? "Creating account…"
                          : "Sign Up",
                    ),
                  ),

                  Align(
                    alignment: AlignmentGeometry.center,
                    child: MyText(
                      textAlign: TextAlign.center,
                      paddingBottom: 20,
                      paddingTop: 10,
                      text: "OR",
                      size: 14,
                      weight: FontWeight.w500,
                      color: kGreyTextColor,
                    ),
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
                          title: (index == 0)
                              ? "Continue With Google"
                              : "Continue With Apple",
                          onTap: () {},
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountCreatedBSheet extends StatelessWidget {
  final VoidCallback onContinue;
  const AccountCreatedBSheet({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return MyBSheet(
      btnText: "Proceed",
      onTap: onContinue,
      body: Column(
        children: [
          CommonImageView(
            width: 150,
            imagePath: Assets.imagesAccountCreatedIcon,
          ),

          MyText(
            textAlign: TextAlign.center,
            paddingBottom: 20,
            paddingTop: 24,
            text: "Account Creation successful!",
            size: 20,
            weight: FontWeight.w700,
          ),

          MyText(
            paddingBottom: 24,
            textAlign: TextAlign.center,
            text: "Congratulations, your account has been successfully created",
            size: 16,
            weight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}

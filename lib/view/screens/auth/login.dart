import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/screens/auth/forget.dart';
import 'package:autonect/view/screens/auth/register.dart';
import 'package:autonect/view/screens/electrician/nav_bar/nav_bar.dart';
import 'package:autonect/view/widget/animation_widget.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_checkbox.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isSelected = false;
  bool isObSecure = false;
  RoleController roleController = Get.find<RoleController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeSlideTransition(
          child: SingleChildScrollView(
            padding: AppSizes.DEFAULT,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(
                  heading: "Log In",
                  title1: "Log in to continue your journey.",
                  title: "Don’t have an account? ",
                  subTitle: "Sign Up",
                  onTap: () {
                    Get.to(
                      () => RegisterPage(),
                      transition: Transition.rightToLeft,
                    );
                  },
                ),

                SizedBox(height: 40),

                MyTextField(
                  labelText: "Email Address",
                  hintText: "example@domain.com",
                ),
                PasswordTextField(
                  labelText: "Password",
                  isObSecure: isObSecure,
                  onTap: () {
                    if (isObSecure == true) {
                      isObSecure = false;
                    } else {
                      isObSecure = true;
                    }
                    setState(() {});
                  },
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsetsGeometry.only(left: 20, right: 20, bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyButton(
              mBottom: 12,
              onTap: () {
                // roleController.role.value == 0
                //     ? Get.offAll(() => ServicesNavBar())
                //     : Get.offAll(() => ContractorNavBar());
                Get.offAll(() => ElectricianNavBar());
              },
              buttonText: "Sign In",
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
                    title: (index == 0)
                        ? "Continue With Apple"
                        : "Continue With Gmail",
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
              text: "Continue With Apple",
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

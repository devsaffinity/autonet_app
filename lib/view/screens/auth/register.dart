import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/auth/login.dart';
import 'package:autonect/view/widget/animation_widget.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_checkbox.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/state_manager.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isSelected = false;
  bool isObSecure1 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeSlideTransition(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSizes.DEFAULT,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(
                  heading: "Create an Account",
                  title1: "Log in to continue your journey",
                  title: "Already have an account? ",
                  subTitle: "Log In",
                  onTap: () {
                    Get.back();
                  },
                ),

                SizedBox(height: 40),

                MyTextField(
                  labelText: "Name",
                  hintText: "e.g John",
                  keyboardType: TextInputType.name,
                ),
                MyTextField(
                  labelText: "Email Address",
                  hintText: "example@domain.com",
                  keyboardType: TextInputType.emailAddress,
                ),
                // MyPhoneField(
                //   marginBottom: 0,
                //   labelText: "Phone Number",
                //   hintText: "Phone Number",
                //   onChanged: (phone) {
                //     // authCTRL.phoneCode = phone.countryCode;
                //     // authCTRL.phoneNumber = phone.number;

                //     // log("Country Code: ${authCTRL.phoneCode}");
                //     // log("Number: ${authCTRL.phoneNumber}");
                //   },
                // ),
                PasswordTextField(
                  labelText: "Password",
                  isObSecure: isObSecure1,
                  onTap: () {
                    if (isObSecure1 == true) {
                      isObSecure1 = false;
                    } else {
                      isObSecure1 = true;
                    }
                    setState(() {});
                  },
                ),
                PasswordTextField(
                  labelText: "Confirm Password",
                  isObSecure: isObSecure1,
                  onTap: () {
                    if (isObSecure1 == true) {
                      isObSecure1 = false;
                    } else {
                      isObSecure1 = true;
                    }
                    setState(() {});
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

                MyButton(
                  mTop: 30,
                  mBottom: 12,
                  onTap: () {
                    // roleController.role.value == 0
                    //     ? Get.offAll(() => ServicesNavBar())
                    //     : Get.offAll(() => ContractorNavBar());
                    Get.bottomSheet(
                      AccountCreatedBSheet(),
                      isScrollControlled: true,
                    );
                  },
                  buttonText: "Sign In",
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
                            ? "Continue With Apple"
                            : "Continue With Gmail",
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
    );
  }
}

class AccountCreatedBSheet extends StatelessWidget {
  const AccountCreatedBSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return MyBSheet(
      btnText: "Proceed",
      onTap: () {},
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

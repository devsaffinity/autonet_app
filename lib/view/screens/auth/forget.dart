import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/auth/login.dart';
import 'package:autonect/view/widget/animation_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:flutter/material.dart';

class ForgetPage extends StatefulWidget {
  @override
  State<ForgetPage> createState() => _ForgetPageState();
}

class _ForgetPageState extends State<ForgetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeSlideTransition(
          child: SingleChildScrollView(
            padding: AppSizes.DEFAULT,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Header(
                  heading: "Forgot your Password?",
                  title1:
                      "Enter your email address and we will send an OTP to create a new password.",
                  title: " ",
                  subTitle: "",
                  onTap: () {},
                ),

                SizedBox(height: 20),

                MyTextField(
                  labelText: "Email Address",
                  hintText: "example@domain.com",
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavButton(buttonText: "Continue", onTap: () {}),
    );
  }
}

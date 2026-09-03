// method to show the loading dialog

import 'package:autonect/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';

void showLoadingDialog() {
  Get.dialog(
    // Center(child: CircularProgressIndicator()),
    Center(
      child: LoadingAnimationWidget.discreteCircle(
        color: kSecondaryColor,
        size: 60,
      ),
    ),
    barrierDismissible: false,
  );
}

void showVideoGenerationLoadingDialog({String? title}) {
  Get.dialog(
    Dialog(
      backgroundColor: kPrimaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loader at top
            LoadingAnimationWidget.discreteCircle(
              color: kSecondaryColor,
              size: 60,
            ),

            SizedBox(height: 24),

            // Message at bottom
            Text(
              title ?? 'Please wait, video is generating\nDo not skip',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kBlackColor,
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

// method to hide the loading dialog
void hideLoadingDialog() {
  if (Get.isDialogOpen == true) {
    Get.close(1);
  }
  // Navigator.pop(context);
}

// -------------- Validation -------------------

String? validateName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Name cannot be empty';
  }
  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
    return 'Name can only contain alphabetic characters';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email cannot be empty';
  }
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePhoneNumber(String? value) {
  if (value == null || value.isEmpty) {
    return 'Phone number cannot be empty';
  }
  if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
    return 'Enter a valid phone number (10-15 digits)';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password cannot be empty';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters long';
  }
  if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
    return 'Password must contain both letters and numbers';
  }
  return null;
}

displayToast({required String msg}) {
  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 1,
    backgroundColor: kPrimaryColor,
    textColor: Colors.white,
    fontSize: 14.0,
  );
}

// ------- Wave Loading Animation Widget ----------

class WaveLoading extends StatelessWidget {
  final double size;
  WaveLoading({super.key, this.size = 30});

  // ThemeController _ctrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.staggeredDotsWave(
      color: kPrimaryColor,
      size: size,
    );
  }
}

class DiscreteCircleLoading extends StatelessWidget {
  final double size;
  const DiscreteCircleLoading({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.discreteCircle(
      color: kSecondaryColor,
      size: size,
    );
  }
}

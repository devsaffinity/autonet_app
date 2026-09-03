// import 'package:flutter/material.dart';
// import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
// import 'package:love_stories/constants/app_colors.dart';
// import 'package:love_stories/constants/app_fonts.dart';

// class OtpFields extends StatelessWidget {
//   final Function(dynamic)? onCodeChanged;

//   const OtpFields({super.key, required this.onCodeChanged});

//   @override
//   Widget build(BuildContext context) {
//     return OtpTextField(
//       margin: EdgeInsets.only(right: 16),
//       numberOfFields: 4,
//       filled: false,
//       fillColor: kTertiaryColor,
//       borderColor: kSecondaryColor,
//       enabledBorderColor: kGreyColor1.withOpacity(0.3),
//       focusedBorderColor: kGradientBorder,
//       borderWidth: 2,
//       borderRadius: BorderRadius.circular(10),
//       showFieldAsBox: true,
//       fieldWidth: 50,
//       textStyle: TextStyle(
//           fontSize: 22,
//           fontWeight: FontWeight.w500,
//           color: kTertiaryColor,
//           fontFamily: AppFonts.Poppins),
//       onCodeChanged: onCodeChanged,
//     );
//   }
// }



// 
// intl_phone_field: ^3.2.0
//   flutter_otp_text_field: ^1.1.1
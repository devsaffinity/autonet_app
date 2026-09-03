import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fonts.dart';

final ThemeData lightTheme = ThemeData(
  scaffoldBackgroundColor: kPrimaryColor,
  fontFamily: AppFonts.Cairo,
  appBarTheme: AppBarTheme(elevation: 0, backgroundColor: kPrimaryColor),
  splashColor: kPrimaryColor.withOpacity(0.10),
  highlightColor: kPrimaryColor.withOpacity(0.10),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: kSecondaryColor.withOpacity(0.1),
  ),
  textSelectionTheme: TextSelectionThemeData(cursorColor: kBlackColor),
);

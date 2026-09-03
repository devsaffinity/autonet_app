import 'package:autonect/constants/app_colors.dart';
import 'package:flutter/material.dart';

class MyFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  const MyFloatingButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kSecondaryColor, kSecondaryColor],
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: kGreyTextColor.withValues(alpha: .5),
            blurRadius: 5,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(),
        child: InkWell(
          splashColor: kBlueColor.withValues(alpha: .5),
          customBorder: CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

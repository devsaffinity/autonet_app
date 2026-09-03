import 'dart:io';
import 'package:flutter/material.dart';

class IOSBottomPadding extends StatelessWidget {
  const IOSBottomPadding({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [if (Platform.isIOS) SizedBox(height: 25)]);
  }
}

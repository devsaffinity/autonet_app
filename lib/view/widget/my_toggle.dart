// import 'package:flutter/material.dart';
// import 'package:little_smarty/constants/app_colors.dart';
// import 'package:little_smarty/view/widget/my_text_widget.dart';

// class MyToggle extends StatefulWidget {
//   final String label;
//   final String? subTitle;
//   final bool initialValue;
//   final ValueChanged<bool>? onChanged;

//   const MyToggle({
//     super.key,
//     this.label = 'Remember',
//     this.subTitle,
//     this.initialValue = false,
//     this.onChanged,
//   });

//   @override
//   State<MyToggle> createState() => _MyToggleState();
// }

// class _MyToggleState extends State<MyToggle>
//     with SingleTickerProviderStateMixin {
//   late bool _isOn;
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _isOn = widget.initialValue;
//     _controller = AnimationController(
//       duration: Duration(milliseconds: 250),
//       vsync: this,
//       value: _isOn ? 1.0 : 0.0,
//     );
//     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _toggle() {
//     setState(() => _isOn = !_isOn);
//     _isOn ? _controller.forward() : _controller.reverse();
//     widget.onChanged?.call(_isOn);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _toggle,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Toggle Track
//           AnimatedContainer(
//             duration: Duration(milliseconds: 250),
//             curve: Curves.easeInOut,
//             width: 52,
//             height: 30,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(50),
//               color: _isOn ? kTertiaryColor : Colors.grey.withValues(alpha: .3),
//             ),
//             child: Padding(
//               padding: EdgeInsets.all(3),
//               child: AnimatedBuilder(
//                 animation: _animation,
//                 builder: (context, child) {
//                   return Align(
//                     alignment: Alignment(
//                       // moves from -1 (left) to 1 (right)
//                       (_animation.value * 2) - 1,
//                       0,
//                     ),
//                     child: child,
//                   );
//                 },
//                 child: Container(
//                   width: 24,
//                   height: 24,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: .15),
//                         blurRadius: 4,
//                         offset: Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           SizedBox(width: 10),

//           // Label
//           MyText(text: widget.label, size: 15, weight: FontWeight.w600),
//           widget.subTitle != null
//               ? MyText(
//                   text: widget.subTitle!,
//                   size: 15,
//                   weight: FontWeight.w600,
//                   color: kTertiaryColor,
//                 )
//               : SizedBox.shrink(),
//         ],
//       ),
//     );
//   }
// }

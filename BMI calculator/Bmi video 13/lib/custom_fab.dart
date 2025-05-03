import 'package:flutter/material.dart';
import 'constant_file.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;

  CustomFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      child: Icon(
        Icons.favorite,
        color: Colors.white,
        size: 30.0,
      ),
      elevation: 6.0,
      constraints: BoxConstraints.tightFor(
        width: 56.0,
        height: 56.0,
      ),
      shape: CircleBorder(),
      fillColor: kFabColor,
      onPressed: onPressed,
    );
  }
}
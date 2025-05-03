import 'package:flutter/material.dart';
import 'constant_file.dart';

class RepeatTextandICONewidget extends StatelessWidget {
  RepeatTextandICONewidget({this.iconData, required this.label});

  final IconData? iconData; // Made optional
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (iconData != null) ...[
          Icon(
            iconData,
            size: 85.0,
          ),
          SizedBox(height: 15.0),
        ],
        Text(
          label,
          style: kLabelStyle, // Use the constant style
        ),
      ],
    );
  }
}
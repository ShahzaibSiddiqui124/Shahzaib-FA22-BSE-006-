import 'package:flutter/material.dart';
import 'constant_file.dart';

class IncrementDecrementWidget extends StatelessWidget {
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  IncrementDecrementWidget({
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        RoundIconButton(
          icon: Icons.remove,
          onPressed: onDecrement,
        ),
        SizedBox(width: 10.0),
        RoundIconButton(
          icon: Icons.add,
          onPressed: onIncrement,
        ),
      ],
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      child: Icon(icon),
      elevation: 0.0,
      constraints: BoxConstraints.tightFor(
        width: 56.0,
        height: 56.0,
      ),
      shape: CircleBorder(),
      fillColor: Color(0xFF4C4F5E),
      onPressed: onPressed,
    );
  }
}
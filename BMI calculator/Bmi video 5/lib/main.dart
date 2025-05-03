import 'package:flutter/material.dart';
import 'bmi_widgets.dart'; // Import the second file

void main() {
  runApp(const BMICalculatorApp());
}

class BMICalculatorApp extends StatelessWidget {
  const BMICalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const BMICalculatorHome(),
    );
  }
}

class BMICalculatorHome extends StatelessWidget {
  const BMICalculatorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI CALCULATOR'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: const [
            GenderCard(icon: Icons.male, label: 'MALE'),
            GenderCard(icon: Icons.female, label: 'FeMALE'),
            BMICard(),
            BMICard(),
            BMICard(),
            BMICard(),
          ],
        ),
      ),
    );
  }
}

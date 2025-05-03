import 'package:flutter/material.dart';
import 'gender_card.dart'; // Import custom widget

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

enum Gender { male, female }

class BMICalculatorHome extends StatefulWidget {
  const BMICalculatorHome({super.key});

  @override
  State<BMICalculatorHome> createState() => _BMICalculatorHomeState();
}

class _BMICalculatorHomeState extends State<BMICalculatorHome> {
  Gender? selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BMI CALCULATOR')),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedGender = Gender.male;
                });
              },
              child: GenderCard(
                icon: Icons.male,
                label: 'MALE',
                isSelected: selectedGender == Gender.male,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedGender = Gender.female;
                });
              },
              child: GenderCard(
                icon: Icons.female,
                label: 'FeMALE',
                isSelected: selectedGender == Gender.female,
              ),
            ),
            const BMICard(),
            const BMICard(),
            const BMICard(),
            const BMICard(),
          ],
        ),
      ),
    );
  }
}

class BMICard extends StatelessWidget {
  const BMICard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

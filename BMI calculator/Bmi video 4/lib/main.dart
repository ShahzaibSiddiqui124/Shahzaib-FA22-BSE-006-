import 'package:flutter/material.dart';

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
            BMICard(), // 4 empty cards as placeholders
            BMICard(),
            BMICard(),
            BMICard(),
          ],
        ),
      ),
    );
  }
}

class GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const GenderCard({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80),
          const SizedBox(height: 15),
          Text(
            label,
            style: const TextStyle(fontSize: 18),
          ),
        ],
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

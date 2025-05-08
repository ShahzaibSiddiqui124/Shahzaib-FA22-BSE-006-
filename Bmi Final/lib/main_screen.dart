import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String selectedGender = 'Male';
  double height = 170;
  double weight = 70;
  double bmi = 0;
  String bmiStatus = '';

  void calculateBMI() {
    setState(() {
      bmi = weight / ((height / 100) * (height / 100));
      if (bmi < 18.5) {
        bmiStatus = 'Underweight';
      } else if (bmi >= 18.5 && bmi < 25) {
        bmiStatus = 'Normal';
      } else if (bmi >= 25 && bmi < 30) {
        bmiStatus = 'Overweight';
      } else {
        bmiStatus = 'Obese';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BMI Calculator',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[100]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Gender Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GenderCard(
                    icon: FontAwesomeIcons.mars,
                    label: 'Male',
                    isSelected: selectedGender == 'Male',
                    onTap: () {
                      setState(() {
                        selectedGender = 'Male';
                      });
                    },
                  ),
                  GenderCard(
                    icon: FontAwesomeIcons.venus,
                    label: 'Female',
                    isSelected: selectedGender == 'Female',
                    onTap: () {
                      setState(() {
                        selectedGender = 'Female';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Height Slider
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          FaIcon(
                            FontAwesomeIcons.rulerVertical,
                            color: Color(0xFF6A1B9A),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Height (cm)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: height,
                        min: 100,
                        max: 250,
                        divisions: 150,
                        activeColor: const Color(0xFF6A1B9A),
                        inactiveColor: Colors.grey[300],
                        label: height.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            height = value;
                          });
                        },
                      ),
                      Text(
                        '${height.round()} cm',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Weight Slider
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          FaIcon(
                            FontAwesomeIcons.weightScale,
                            color: Color(0xFF6A1B9A),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Weight (kg)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: weight,
                        min: 30,
                        max: 150,
                        divisions: 120,
                        activeColor: const Color(0xFF6A1B9A),
                        inactiveColor: Colors.grey[300],
                        label: weight.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            weight = value;
                          });
                        },
                      ),
                      Text(
                        '${weight.round()} kg',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Calculate Button
              ElevatedButton(
                onPressed: calculateBMI,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Calculate BMI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Result Display
              if (bmi > 0)
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Your BMI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        Text(
                          bmi.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                            fontFamily: 'Roboto',
                          ),
                        ),
                        Text(
                          bmiStatus,
                          style: TextStyle(
                            fontSize: 18,
                            color: bmiStatus == 'Normal'
                                ? Colors.green
                                : Colors.red,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20), // Extra padding at the bottom
            ],
          ),
        ),
      ),
    );
  }
}

class GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GenderCard({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 8 : 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: isSelected ? const Color(0xFF6A1B9A) : Colors.white,
        child: Container(
          width: 150,
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 40,
                color: isSelected ? Colors.white : const Color(0xFF6A1B9A),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF6A1B9A),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
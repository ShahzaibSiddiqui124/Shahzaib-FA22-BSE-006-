import 'package:flutter/material.dart';

void main() {
  runApp(BMICalculatorApp());
}

class BMICalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Dark theme
      home: Scaffold(
        appBar: AppBar(
          title: Text('BMI CALCULATOR'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GridView.count(
            crossAxisCount: 2, // 2 columns
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: List.generate(6, (index) {
              return Card(
                color: Colors.grey[850], // dark card color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

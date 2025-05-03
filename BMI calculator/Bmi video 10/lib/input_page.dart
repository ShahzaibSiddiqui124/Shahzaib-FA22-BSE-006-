import 'package:flutter/material.dart';
import 'container_file.dart';
import 'icon_text_file.dart';

// Define the Gender enum
enum Gender {
  male,
  female,
}

class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  Gender? selectedGender; // Track the selected gender
  Color activeColor = Colors.blue; // Active color
  Color deActiveColor = Colors.grey; // Inactive color

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BMI CALCULATOR'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: RepeatContainerCode(
                    onPressed: () {
                      setState(() {
                        selectedGender = Gender.male;
                      });
                      print('Click! Male');
                    },
                    colors: selectedGender == Gender.male ? activeColor : deActiveColor,
                    cardWidget: RepeatTextandICONewidget(
                      iconData: Icons.male,
                      label: 'MALE',
                    ),
                  ),
                ),
                Expanded(
                  child: RepeatContainerCode(
                    onPressed: () {
                      setState(() {
                        selectedGender = Gender.female;
                      });
                      print('Click! Female');
                    },
                    colors: selectedGender == Gender.female ? activeColor : deActiveColor,
                    cardWidget: RepeatTextandICONewidget(
                      iconData: Icons.female,
                      label: 'FEMALE',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RepeatContainerCode(
              colors: Colors.grey,
              cardWidget: RepeatTextandICONewidget(
                label: 'HEIGHT',
              ),
            ),
          ),
          Expanded(
            child: RepeatContainerCode(
              colors: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
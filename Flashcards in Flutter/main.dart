import 'package:flutter/material.dart';

void main() {
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FlashcardScreen(),
    );
  }
}

class FlashcardScreen extends StatelessWidget {
  final List<Map<String, String>> flashcards = [
    {'question': 'What is the capital of pakistan?', 'answer': 'Islamabad'},
    {'question': 'What is 18 + 2?', 'answer': '20'},
    {'question': 'Who is the instructor of MAD?', 'answer': 'Sir Abdullah'},
    {'question': "Where is city Vehari?", 'answer': 'Punjab'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen,
      appBar: AppBar(title: const Text('QnA')),
      body: ListView.builder(
        itemCount: flashcards.length,
        itemBuilder: (context, index) {
          return FlashcardWidget(
            question: flashcards[index]['question']!,
            answer: flashcards[index]['answer']!,
          );
        },
      ),
    );
  }
}

class FlashcardWidget extends StatefulWidget {
  final String question;
  final String answer;

  const FlashcardWidget({super.key, required this.question, required this.answer});

  @override
  _FlashcardWidgetState createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  bool showAnswer = false;

  void toggleCard() {
    setState(() {
      showAnswer = !showAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleCard,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            showAnswer ? widget.answer : widget.question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

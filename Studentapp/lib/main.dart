import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'student_dashboard.dart';
import 'assignments_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: 'https://fyiashlxnnlquzzpkolq.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5aWFzaGx4bm5scXV6enBrb2xxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1NjYyMTQsImV4cCI6MjA2MzE0MjIxNH0.fTw10TQUxy56BmdsqCDGNnSsWpWoulUM2FHS_27sesc',
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }
  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      home: const LoginPage(),
      routes: {
        '/dashboard': (context) => const StudentDashboard(),
        '/assignments': (context) => const AssignmentsPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'welcome_page.dart';
import 'login_page.dart';
import 'student_dashboard.dart';
import 'advisor_dashboard.dart';
import 'hod_dashboard.dart';
import 'admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qsaixjnkbwlvvubqbnqj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFzYWl4am5rYndsdnZ1YnFibnFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxNDY5NjYsImV4cCI6MjA2NTcyMjk2Nn0.4nnKMh0LfNP4_frsw11Ib12Fp3PFOFx2GP4TnJGPrCc',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Complaint System',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[850],
        appBarTheme: const AppBarTheme(backgroundColor: Colors.teal),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/student': (context) => const StudentDashboard(),
        '/advisor': (context) => const AdvisorDashboard(),
        '/hod': (context) => const HodDashboard(),
        '/admin': (context) => const AdminDashboard(),
      },
    );
  }
}
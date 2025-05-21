import 'package:flutter/material.dart';
import 'supabase_config.dart';
import 'welcome_page.dart';
import 'admin_dashboard.dart';
import 'assignments_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Admin Portal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            letterSpacing: 0, // Ensure no extra spacing between characters
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            letterSpacing: 0,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
          ),
        ).apply(
          fontFamily: 'Roboto', // Fallback to ensure all text uses Roboto
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const WelcomePage(),
      routes: {
        '/dashboard': (context) => const AdminDashboard(),
        '/assignments': (context) => const AssignmentsPage(),
      },
    );
  }
}
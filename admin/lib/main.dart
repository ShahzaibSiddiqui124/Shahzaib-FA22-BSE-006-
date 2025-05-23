import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'welcome_page.dart';
import 'dashboard.dart';
import 'student_list.dart';
import 'notifications_page.dart';
import 'SubmissionsPage.dart';
import 'reports_page.dart';
import 'assignment_list.dart';
import 'upload_assignment.dart';
import 'marks_management.dart';
import 'student_management.dart';
import 'AttendanceManagement.dart'; // New module

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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const WelcomePage(),
      routes: {
        '/dashboard': (_) => Dashboard(),
        '/students': (_) => StudentList(),
        '/notifications': (_) => NotificationsPage(),
        '/submissions': (_) => SubmissionsPage(),
        '/reports': (_) => ReportsPage(),
        '/assignments': (_) => AssignmentList(),
        '/upload-assignment': (_) => UploadAssignment(),
        '/marks-management': (_) => MarksManagement(),
        '/student-management': (_) => StudentManagement(),
        '/attendance-management': (_) => AttendanceManagement(), // New route
      },
    );
  }
}
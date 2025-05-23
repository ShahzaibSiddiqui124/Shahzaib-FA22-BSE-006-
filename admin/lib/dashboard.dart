import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int studentCount = 0;
  int notificationCount = 0;
  int submissionCount = 0;

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    try {
      final client = Supabase.instance.client;
      final studentRes = await client.from('students').select();
      final notifRes = await client.from('notifications').select();
      final subRes = await client.from('student_submissions').select(); // Correct table name
      debugPrint('Student Response: $studentRes');
      debugPrint('Notification Response: $notifRes');
      debugPrint('Submission Response: $subRes');
      setState(() {
        studentCount = studentRes.length;
        notificationCount = notifRes.length;
        submissionCount = subRes.length;
      });
    } catch (e) {
      debugPrint('Error fetching summary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching summary: $e')),
      );
    }
  }

  Widget buildTile(String title, int count, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$count', style: TextStyle(fontSize: 24, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchSummary,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Admin Portal',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Students'),
              onTap: () => Navigator.pushNamed(context, '/students'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () => Navigator.pushNamed(context, '/notifications'),
            ),
            ListTile(
              leading: const Icon(Icons.mail),
              title: const Text('Submissions'),
              onTap: () => Navigator.pushNamed(context, '/submissions'),
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Reports'),
              onTap: () => Navigator.pushNamed(context, '/reports'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Assignments'),
              onTap: () => Navigator.pushNamed(context, '/assignments'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload Assignment'),
              onTap: () => Navigator.pushNamed(context, '/upload-assignment'),
            ),
            ListTile(
              leading: const Icon(Icons.grade),
              title: const Text('Marks Management'),
              onTap: () => Navigator.pushNamed(context, '/marks-management'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Student Management'),
              onTap: () => Navigator.pushNamed(context, '/student-management'),
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Attendance Management'),
              onTap: () => Navigator.pushNamed(context, '/attendance-management'),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTile('Total Students', studentCount, Icons.group, Colors.deepPurple, '/students'),
            buildTile('Notifications', notificationCount, Icons.notifications, Colors.blue, '/notifications'),
            buildTile('Submissions', submissionCount, Icons.mail, Colors.green, '/submissions'),
          ],
        ),
      ),
    );
  }
}
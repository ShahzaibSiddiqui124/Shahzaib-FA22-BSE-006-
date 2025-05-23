import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Map<String, dynamic>? student;
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> marks = [];
  bool _isLoading = false;

  Future<void> fetchStudentData() async {
    setState(() => _isLoading = true);
    try {
      final studentId = student!['id'].toString();

      // Fetch attendance
      final attendanceResponse = await Supabase.instance.client
          .from('attendance')
          .select()
          .eq('student_id', studentId);

      // Fetch marks
      final marksResponse = await Supabase.instance.client
          .from('marks')
          .select()
          .eq('student_id', studentId);

      setState(() {
        attendance = List<Map<String, dynamic>>.from(attendanceResponse);
        marks = List<Map<String, dynamic>>.from(marksResponse);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double getAttendancePercentage() {
    final totalDays = attendance.length;
    final presentDays = attendance.where((record) => record['status'] == 'Present').length;
    return totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    student = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    fetchStudentData();
  }

  @override
  Widget build(BuildContext context) {
    final attendancePercentage = getAttendancePercentage();

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${student?['name'] ?? 'Student'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchStudentData,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                'Student Portal',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Assignments'),
              onTap: () => Navigator.pushNamed(context, '/assignments', arguments: student),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () => Navigator.pushNamed(context, '/notifications', arguments: student),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Navigator.pushNamed(context, '/profile', arguments: student),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => Navigator.pushReplacementNamed(context, '/'),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Overview',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance: ${attendancePercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 18,
                                color: attendancePercentage >= 75 ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              'Total Days: ${attendance.length}',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: attendancePercentage >= 75
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          child: Text(
                            '${attendancePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: attendancePercentage >= 75 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Attendance History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    attendance.isEmpty
                        ? const Text('No attendance records available.')
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: attendance.length,
                      itemBuilder: (context, index) {
                        final record = attendance[index];
                        return ListTile(
                          title: Text('Date: ${record['date']}'),
                          trailing: Icon(
                            record['status'] == 'Present'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: record['status'] == 'Present'
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.purple[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Marks Overview',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    marks.isEmpty
                        ? const Text('No marks available.')
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: marks.length,
                      itemBuilder: (context, index) {
                        final mark = marks[index];
                        return ListTile(
                          title: Text('Course: ${mark['course']}'),
                          subtitle: Text('Marks: ${mark['marks']}'),
                          trailing: CircleAvatar(
                            backgroundColor: (mark['marks'] as int) >= 50
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            child: Text(
                              '${mark['marks']}',
                              style: TextStyle(
                                color: (mark['marks'] as int) >= 50
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
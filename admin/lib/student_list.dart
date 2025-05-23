import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentList extends StatefulWidget {
  const StudentList({super.key});

  @override
  _StudentListState createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  List<Map<String, dynamic>> students = [];
  bool _isLoading = false;

  Future<void> fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.from('students').select();
      final studentList = List<Map<String, dynamic>>.from(response);

      // Fetch attendance for each student
      for (var student in studentList) {
        final studentId = student['id'].toString();
        final attendanceResponse = await Supabase.instance.client
            .from('attendance')
            .select()
            .eq('student_id', studentId);

        // Calculate attendance percentage
        final totalDays = attendanceResponse.length;
        final presentDays = attendanceResponse
            .where((record) => record['status'] == 'Present')
            .length;
        final percentage = totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;

        student['attendance'] = attendanceResponse;
        student['attendancePercentage'] = percentage;
      }

      setState(() => students = studentList);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchStudents,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : students.isEmpty
            ? const Center(child: Text('No students available'))
            : RefreshIndicator(
          onRefresh: fetchStudents,
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final attendancePercentage = student['attendancePercentage'] ?? 0.0;
              final attendanceRecords = student['attendance'] ?? [];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: attendancePercentage >= 75
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    child: Text(
                      '${attendancePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: attendancePercentage >= 75
                            ? Colors.green
                            : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    student['name'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Email: ${student['email'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  children: [
                    if (attendanceRecords.isNotEmpty)
                      ...attendanceRecords.map<Widget>((record) {
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
                      }).toList()
                    else
                      const ListTile(
                        title: Text('No attendance records available.'),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
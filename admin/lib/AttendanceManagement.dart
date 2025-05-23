import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceManagement extends StatefulWidget {
  const AttendanceManagement({super.key});

  @override
  _AttendanceManagementState createState() => _AttendanceManagementState();
}

class _AttendanceManagementState extends State<AttendanceManagement> {
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {};
  bool _isLoading = false;
  DateTime selectedDate = DateTime(2025, 5, 23); // Current date based on system prompt

  Future<void> fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.from('students').select();
      final studentList = List<Map<String, dynamic>>.from(response);

      // Fetch attendance for the selected date
      final attendanceResponse = await Supabase.instance.client
          .from('attendance')
          .select()
          .eq('date', selectedDate.toIso8601String().split('T')[0]);

      // Initialize attendance status
      final Map<String, String> tempStatus = {};
      for (var student in studentList) {
        final studentId = student['id'].toString();
        final existingAttendance = attendanceResponse.firstWhere(
              (record) => record['student_id'].toString() == studentId,
          orElse: () => {'status': 'Absent'},
        );
        tempStatus[studentId] = existingAttendance['status'];
      }

      setState(() {
        students = studentList;
        attendanceStatus = tempStatus;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> saveAttendance() async {
    setState(() => _isLoading = true);
    try {
      for (var student in students) {
        final studentId = student['id'].toString();
        final status = attendanceStatus[studentId] ?? 'Absent';

        final existingAttendance = await Supabase.instance.client
            .from('attendance')
            .select()
            .eq('student_id', studentId)
            .eq('date', selectedDate.toIso8601String().split('T')[0]);

        if (existingAttendance.isNotEmpty) {
          // Update existing record
          await Supabase.instance.client
              .from('attendance')
              .update({'status': status})
              .eq('student_id', studentId)
              .eq('date', selectedDate.toIso8601String().split('T')[0]);
        } else {
          // Insert new record
          await Supabase.instance.client.from('attendance').insert({
            'student_id': studentId,
            'date': selectedDate.toIso8601String().split('T')[0],
            'status': status,
          });
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving attendance: $e')),
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
        title: const Text('Attendance Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchStudents,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Date: ${selectedDate.toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                      fetchStudents();
                    }
                  },
                  child: const Text('Change Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : students.isEmpty
                  ? const Center(child: Text('No students available'))
                  : ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final studentId = student['id'].toString();
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(student['name'] ?? 'No Name'),
                      subtitle: Text('Email: ${student['email'] ?? 'N/A'}'),
                      trailing: ToggleButtons(
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: attendanceStatus[studentId] == 'Present'
                            ? Colors.green
                            : Colors.red,
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Present'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Absent'),
                          ),
                        ],
                        isSelected: [
                          attendanceStatus[studentId] == 'Present',
                          attendanceStatus[studentId] == 'Absent',
                        ],
                        onPressed: (int index) {
                          setState(() {
                            attendanceStatus[studentId] = index == 0 ? 'Present' : 'Absent';
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : saveAttendance,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}
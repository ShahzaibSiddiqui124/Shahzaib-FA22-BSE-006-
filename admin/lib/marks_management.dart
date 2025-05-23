import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarksManagement extends StatefulWidget {
  const MarksManagement({super.key});

  @override
  _MarksManagementState createState() => _MarksManagementState();
}

class _MarksManagementState extends State<MarksManagement> {
  List<Map<String, dynamic>> students = [];
  bool _isLoading = false;

  Future<void> fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.from('students').select();
      setState(() {
        students = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> addMarks(String studentId, String course, int marks) async {
    try {
      await Supabase.instance.client.from('marks').insert({
        'student_id': studentId,
        'course': course,
        'marks': marks,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks added successfully')),
      );
      // Refresh the page after adding marks
      fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding marks: $e')),
      );
    }
  }

  Future<void> editMarks(String studentId, String course, int newMarks) async {
    try {
      final existingMarks = await Supabase.instance.client
          .from('marks')
          .select()
          .eq('student_id', studentId)
          .eq('course', course);

      if (existingMarks.isNotEmpty) {
        await Supabase.instance.client
            .from('marks')
            .update({'marks': newMarks})
            .eq('student_id', studentId)
            .eq('course', course);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No marks found for this course. Please add marks first.')),
        );
      }
      // Refresh the page after editing marks
      fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating marks: $e')),
      );
    }
  }

  Future<void> deleteMarks(String studentId, String course) async {
    try {
      await Supabase.instance.client
          .from('marks')
          .delete()
          .eq('student_id', studentId)
          .eq('course', course);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks deleted successfully')),
      );
      // Refresh the page after deleting marks
      fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting marks: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchStudentMarks(String studentId) async {
    try {
      final response = await Supabase.instance.client
          .from('marks')
          .select()
          .eq('student_id', studentId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching marks: $e')),
      );
      return [];
    }
  }

  void showMarksDialog(String studentId, String studentName) {
    final _courseController = TextEditingController();
    final _marksController = TextEditingController();
    bool _dialogLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Manage Marks for $studentName'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _courseController,
                      decoration: const InputDecoration(labelText: 'Course'),
                    ),
                    TextField(
                      controller: _marksController,
                      decoration: const InputDecoration(labelText: 'Marks'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder(
                      future: fetchStudentMarks(studentId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        final marks = snapshot.data as List<Map<String, dynamic>>;
                        if (marks.isEmpty) {
                          return const Text('No marks available for this student.');
                        }
                        return Column(
                          children: marks.map((mark) {
                            return ListTile(
                              title: Text('Course: ${mark['course']}'),
                              subtitle: Text('Marks: ${mark['marks']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  deleteMarks(studentId, mark['course']);
                                  Navigator.pop(context); // Close dialog after deletion
                                  setState(() {}); // Refresh the parent page
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: _dialogLoading
                      ? null
                      : () async {
                    if (_courseController.text.isEmpty || _marksController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    setDialogState(() => _dialogLoading = true);
                    await addMarks(
                      studentId,
                      _courseController.text,
                      int.parse(_marksController.text),
                    );
                    setDialogState(() => _dialogLoading = false);
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: _dialogLoading
                      ? const CircularProgressIndicator()
                      : const Text('Add Marks'),
                ),
                TextButton(
                  onPressed: _dialogLoading
                      ? null
                      : () async {
                    if (_courseController.text.isEmpty || _marksController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    setDialogState(() => _dialogLoading = true);
                    await editMarks(
                      studentId,
                      _courseController.text,
                      int.parse(_marksController.text),
                    );
                    setDialogState(() => _dialogLoading = false);
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: _dialogLoading
                      ? const CircularProgressIndicator()
                      : const Text('Edit Marks'),
                ),
              ],
            );
          },
        );
      },
    );
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
        title: const Text('Marks Management'),
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
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(student['name'] ?? 'No Name'),
                  subtitle: Text('Email: ${student['email'] ?? 'N/A'}'),
                  onTap: () => showMarksDialog(
                    student['id'].toString(),
                    student['name'] ?? 'No Name',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
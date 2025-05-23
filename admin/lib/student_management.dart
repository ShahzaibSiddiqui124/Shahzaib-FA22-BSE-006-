import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentManagement extends StatefulWidget {
  const StudentManagement({super.key});

  @override
  _StudentManagementState createState() => _StudentManagementState();
}

class _StudentManagementState extends State<StudentManagement> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  List<Map<String, dynamic>> students = [];
  bool _isLoading = false;

  Future<void> fetchStudents() async {
    try {
      final response = await Supabase.instance.client.from('students').select();
      for (var student in response) {
        final marksResponse = await Supabase.instance.client
            .from('marks')
            .select()
            .eq('student_id', student['id'].toString());
        student['marks'] = marksResponse; // Add marks to student data
      }
      setState(() => students = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students: $e')),
      );
    }
  }

  Future<void> addStudent() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _departmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('students').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'department': _departmentController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully')),
      );
      _nameController.clear();
      _emailController.clear();
      _departmentController.clear();
      fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding student: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> editStudent(String id, Map<String, dynamic> student) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('students')
          .update({
        'name': student['name'],
        'email': student['email'],
        'department': student['department'],
      })
          .eq('id', id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student updated successfully')),
      );
      fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating student: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteStudent(String id) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('students').delete().eq('id', id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully')),
      );
      fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting student: $e')),
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _departmentController,
              decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : addStudent,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add Student'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: students.isEmpty
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
                      child: ExpansionTile(
                        title: Text(student['name'] ?? 'No Name'),
                        subtitle: Text('Email: ${student['email'] ?? 'N/A'}, Dept: ${student['department'] ?? 'N/A'}'),
                        children: [
                          if (student['marks'] != null && (student['marks'] as List).isNotEmpty)
                            ...((student['marks'] as List).map((mark) {
                              return ListTile(
                                title: Text('Course: ${mark['course']}'),
                                subtitle: Text('Marks: ${mark['marks']}'),
                              );
                            }).toList())
                          else
                            const ListTile(
                              title: Text('No marks available for this student.'),
                            ),
                        ],
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final _editNameController = TextEditingController(text: student['name']);
                                    final _editEmailController = TextEditingController(text: student['email']);
                                    final _editDeptController = TextEditingController(text: student['department']);
                                    return AlertDialog(
                                      title: const Text('Edit Student'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: _editNameController,
                                            decoration: const InputDecoration(labelText: 'Name'),
                                          ),
                                          TextField(
                                            controller: _editEmailController,
                                            decoration: const InputDecoration(labelText: 'Email'),
                                          ),
                                          TextField(
                                            controller: _editDeptController,
                                            decoration: const InputDecoration(labelText: 'Department'),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            editStudent(student['id'].toString(), {
                                              'name': _editNameController.text,
                                              'email': _editEmailController.text,
                                              'department': _editDeptController.text,
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteStudent(student['id'].toString()),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
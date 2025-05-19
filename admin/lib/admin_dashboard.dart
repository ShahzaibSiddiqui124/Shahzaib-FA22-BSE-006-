import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final SupabaseClient supabase = SupabaseConfig.client;
  late Future<List<Map<String, dynamic>>> _studentsData;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _attendanceController = TextEditingController();
  final _marksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _studentsData = supabase
          .from('students')
          .select('id, name, attendance, marks, avatar_url')
          .order('name', ascending: true)
          .then((value) {
        return (value as List).map((item) {
          return {
            'id': item['id'],
            'name': item['name'] ?? 'Unknown',
            'attendance': item['attendance'] ?? 0,
            'marks': item['marks'] ?? 0,
            'avatar_url': item['avatar_url'] ?? 'https://via.placeholder.com/150',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading data: $e');
      _studentsData = Future.value([]);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _attendanceController,
                decoration: const InputDecoration(labelText: 'Attendance (%)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Attendance is required' : null,
              ),
              TextFormField(
                controller: _marksController,
                decoration: const InputDecoration(labelText: 'Marks'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Marks is required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Avatar URL (optional)'),
                controller: TextEditingController(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await supabase.from('students').insert({
                  'name': _nameController.text,
                  'attendance': int.parse(_attendanceController.text),
                  'marks': int.parse(_marksController.text),
                  'avatar_url': TextEditingController().text.isEmpty ? 'https://via.placeholder.com/150' : TextEditingController().text,
                });
                _nameController.clear();
                _attendanceController.clear();
                _marksController.clear();
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {
                  _loadData();
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    _nameController.text = student['name'] ?? '';
    _attendanceController.text = (student['attendance'] ?? 0).toString();
    _marksController.text = (student['marks'] ?? 0).toString();
    final avatarController = TextEditingController(text: student['avatar_url'] ?? 'https://via.placeholder.com/150');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _attendanceController,
                decoration: const InputDecoration(labelText: 'Attendance (%)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Attendance is required' : null,
              ),
              TextFormField(
                controller: _marksController,
                decoration: const InputDecoration(labelText: 'Marks'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Marks is required' : null,
              ),
              TextFormField(
                controller: avatarController,
                decoration: const InputDecoration(labelText: 'Avatar URL (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await supabase.from('students').update({
                  'name': _nameController.text,
                  'attendance': int.parse(_attendanceController.text),
                  'marks': int.parse(_marksController.text),
                  'avatar_url': avatarController.text.isEmpty ? 'https://via.placeholder.com/150' : avatarController.text,
                }).eq('id', student['id']);
                _nameController.clear();
                _attendanceController.clear();
                _marksController.clear();
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {
                  _loadData();
                });
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(int id) async {
    await supabase.from('students').delete().eq('id', id);
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        elevation: 0,
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder(
        future: _studentsData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final students = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(student['avatar_url'] ?? 'https://via.placeholder.com/150'),
                    radius: 24,
                  ),
                  title: Text(
                    student['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Attendance: ${student['attendance']}%'),
                      Text('Marks: ${student['marks']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditStudentDialog(student),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteStudent(student['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _attendanceController.dispose();
    _marksController.dispose();
    super.dispose();
  }
}
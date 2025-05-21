import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final _avatarController = TextEditingController();
  final _assignmentTitleController = TextEditingController();
  File? _selectedFile;
  bool _isUploading = false;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
      _studentsData = Future.value([]);
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  void _showAddStudentDialog() {
    _avatarController.text = 'https://via.placeholder.com/150';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Student', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _attendanceController,
                  decoration: InputDecoration(
                    labelText: 'Attendance (%)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Attendance is required';
                    final num = int.tryParse(value);
                    return num == null || num < 0 || num > 100 ? 'Enter a valid percentage (0-100)' : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _marksController,
                  decoration: InputDecoration(
                    labelText: 'Marks',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Marks is required';
                    final num = int.tryParse(value);
                    return num == null || num < 0 ? 'Enter valid marks' : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _avatarController,
                  decoration: InputDecoration(
                    labelText: 'Avatar URL (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await supabase.from('students').insert({
                    'name': _nameController.text,
                    'attendance': int.parse(_attendanceController.text),
                    'marks': int.parse(_marksController.text),
                    'avatar_url': _avatarController.text.isEmpty ? 'https://via.placeholder.com/150' : _avatarController.text,
                  });
                  _nameController.clear();
                  _attendanceController.clear();
                  _marksController.clear();
                  _avatarController.clear();
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {
                    _loadData();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding student: $e')),
                  );
                }
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    _nameController.text = student['name'] ?? '';
    _attendanceController.text = (student['attendance'] ?? 0).toString();
    _marksController.text = (student['marks'] ?? 0).toString();
    _avatarController.text = student['avatar_url'] ?? 'https://via.placeholder.com/150';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Student', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _attendanceController,
                  decoration: InputDecoration(
                    labelText: 'Attendance (%)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Attendance is required';
                    final num = int.tryParse(value);
                    return num == null || num < 0 || num > 100 ? 'Enter a valid percentage (0-100)' : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _marksController,
                  decoration: InputDecoration(
                    labelText: 'Marks',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Marks is required';
                    final num = int.tryParse(value);
                    return num == null || num < 0 ? 'Enter valid marks' : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _avatarController,
                  decoration: InputDecoration(
                    labelText: 'Avatar URL (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await supabase.from('students').update({
                    'name': _nameController.text,
                    'attendance': int.parse(_attendanceController.text),
                    'marks': int.parse(_marksController.text),
                    'avatar_url': _avatarController.text.isEmpty ? 'https://via.placeholder.com/150' : _avatarController.text,
                  }).eq('id', student['id']);
                  _nameController.clear();
                  _attendanceController.clear();
                  _marksController.clear();
                  _avatarController.clear();
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {
                    _loadData();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating student: $e')),
                  );
                }
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(int id, String name) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await supabase.from('students').delete().eq('id', id);
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {
                  _loadData();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting student: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAssignment(int studentId) async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Request storage permissions for Android
      bool permissionGranted = true;
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          permissionGranted = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
      }

      if (!permissionGranted) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        final String path = 'assignments/$studentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        // Upload file to Supabase storage
        await supabase.storage.from('assignments').upload(path, file);

        // Get the public URL
        final String fileUrl = supabase.storage.from('assignments').getPublicUrl(path);

        // Save assignment details to database
        await supabase.from('assignments').insert({
          'student_id': studentId,
          'title': _assignmentTitleController.text,
          'file_url': fileUrl,
          'file_name': fileName,
        });

        _assignmentTitleController.clear();
        setState(() {
          _selectedFile = null;
          _isUploading = false;
          _loadData();
        });

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment uploaded successfully')),
        );
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading assignment: $e')),
      );
    }
  }

  void _showAssignmentDialog(int studentId) {
    _assignmentTitleController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Upload Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _assignmentTitleController,
                decoration: InputDecoration(
                  labelText: 'Assignment Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) => value!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
                  );
                  if (result != null) {
                    setState(() {
                      _selectedFile = File(result.files.single.path!);
                    });
                  }
                },
                child: Text(
                  _selectedFile == null ? 'Select File' : 'File Selected: ${_selectedFile!.path.split('/').last}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _selectedFile == null || _isUploading
                ? null
                : () => _uploadAssignment(studentId),
            child: _isUploading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white),
            )
                : const Text('Upload', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getStudentAssignments(int studentId) async {
    try {
      final response = await supabase
          .from('assignments')
          .select('id, title, file_url, file_name, uploaded_at')
          .eq('student_id', studentId)
          .order('uploaded_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading assignments: $e')),
      );
      return [];
    }
  }

  void _showAssignmentsList(int studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Student Assignments', style: TextStyle(fontWeight: FontWeight.bold)),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getStudentAssignments(studentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final assignments = snapshot.data ?? [];
            if (assignments.isEmpty) {
              return const Text('No assignments found.');
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(assignment['title'], style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        assignment['file_name'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        onPressed: () async {
                          final url = assignment['file_url'];
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cannot open file')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _studentsData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _loadData();
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final students = snapshot.data ?? [];
            if (students.isEmpty) {
              return const Center(
                child: Text(
                  'No students found.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue[100],
                      backgroundImage: NetworkImage(student['avatar_url']),
                      onBackgroundImageError: (_, __) => const Icon(Icons.person),
                    ),
                    title: Text(
                      student['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Attendance: ${student['attendance']}%',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Marks: ${student['marks']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.upload_file, color: Colors.green),
                          onPressed: () => _showAssignmentDialog(student['id']),
                          tooltip: 'Upload Assignment',
                        ),
                        IconButton(
                          icon: const Icon(Icons.assignment, color: Colors.blue),
                          onPressed: () => _showAssignmentsList(student['id']),
                          tooltip: 'View Assignments',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditStudentDialog(student),
                          tooltip: 'Edit Student',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteStudent(student['id'], student['name']),
                          tooltip: 'Delete Student',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Student',
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _attendanceController.dispose();
    _marksController.dispose();
    _avatarController.dispose();
    _assignmentTitleController.dispose();
    super.dispose();
  }
}
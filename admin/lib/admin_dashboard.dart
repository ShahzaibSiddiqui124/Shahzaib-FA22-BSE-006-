import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'supabase_config.dart';
import 'assignments_page.dart';

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
  PlatformFile? _selectedFile;
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
            'name': item['name']?.toString() ?? 'Unknown',
            'attendance': item['attendance'] ?? 0,
            'marks': item['marks'] ?? 0,
            'avatar_url': item['avatar_url']?.toString() ?? 'https://via.placeholder.com/150',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading data: $e');
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
      print('Error logging out: $e');
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
                    'name': _nameController.text.trim(),
                    'attendance': int.parse(_attendanceController.text),
                    'marks': int.parse(_marksController.text),
                    'avatar_url': _avatarController.text.isEmpty ? 'https://via.placeholder.com/150' : _avatarController.text.trim(),
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
                  print('Error adding student: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding student: $e')),
                    );
                  }
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
                    'name': _nameController.text.trim(),
                    'attendance': int.parse(_attendanceController.text),
                    'marks': int.parse(_marksController.text),
                    'avatar_url': _avatarController.text.isEmpty ? 'https://via.placeholder.com/150' : _avatarController.text.trim(),
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
                  print('Error updating student: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating student: $e')),
                    );
                  }
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
                print('Error deleting student: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting student: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkAndRequestStoragePermission() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.storage.status;
      print('Initial permission status: $status');

      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.storage.request();
        print('After request permission status: $status');
        if (status.isDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Storage permission denied. Please allow access.'),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: _checkAndRequestStoragePermission,
                ),
              ),
            );
          }
          return false;
        }
        if (status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Permission permanently denied. Please enable it in settings.'),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: _openAppSettings,
                ),
              ),
            );
          }
          return false;
        }
      }
      return status.isGranted;
    }
    return true;
  }

  Future<void> _uploadAssignment(int studentId) async {
    if (_isUploading) return;

    try {
      setState(() {
        _isUploading = true;
      });

      if (_selectedFile == null) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected. Please select a file to upload.')),
        );
        return;
      }

      if (_selectedFile!.bytes == null) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected file has no data. Please try another file.')),
        );
        return;
      }

      final String fileName = _selectedFile!.name;
      final String path = 'assignments/$studentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      print('Uploading file: $fileName, path: $path, bytes length: ${_selectedFile!.bytes!.length}');

      final response = await supabase.storage.from('assignments').uploadBinary(
        path,
        _selectedFile!.bytes!,
        fileOptions: FileOptions(contentType: _selectedFile!.extension),
      );
      print('Upload response: $response');

      final String fileUrl = supabase.storage.from('assignments').getPublicUrl(path);
      print('Public URL: $fileUrl');

      await supabase.from('assignments').insert({
        'student_id': studentId,
        'title': _assignmentTitleController.text.trim(),
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
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading assignment: $e')),
        );
      }
    }
  }

  void _showAssignmentDialog(int studentId) {
    _assignmentTitleController.clear();
    setState(() {
      _selectedFile = null;
    });

    // Request storage permission proactively
    _checkAndRequestStoragePermission().then((hasPermission) {
      if (!hasPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required to proceed with upload.')),
        );
        return;
      }

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
                      allowCompression: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setState(() {
                        _selectedFile = result.files.first;
                        print('File selected: ${_selectedFile!.name}, bytes: ${_selectedFile!.bytes?.length}');
                      });
                    } else {
                      print('No file selected');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No file selected')),
                        );
                      }
                    }
                  },
                  child: Text(
                    _selectedFile == null ? 'Select File' : 'File Selected: ${_selectedFile!.name}',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
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
              onPressed: _isUploading ? null : () {
                if (_formKey.currentState!.validate()) {
                  _uploadAssignment(studentId);
                }
              },
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
    });
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
      print('Error loading assignments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assignments: $e')),
        );
      }
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
                      title: Text(
                        assignment['title'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        assignment['file_name'],
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        onPressed: () async {
                          final url = assignment['file_url'];
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cannot open file')),
                              );
                            }
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
            icon: const Icon(Icons.assignment, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AssignmentsPage()),
              );
            },
            tooltip: 'Manage Assignments',
          ),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Attendance: ${student['attendance']}%',
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Marks: ${student['marks']}',
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
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

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'supabase_config.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  final SupabaseClient supabase = SupabaseConfig.client;
  late Future<List<Map<String, dynamic>>> _assignments;
  final _formKey = GlobalKey<FormState>();
  final _assignmentTitleController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id ?? 'admin';
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    try {
      _assignments = supabase
          .from('global_assignments')
          .select('id, title, file_url, file_name, uploaded_at')
          .order('uploaded_at', ascending: false)
          .then((value) => (value as List).cast<Map<String, dynamic>>());
    } catch (e) {
      print('Error loading assignments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assignments: $e')),
        );
      }
      _assignments = Future.value([]);
    }
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

  Future<void> _uploadAssignment() async {
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
      final String path = 'global_assignments/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      print('Uploading file: $fileName, path: $path, bytes length: ${_selectedFile!.bytes!.length}');

      final response = await supabase.storage.from('global_assignments').uploadBinary(
        path,
        _selectedFile!.bytes!,
        fileOptions: FileOptions(contentType: _selectedFile!.extension),
      );
      print('Upload response: $response');

      final String fileUrl = supabase.storage.from('global_assignments').getPublicUrl(path);
      print('Public URL: $fileUrl');

      await supabase.from('global_assignments').insert({
        'title': _assignmentTitleController.text.trim(),
        'file_url': fileUrl,
        'file_name': fileName,
        'uploaded_by': _currentUserId,
      });

      _assignmentTitleController.clear();
      setState(() {
        _selectedFile = null;
        _isUploading = false;
        _loadAssignments();
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

  void _showUploadAssignmentDialog() {
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
                  _uploadAssignment();
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

  Future<void> _submitAssignment(int assignmentId) async {
    if (_isUploading) return;

    // Request storage permission proactively
    bool hasPermission = await _checkAndRequestStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required to proceed with submission.')),
        );
      }
      return;
    }

    try {
      setState(() {
        _isUploading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
        allowCompression: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        if (file.bytes == null) {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected file has no data. Please try another file.')),
          );
          return;
        }

        final String fileName = file.name;
        final String path = 'submissions/$assignmentId/${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}_$fileName';

        print('Uploading submission: $fileName, path: $path, bytes length: ${file.bytes!.length}');

        final response = await supabase.storage.from('submissions').uploadBinary(
          path,
          file.bytes!,
          fileOptions: FileOptions(contentType: file.extension),
        );
        print('Submission upload response: $response');

        final String fileUrl = supabase.storage.from('submissions').getPublicUrl(path);
        print('Submission public URL: $fileUrl');

        await supabase.from('submissions').insert({
          'assignment_id': assignmentId,
          'student_id': _currentUserId,
          'file_url': fileUrl,
          'file_name': fileName,
        });

        setState(() {
          _isUploading = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully')),
        );
      } else {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print('Submission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting assignment: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getSubmissions(int assignmentId) async {
    try {
      final response = await supabase
          .from('submissions')
          .select('id, student_id, file_url, file_name, submitted_at')
          .eq('assignment_id', assignmentId)
          .order('submitted_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading submissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading submissions: $e')),
        );
      }
      return [];
    }
  }

  void _showSubmissionsList(int assignmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submissions', style: TextStyle(fontWeight: FontWeight.bold)),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getSubmissions(assignmentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final submissions = snapshot.data ?? [];
            if (submissions.isEmpty) {
              return const Text('No submissions found.');
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final submission = submissions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        'Student: ${submission['student_id']}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        submission['file_name'],
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        onPressed: () async {
                          final url = submission['file_url'];
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
          'Assignments',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.blue[800],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssignments,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _assignments,
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
                        _loadAssignments();
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final assignments = snapshot.data ?? [];
            if (assignments.isEmpty) {
              return const Center(
                child: Text(
                  'No assignments found.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(
                      assignment['title'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      assignment['file_name'],
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
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
                          tooltip: 'Download Assignment',
                        ),
                        IconButton(
                          icon: const Icon(Icons.upload, color: Colors.green),
                          onPressed: () => _submitAssignment(assignment['id']),
                          tooltip: 'Submit Assignment',
                        ),
                        if (_currentUserId == 'admin')
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () => _showSubmissionsList(assignment['id']),
                            tooltip: 'View Submissions',
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
      floatingActionButton: _currentUserId == 'admin'
          ? FloatingActionButton(
        onPressed: _showUploadAssignmentDialog,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Upload Assignment',
      )
          : null,
    );
  }

  @override
  void dispose() {
    _assignmentTitleController.dispose();
    super.dispose();
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }
}
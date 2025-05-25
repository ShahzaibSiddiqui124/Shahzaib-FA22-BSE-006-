import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clipboard/clipboard.dart';
import 'dart:io';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  _AssignmentsPageState createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  Map<String, dynamic>? student;
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> submissions = [];
  bool _isLoading = false;

  Future<void> fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.from('assignments').select();
      final studentId = student!['id'].toString();
      final submissionResponse = await Supabase.instance.client
          .from('student_submissions')
          .select()
          .eq('student_id', studentId);

      setState(() {
        assignments = response.isNotEmpty ? List<Map<String, dynamic>>.from(response) : [];
        submissions = submissionResponse.isNotEmpty ? List<Map<String, dynamic>>.from(submissionResponse) : [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching assignments: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> downloadAssignment(String url) async {
    debugPrint('Attempting to launch URL: $url');

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL format')),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to launch URL: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot launch URL. Copy the link to open manually.'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              FlutterClipboard.copy(url).then((value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied to clipboard')),
                );
              });
            },
          ),
        ),
      );
    }
  }

  Future<void> uploadSubmission(String assignmentId) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        const maxFileSize = 50 * 1024 * 1024; // 50 MB in bytes
        if (fileSize > maxFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size exceeds 50 MB limit. Please upload a smaller file.'),
            ),
          );
          return;
        }

        final fileName = '${student!['id']}_${assignmentId}_${result.files.single.name}';
        final fileBytes = await file.readAsBytes();

        final bucket = Supabase.instance.client.storage.from('submissions');
        final uploadResponse = await bucket.uploadBinary(fileName, fileBytes);

        if (uploadResponse.isEmpty) {
          throw Exception('Upload failed: No response from server');
        }

        final fileUrl = bucket.getPublicUrl(fileName);
        if (fileUrl.isEmpty) {
          throw Exception('Failed to retrieve public URL');
        }

        await Supabase.instance.client.from('student_submissions').insert({
          'student_id': student!['id'],
          'assignment_id': assignmentId,
          'file_url': fileUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission uploaded successfully')),
        );
        fetchAssignments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading submission: $e')),
      );
    }
  }

  bool isOverdue(String deadline) {
    final deadlineDate = DateTime.parse(deadline);
    final now = DateTime.now();
    return now.isAfter(deadlineDate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    student = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    fetchAssignments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAssignments,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : assignments.isEmpty
            ? const Center(child: Text('No assignments available'))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                final assignmentId = assignment['id'].toString();
                final hasSubmitted = submissions.any((sub) => sub['assignment_id'].toString() == assignmentId);
                final isPastDeadline = isOverdue(assignment['deadline']);

                return Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment['title'] ?? 'No Title',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          assignment['description'] ?? 'No Description',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deadline: ${assignment['deadline'].split('T')[0]}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: ElevatedButton.icon(
                                onPressed: () => downloadAssignment(assignment['file_url']),
                                icon: const Icon(Icons.download),
                                label: const Text('Download'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: ElevatedButton.icon(
                                onPressed: (hasSubmitted || isPastDeadline)
                                    ? null
                                    : () => uploadSubmission(assignmentId),
                                icon: const Icon(Icons.upload),
                                label: Text(
                                  hasSubmitted
                                      ? 'Submitted'
                                      : isPastDeadline
                                      ? 'Overdue'
                                      : 'Upload',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasSubmitted
                                      ? Colors.grey
                                      : isPastDeadline
                                      ? Colors.red
                                      : Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
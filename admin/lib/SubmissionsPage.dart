import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clipboard/clipboard.dart'; // Import clipboard package

class SubmissionsPage extends StatefulWidget {
  const SubmissionsPage({super.key});

  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  List<Map<String, dynamic>> submissions = [];
  bool _isLoading = false;

  Future<void> fetchSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('student_submissions')
          .select('''
            id,
            student_id,
            assignment_id,
            file_url,
            submitted_at,
            students!student_id(name),
            assignments!assignment_id(title)
          ''');

      debugPrint('Fetched Submissions: $response');
      setState(() {
        submissions = response.isNotEmpty ? List<Map<String, dynamic>>.from(response) : [];
      });
    } catch (e) {
      debugPrint('Error fetching submissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching submissions: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> downloadSubmission(String url) async {
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
      // Fallback: Show the URL and allow copying to clipboard
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

  @override
  void initState() {
    super.initState();
    fetchSubmissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchSubmissions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : submissions.isEmpty
          ? const Center(child: Text('No submissions available'))
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: submissions.length,
        itemBuilder: (context, index) {
          final submission = submissions[index];
          final studentName = submission['students']?['name'] ?? 'Unknown Student';
          final assignmentTitle = submission['assignments']?['title'] ?? 'Unknown Assignment';
          final submittedAt = submission['submitted_at']?.split('T')[0] ?? 'Unknown Date';

          return Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assignment: $assignmentTitle',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Student: $studentName',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted At: $submittedAt',
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => downloadSubmission(submission['file_url']),
                    icon: const Icon(Icons.download),
                    label: const Text('Download Submission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
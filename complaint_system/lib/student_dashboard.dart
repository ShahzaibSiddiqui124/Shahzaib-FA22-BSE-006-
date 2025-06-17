import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final supabase = Supabase.instance.client;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final linkController = TextEditingController();
  bool isSubmitting = false;
  List<dynamic> complaints = [];
  RealtimeChannel? _complaintsChannel; // Store channel reference

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    // Create channel with simplified name
    _complaintsChannel = supabase.channel('complaints');

    // Use correct method name: onPostgresChanges instead of postgresChanges
    _complaintsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'complaints',
      callback: (payload) {
        _fetchComplaints();
      },
    ).subscribe(); // Chain subscribe directly
  }

  @override
  void dispose() {
    _complaintsChannel?.unsubscribe(); // Clean up channel
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() => complaints = []);
      }
      return;
    }
    try {
      final response = await supabase
          .from('complaints')
          .select('id, title, description, link, status, batch, created_at, updated_at, users(name)')
          .eq('student_id', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => complaints = response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching complaints: $e")),
        );
      }
    }
  }

  Future<void> submitComplaint() async {
    setState(() => isSubmitting = true);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not authenticated")),
        );
        setState(() => isSubmitting = false);
      }
      return;
    }
    try {
      final userData = await supabase
          .from('users')
          .select('batch')
          .eq('id', userId)
          .single();
      await supabase.from('complaints').insert({
        'title': titleController.text,
        'description': descriptionController.text,
        'link': linkController.text,
        'student_id': userId,
        'status': 'Submitted',
        'batch': userData['batch'],
      });
      titleController.clear();
      descriptionController.clear();
      linkController.clear();
      await _fetchComplaints();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submit New Complaint', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: linkController,
                      decoration: const InputDecoration(labelText: 'Image/Video Link (Google Drive)'),
                    ),
                    const SizedBox(height: 10),
                    isSubmitting
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: submitComplaint,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      child: const Text('Submit', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('My Complaints', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (complaints.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No complaints found.'),
              ),
            ...complaints.map((c) => Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${c['description'] ?? ''}\nStatus: ${c['status'] ?? ''}\nHandler: ${c['users']['name'] ?? ''}\nCreated: ${c['created_at'] ?? ''}',
                ),
                trailing: const Icon(Icons.history, color: Colors.teal),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

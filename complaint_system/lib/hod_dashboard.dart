import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HodDashboard extends StatefulWidget {
  const HodDashboard({super.key});

  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  final supabase = Supabase.instance.client;
  List<dynamic> complaints = [];
  final commentController = TextEditingController();
  RealtimeChannel? _complaintsChannel; // Store channel reference

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    // Create channel for complaints
    _complaintsChannel = supabase.channel('hod_complaints');

    // Use correct method for real-time updates
    _complaintsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'complaints',
      callback: (payload) => _fetchComplaints(),
    ).subscribe();
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
          .eq('status', 'Escalated to HOD')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => complaints = response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching complaints: $e")));
      }
    }
  }

  Future<void> resolveComplaint(int complaintId, String status) async {
    await supabase.from('complaints').update({'status': status}).eq('id', complaintId);
    await _fetchComplaints();
  }

  Future<void> addComment(int complaintId, String comment) async {
    await supabase.from('comments').insert({
      'complaint_id': complaintId,
      'comment': comment,
      'user_id': supabase.auth.currentUser!.id
    });
    await _fetchComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOD Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Escalated Complaints',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            if (complaints.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No escalated complaints found.'),
              ),

            ...complaints.map((c) => Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(c['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['description'] ?? ''),
                    const SizedBox(height: 4),
                    Text('Status: ${c['status'] ?? ''}'),
                    Text('Batch: ${c['batch'] ?? ''}'),
                    Text('Created: ${c['created_at']?.substring(0, 10) ?? ''}'),
                    if (c['users'] != null && c['users']['name'] != null)
                      Text('Submitted by: ${c['users']['name']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      tooltip: 'Mark as Resolved',
                      onPressed: () => resolveComplaint(c['id'], 'Resolved'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Reject Complaint',
                      onPressed: () => resolveComplaint(c['id'], 'Rejected'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.comment, color: Colors.blue),
                      tooltip: 'Add Comment',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Add Comment'),
                            content: TextField(
                              controller: commentController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Enter your comment',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  addComment(c['id'], commentController.text);
                                  commentController.clear();
                                  Navigator.pop(context);
                                },
                                child: const Text('Submit'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

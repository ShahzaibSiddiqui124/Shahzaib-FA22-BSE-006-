import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdvisorDashboard extends StatefulWidget {
  const AdvisorDashboard({super.key});

  @override
  State<AdvisorDashboard> createState() => _AdvisorDashboardState();
}

class _AdvisorDashboardState extends State<AdvisorDashboard> {
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
    // Create channel with simplified name
    _complaintsChannel = supabase.channel('complaints');

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
      final userData = await supabase.from('users').select('batch').eq('id', userId).single();
      final batch = userData['batch'];
      final response = await supabase
          .from('complaints')
          .select('id, title, description, link, status, batch, created_at, updated_at, users(name)')
          .eq('batch', batch)
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

  Future<void> escalateComplaint(int complaintId) async {
    await supabase.from('complaints').update({'status': 'Escalated to HOD'}).eq('id', complaintId);
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
        title: const Text('Advisor Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complaints', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                subtitle: Text('${c['description'] ?? ''}\nStatus: ${c['status'] ?? ''}\nCreated: ${c['created_at'] ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => escalateComplaint(c['id']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.comment, color: Colors.teal),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Add Comment'),
                            content: TextField(controller: commentController),
                            actions: [
                              TextButton(
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

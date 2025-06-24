import 'package:flutter/material.dart';
import 'complaint_model.dart';
import 'complaint_service.dart';
import 'package:intl/intl.dart';

class ViewComplaintsScreen extends StatefulWidget {
  const ViewComplaintsScreen({super.key});

  @override
  State<ViewComplaintsScreen> createState() => _ViewComplaintsScreenState();
}

class _ViewComplaintsScreenState extends State<ViewComplaintsScreen> {
  List<Complaint> _complaints = [];
  bool _isLoading = true;
  ComplaintStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final complaints = await ComplaintService.getAllComplaints();
      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading complaints: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Complaint> get _filteredComplaints {
    if (_filterStatus == null) return _complaints;
    return _complaints.where((complaint) => complaint.status == _filterStatus).toList();
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.solved:
        return Colors.green;
      case ComplaintStatus.rejected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Complaints'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComplaints,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: Column(
          children: [
            // Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _filterStatus == null,
                            onSelected: (selected) {
                              setState(() {
                                _filterStatus = null;
                              });
                            },
                          ),
                          ...ComplaintStatus.values.map((status) {
                            return FilterChip(
                              label: Text(status.toString().split('.').last.toUpperCase()),
                              selected: _filterStatus == status,
                              onSelected: (selected) {
                                setState(() {
                                  _filterStatus = selected ? status : null;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Complaints List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredComplaints.isEmpty
                  ? const Center(
                child: Text(
                  'No complaints found',
                  style: TextStyle(fontSize: 18),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredComplaints.length,
                itemBuilder: (context, index) {
                  final complaint = _filteredComplaints[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(complaint.status),
                        child: Icon(
                          _getStatusIcon(complaint.status),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        complaint.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From: ${complaint.senderName}'),
                          Text('To: ${complaint.receiverName}'),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(complaint.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(complaint.status),
                              ),
                            ),
                            child: Text(
                              complaint.status.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(complaint.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(complaint.description),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Created: ${DateFormat('dd/MM/yyyy HH:mm').format(complaint.createdAt)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (complaint.updatedAt != null)
                                    Text(
                                      'Updated: ${DateFormat('dd/MM/yyyy HH:mm').format(complaint.updatedAt!)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Icons.schedule;
      case ComplaintStatus.solved:
        return Icons.check_circle;
      case ComplaintStatus.rejected:
        return Icons.cancel;
    }
  }
}
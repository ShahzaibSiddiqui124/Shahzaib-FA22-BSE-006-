import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'complaint_model.dart';
import 'complaint_service.dart';

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
    setState(() => _isLoading = true);

    try {
      final complaints = await ComplaintService.getAllComplaints();
      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading complaints: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  List<Complaint> get _filteredComplaints {
    return _filterStatus == null
        ? _complaints
        : _complaints.where((complaint) => complaint.status == _filterStatus).toList();
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange[600]!;
      case ComplaintStatus.solved:
        return Colors.green[600]!;
      case ComplaintStatus.rejected:
        return Colors.redAccent;
    }
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Complaints',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadComplaints,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: size.height * 0.02,
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white.withOpacity(0.95), // Glassmorphism effect
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(maxWidth: 400), // Prevent overflow
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Filter by Status:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: Text('All', style: GoogleFonts.poppins(fontSize: 14)),
                              selected: _filterStatus == null,
                              selectedColor: const Color(0xFF3B82F6).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF3B82F6),
                              labelStyle: GoogleFonts.poppins(
                                color: _filterStatus == null ? const Color(0xFF3B82F6) : Colors.grey[600],
                              ),
                              backgroundColor: Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              onSelected: (selected) => setState(() => _filterStatus = null),
                            ),
                            ...ComplaintStatus.values.map((status) {
                              return FilterChip(
                                label: Text(
                                  status.toString().split('.').last.toUpperCase(),
                                  style: GoogleFonts.poppins(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: _filterStatus == status,
                                selectedColor: _getStatusColor(status).withOpacity(0.2),
                                checkmarkColor: _getStatusColor(status),
                                labelStyle: GoogleFonts.poppins(
                                  color: _filterStatus == status ? _getStatusColor(status) : Colors.grey[600],
                                ),
                                backgroundColor: Colors.grey[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: _getStatusColor(status).withOpacity(0.3)),
                                ),
                                onSelected: (selected) => setState(() => _filterStatus = selected ? status : null),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                    : _filteredComplaints.isEmpty
                    ? Center(
                  child: Text(
                    'No complaints found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(size.width * 0.06),
                  itemCount: _filteredComplaints.length,
                  itemBuilder: (context, index) {
                    final complaint = _filteredComplaints[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white.withOpacity(0.95),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: _getStatusColor(complaint.status).withOpacity(0.1),
                          child: Icon(
                            _getStatusIcon(complaint.status),
                            color: _getStatusColor(complaint.status),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          complaint.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E3A8A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From: ${complaint.senderName}',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'To: ${complaint.receiverName}',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(complaint.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _getStatusColor(complaint.status).withOpacity(0.3)),
                              ),
                              child: Text(
                                complaint.status.toString().split('.').last.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(complaint.status),
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
                                Text(
                                  'Description:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E3A8A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  complaint.description,
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Created: ${DateFormat('dd/MM/yyyy HH:mm').format(complaint.createdAt)}',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    if (complaint.updatedAt != null)
                                      Text(
                                        'Updated: ${DateFormat('dd/MM/yyyy HH:mm').format(complaint.updatedAt!)}',
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
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
      ),
    );
  }
}
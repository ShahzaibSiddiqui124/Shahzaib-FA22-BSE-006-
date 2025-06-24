import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_model.dart';
import 'complaint_model.dart';
import 'auth_service.dart';
import 'complaint_service.dart';
import 'create_complaint_screen.dart';
import 'my_complaints_screen.dart';
import 'received_complaints_screen.dart';

class UserDashboard extends StatefulWidget {
  final AppUser user;

  const UserDashboard({super.key, required this.user});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _sentComplaintsCount = 0;
  int _receivedComplaintsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComplaintCounts();
  }

  Future<void> _loadComplaintCounts() async {
    setState(() => _isLoading = true);

    try {
      final sentComplaints = await ComplaintService.getSentComplaints(widget.user.id);
      final receivedComplaints = await ComplaintService.getReceivedComplaints(widget.user.id);
      setState(() {
        _sentComplaintsCount = sentComplaints.length;
        _receivedComplaintsCount = receivedComplaints.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading counts: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Color _getRoleColor() {
    switch (widget.user.role) {
      case UserRole.hod:
        return Colors.red;
      case UserRole.teacher:
        return Colors.orange;
      case UserRole.student:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleTitle() {
    switch (widget.user.role) {
      case UserRole.hod:
        return 'Head of Department';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_getRoleTitle()} Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: _getRoleColor(),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_getRoleColor(), Colors.purple],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(size.width * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: size.width * 0.08,
                              backgroundColor: _getRoleColor(),
                              child: Icon(_getUserIcon(), size: 30, color: Colors.white),
                            ),
                            SizedBox(width: size.width * 0.04),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${widget.user.name}!',
                                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _getRoleTitle(),
                                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard('Sent', _sentComplaintsCount.toString(), Icons.send, Colors.blue),
                            ),
                            SizedBox(width: size.width * 0.03),
                            Expanded(
                              child: _buildStatCard('Received', _receivedComplaintsCount.toString(), Icons.inbox, Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.03),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: size.width > 600 ? 3 : 2,
                    crossAxisSpacing: size.width * 0.04,
                    mainAxisSpacing: size.height * 0.02,
                    children: [
                      _buildMenuCard(
                        icon: Icons.add_circle,
                        title: 'Create Complaint',
                        subtitle: 'Submit a new complaint',
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateComplaintScreen(user: widget.user)))
                            .then((_) => _loadComplaintCounts()),
                      ),
                      _buildMenuCard(
                        icon: Icons.send,
                        title: 'My Complaints',
                        subtitle: 'View sent complaints',
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyComplaintsScreen(user: widget.user)))
                            .then((_) => _loadComplaintCounts()),
                      ),
                      if (widget.user.role != UserRole.student)
                        _buildMenuCard(
                          icon: Icons.inbox,
                          title: 'Received Complaints',
                          subtitle: 'View received complaints',
                          color: Colors.green,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceivedComplaintsScreen(user: widget.user)))
                              .then((_) => _loadComplaintCounts()),
                        ),
                      _buildMenuCard(
                        icon: Icons.refresh,
                        title: 'Refresh',
                        subtitle: 'Update dashboard',
                        color: Colors.purple,
                        onTap: _loadComplaintCounts,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getUserIcon() {
    switch (widget.user.role) {
      case UserRole.hod:
        return Icons.school;
      case UserRole.teacher:
        return Icons.person;
      case UserRole.student:
        return Icons.school_outlined;
      default:
        return Icons.person;
    }
  }
}
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
        SnackBar(
          content: Text('Error loading counts: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
        return Colors.red[600]!;
      case UserRole.teacher:
        return Colors.orange[600]!;
      case UserRole.student:
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_getRoleTitle()} Dashboard',
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
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
              : SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.06,
              vertical: size.height * 0.02,
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.white.withOpacity(0.95), // Glassmorphism effect
                  child: Container(
                    padding: EdgeInsets.all(size.width * 0.05),
                    constraints: const BoxConstraints(maxWidth: 400), // Prevent overflow
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
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
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E3A8A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _getRoleTitle(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
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
                              child: _buildStatCard('Sent', _sentComplaintsCount.toString(), Icons.send, Colors.blue[600]!),
                            ),
                            SizedBox(width: size.width * 0.03),
                            Expanded(
                              child: _buildStatCard('Received', _receivedComplaintsCount.toString(), Icons.inbox, Colors.green[600]!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.03),
                GridView.count(
                  crossAxisCount: size.width > 600 ? 3 : 2,
                  crossAxisSpacing: size.width * 0.04,
                  mainAxisSpacing: size.height * 0.02,
                  childAspectRatio: size.width > 600 ? 1.0 : 0.8, // Adjust aspect ratio for smaller screens
                  shrinkWrap: true, // Prevent GridView from expanding infinitely
                  physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling
                  children: [
                    _buildMenuCard(
                      icon: Icons.add_circle,
                      title: 'Create Complaint',
                      subtitle: 'Submit a new complaint',
                      color: Colors.blue[600]!,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateComplaintScreen(user: widget.user)))
                          .then((_) => _loadComplaintCounts()),
                    ),
                    _buildMenuCard(
                      icon: Icons.send,
                      title: 'My Complaints',
                      subtitle: 'View sent complaints',
                      color: Colors.orange[600]!,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyComplaintsScreen(user: widget.user)))
                          .then((_) => _loadComplaintCounts()),
                    ),
                    if (widget.user.role != UserRole.student)
                      _buildMenuCard(
                        icon: Icons.inbox,
                        title: 'Received Complaints',
                        subtitle: 'View received complaints',
                        color: Colors.green[600]!,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceivedComplaintsScreen(user: widget.user)))
                            .then((_) => _loadComplaintCounts()),
                      ),
                    _buildMenuCard(
                      icon: Icons.refresh,
                      title: 'Refresh',
                      subtitle: 'Update dashboard',
                      color: Colors.purple[600]!,
                      onTap: _loadComplaintCounts,
                    ),
                  ],
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
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
            ),
          ),
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
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.95),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E3A8A),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
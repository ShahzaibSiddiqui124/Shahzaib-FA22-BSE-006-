import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_model.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'add_user_screen.dart';
import 'view_users_screen.dart';
import 'view_complaints_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: size.width * 0.08,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.admin_panel_settings, size: 30, color: Colors.white),
                        ),
                        SizedBox(width: size.width * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${_currentUser?.name ?? 'Admin'}!',
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'System Administrator',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
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
                        icon: Icons.person_add,
                        title: 'Add User',
                        subtitle: 'Create new users',
                        color: Colors.green,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen())),
                      ),
                      _buildMenuCard(
                        icon: Icons.people,
                        title: 'View Users',
                        subtitle: 'Manage all users',
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewUsersScreen())),
                      ),
                      _buildMenuCard(
                        icon: Icons.report_problem,
                        title: 'View Complaints',
                        subtitle: 'Monitor all complaints',
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewComplaintsScreen())),
                      ),
                      _buildMenuCard(
                        icon: Icons.analytics,
                        title: 'Statistics',
                        subtitle: 'View system stats',
                        color: Colors.purple,
                        onTap: _showStatistics,
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
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('System Statistics', style: GoogleFonts.poppins()),
        content: const Text('Statistics feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
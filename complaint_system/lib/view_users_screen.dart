import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'user_model.dart';
import 'auth_service.dart';

class ViewUsersScreen extends StatefulWidget {
  const ViewUsersScreen({super.key});

  @override
  State<ViewUsersScreen> createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends State<ViewUsersScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  UserRole? _filterRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await AuthService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  List<AppUser> get _filteredUsers {
    return _filterRole == null
        ? _users
        : _users.where((user) => user.role == _filterRole).toList();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
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

  IconData _getUserIcon(UserRole role) {
    switch (role) {
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

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Users',
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
            onPressed: _loadUsers,
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
                          'Filter by Role:',
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
                              selected: _filterRole == null,
                              selectedColor: const Color(0xFF3B82F6).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF3B82F6),
                              labelStyle: GoogleFonts.poppins(
                                color: _filterRole == null ? const Color(0xFF3B82F6) : Colors.grey[600],
                              ),
                              backgroundColor: Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              onSelected: (selected) => setState(() => _filterRole = null),
                            ),
                            ...UserRole.values.map((role) {
                              return FilterChip(
                                label: Text(
                                  role.toString().split('.').last.toUpperCase(),
                                  style: GoogleFonts.poppins(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: _filterRole == role,
                                selectedColor: _getRoleColor(role).withOpacity(0.2),
                                checkmarkColor: _getRoleColor(role),
                                labelStyle: GoogleFonts.poppins(
                                  color: _filterRole == role ? _getRoleColor(role) : Colors.grey[600],
                                ),
                                backgroundColor: Colors.grey[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: _getRoleColor(role).withOpacity(0.3)),
                                ),
                                onSelected: (selected) => setState(() => _filterRole = selected ? role : null),
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
                    : _filteredUsers.isEmpty
                    ? Center(
                  child: Text(
                    'No users found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(size.width * 0.06),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white.withOpacity(0.95),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                          child: Icon(
                            _getUserIcon(user.role),
                            color: _getRoleColor(user.role),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          user.name,
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
                              user.email,
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.username,
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user.role).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _getRoleColor(user.role).withOpacity(0.3)),
                              ),
                              child: Text(
                                user.role.toString().split('.').last.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getRoleColor(user.role),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          'Created: ${_formatDate(user.createdAt)}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
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
import 'package:flutter/material.dart';
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
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await AuthService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<AppUser> get _filteredUsers {
    if (_filterRole == null) return _users;
    return _users.where((user) => user.role == _filterRole).toList();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Users'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
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
                        'Filter by Role:',
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
                            selected: _filterRole == null,
                            onSelected: (selected) {
                              setState(() {
                                _filterRole = null;
                              });
                            },
                          ),
                          ...UserRole.values.map((role) {
                            return FilterChip(
                              label: Text(role.toString().split('.').last.toUpperCase()),
                              selected: _filterRole == role,
                              onSelected: (selected) {
                                setState(() {
                                  _filterRole = selected ? role : null;
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

            // Users List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                  ? const Center(
                child: Text(
                  'No users found',
                  style: TextStyle(fontSize: 18),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(user.role),
                        child: Icon(
                          _getUserIcon(user.role),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          Text(user.username),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getRoleColor(user.role),
                              ),
                            ),
                            child: Text(
                              user.role.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                color: _getRoleColor(user.role),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        'Created: ${_formatDate(user.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
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
    return '${date.day}/${date.month}/${date.year}';
  }
}
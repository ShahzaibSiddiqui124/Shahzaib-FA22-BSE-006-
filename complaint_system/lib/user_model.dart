enum UserRole { admin, hod, teacher, student }

class AppUser {
  final String id;
  final String username;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: UserRole.values.firstWhere(
            (e) => e.toString().split('.').last == (json['role'] ?? 'student'),
        orElse: () => UserRole.student,
      ),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_model.dart';

class AuthService {
  static SupabaseClient get _supabase => Supabase.instance.client;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _adminUsername = 'admin01@';
  static const String _adminPassword = 'admin1122';

  static bool isAdmin(String username, String password) {
    return username == _adminUsername && password == _adminPassword;
  }

  static Future<AppUser?> login(String username, String password) async {
    try {
      if (isAdmin(username, password)) {
        final adminUser = AppUser(
          id: 'admin-001',
          username: username,
          email: 'admin@institution.com',
          name: 'System Administrator',
          role: UserRole.admin,
          createdAt: DateTime.now(),
        );

        await _storage.write(key: 'user_id', value: adminUser.id);
        await _storage.write(key: 'user_role', value: adminUser.role.toString());
        await _storage.write(key: 'user_name', value: adminUser.name);

        return adminUser;
      }

      final response = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response == null) return null;

      final user = AppUser.fromJson(response);
      await _storage.write(key: 'user_id', value: user.id);
      await _storage.write(key: 'user_role', value: user.role.toString());
      await _storage.write(key: 'user_name', value: user.name);

      return user;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  static Future<AppUser?> getCurrentUser() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) return null;

      if (userId == 'admin-001') {
        return AppUser(
          id: userId,
          username: _adminUsername,
          email: 'admin@institution.com',
          name: (await _storage.read(key: 'user_name')) ?? 'System Administrator',
          role: UserRole.admin,
          createdAt: DateTime.now(),
        );
      }

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return AppUser.fromJson(response);
    } catch (e) {
      print('Get current user error: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  static Future<bool> addUser({
    required String username,
    required String password,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    try {
      await _supabase.from('users').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'username': username,
        'password': password,
        'email': email,
        'name': name,
        'role': role.toString().split('.').last,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Add user error: $e');
      return false;
    }
  }

  static Future<List<AppUser>> getAllUsers() async {
    try {
      final response = await _supabase.from('users').select().order('created_at', ascending: false);
      return (response as List).map((json) => AppUser.fromJson(json)).toList();
    } catch (e) {
      print('Get all users error: $e');
      return [];
    }
  }

  static Future<List<AppUser>> getUsersByRole(UserRole role) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', role.toString().split('.').last)
          .order('created_at', ascending: false);
      return (response as List).map((json) => AppUser.fromJson(json)).toList();
    } catch (e) {
      print('Get users by role error: $e');
      return [];
    }
  }
}
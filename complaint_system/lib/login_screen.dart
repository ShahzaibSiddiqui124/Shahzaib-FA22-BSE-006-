import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_model.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.login(_usernameController.text.trim(), _passwordController.text);

      if (!mounted) return;
      if (user != null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          user.role == UserRole.admin ? '/admin' : '/user',
              (route) => false,
          arguments: user,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(size.width * 0.06),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(size.width * 0.08),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
                        SizedBox(height: size.height * 0.03),
                        Text(
                          'Complaint Management System',
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.04),
                        DropdownButtonFormField<UserRole>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Login as',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          items: UserRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.toString().split('.').last.toUpperCase(), style: GoogleFonts.poppins()),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedRole = value!),
                        ),
                        SizedBox(height: size.height * 0.02),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          validator: (value) => value!.isEmpty ? 'Please enter username' : null,
                        ),
                        SizedBox(height: size.height * 0.02),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) => value!.isEmpty ? 'Please enter password' : null,
                        ),
                        SizedBox(height: size.height * 0.03),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text('Login', style: GoogleFonts.poppins(fontSize: 16)),
                          ),
                        ),
                        if (_selectedRole == UserRole.admin) ...[
                          SizedBox(height: size.height * 0.02),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Admin Credentials:',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Username: admin01@\nPassword: admin1122',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
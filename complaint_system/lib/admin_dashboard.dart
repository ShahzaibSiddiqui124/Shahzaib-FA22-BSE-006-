import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_model.dart';
import 'auth_service.dart';
import 'add_user_screen.dart';
import 'view_users_screen.dart';
import 'view_complaints_screen.dart';
import 'dart:async';

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
        SnackBar(
          content: Text('Error loading user: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
        title: Text(
          'Admin Dashboard',
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
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : ListView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.06,
              vertical: size.height * 0.02,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: Colors.white.withOpacity(0.95),
                    child: Container(
                      padding: EdgeInsets.all(size.width * 0.05),
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: size.width * 0.08,
                            backgroundColor: const Color(0xFF3B82F6),
                            child: const Icon(Icons.admin_panel_settings,
                                size: 30, color: Colors.white),
                          ),
                          SizedBox(width: size.width * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${_currentUser?.name ?? 'Admin'}!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E3A8A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'System Administrator',
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
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),
              GridView.count(
                crossAxisCount: size.width > 900 ? 4 : 2,
                crossAxisSpacing: size.width * 0.04,
                mainAxisSpacing: size.height * 0.02,
                childAspectRatio: 1.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMenuCard(
                    icon: Icons.person_add,
                    title: 'Add User',
                    subtitle: 'Create new users',
                    color: Colors.green[600]!,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AddUserScreen())),
                  ),
                  _buildMenuCard(
                    icon: Icons.people,
                    title: 'View Users',
                    subtitle: 'Manage all users',
                    color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ViewUsersScreen())),
                  ),
                  _buildMenuCard(
                    icon: Icons.report_problem,
                    title: 'View Complaints',
                    subtitle: 'Monitor all complaints',
                    color: Colors.orange[600]!,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ViewComplaintsScreen())),
                  ),
                  _buildMenuCard(
                    icon: Icons.analytics,
                    title: 'Statistics',
                    subtitle: 'View system stats',
                    color: Colors.purple[600]!,
                    onTap: _showStatistics,
                  ),
                  // NEW CSV UPLOAD MODULE
                  _buildMenuCard(
                    icon: Icons.upload_file,
                    title: 'Upload Files',
                    subtitle: 'CSV/PDF documents',
                    color: Colors.teal[600]!,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const UploadCsvScreen())),
                  ),
                ],
              ),
            ],
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E3A8A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white.withOpacity(0.95),
        title: Text(
          'System Statistics',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        content: Text(
          'Statistics feature coming soon!',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// UPLOAD CSV SCREEN WITH SUPPORTED UPLOAD METHOD
class UploadCsvScreen extends StatefulWidget {
  const UploadCsvScreen({super.key});

  @override
  State<UploadCsvScreen> createState() => _UploadCsvScreenState();
}

class _UploadCsvScreenState extends State<UploadCsvScreen> {
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  double _progress = 0;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
          _progress = 0;
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (_pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        _showError('User not authenticated');
        setState(() => _isUploading = false);
        return;
      }

      final file = File(_pickedFile!.path!);
      final fileExtension = _pickedFile!.extension ?? 'bin';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final fileBytes = await file.readAsBytes();
      final fileSize = fileBytes.length;

      // Create periodic timer to simulate progress
      const progressInterval = Duration(milliseconds: 100);
      final timer = Timer.periodic(progressInterval, (Timer t) {
        if (_progress < 0.95) {
          setState(() => _progress += 0.05);
        }
      });

      // Perform actual upload
      final response = await Supabase.instance.client.storage
          .from('uploads')
          .uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(upsert: false),
      );

      // Cancel timer and set progress to complete
      timer.cancel();
      setState(() => _progress = 1.0);

      // Get public URL
      final urlResponse = Supabase.instance.client.storage
          .from('uploads')
          .getPublicUrl(fileName);

      // Save to database table
      await Supabase.instance.client.from('uploaded_files').insert({
        'file_name': _pickedFile!.name,
        'file_path': urlResponse,
        'file_type': fileExtension,
        'file_size': fileSize,
        'uploaded_by': user.id,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      // Show success message
      _showSuccess('File uploaded successfully!');

      // Reset after a short delay to show completion
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _pickedFile = null;
        _isUploading = false;
        _progress = 0;
      });
    } catch (e) {
      _showError('Upload failed: $e');
      setState(() {
        _isUploading = false;
        _progress = 0;
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Files',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload, size: 60, color: Colors.blue[300]),
                        const SizedBox(height: 20),
                        Text(
                          'Upload CSV or PDF Files',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Supported formats: .csv, .pdf\nMax size: 10MB',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: Text(
                            'Select File',
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _pickFile,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (_pickedFile != null) ...[
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white.withOpacity(0.95),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.insert_drive_file,
                            color: Colors.teal),
                      ),
                      title: Text(
                        _pickedFile!.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${(_pickedFile!.size / 1024).toStringAsFixed(2)} KB',
                        style: GoogleFonts.poppins(),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => setState(() => _pickedFile = null),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isUploading) ...[
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blue,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Uploading: ${(_progress * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton(
                    onPressed: _isUploading ? null : _uploadFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUploading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Uploading...',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ],
                    )
                        : Text(
                      'Upload to Server',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
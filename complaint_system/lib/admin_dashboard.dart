import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;
  bool isUploading = false;
  String status = '';

  Future<void> uploadCSV() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result == null) return;

    final file = File(result.files.single.path!); // Create File object from path
    final input = await file.readAsString(); // Read file content as string
    final fields = const CsvToListConverter().convert(input);

    final headers = fields[0] as List;
    final rows = fields.sublist(1) as List<List>;

    setState(() => isUploading = true);

    try {
      for (var row in rows) {
        final data = Map.fromIterables(headers, row);
        final deptId = await getDepartmentId(data['Department'] as String);
        await supabase.from('users').insert({
          'name': data['Student Name'],
          'email': data['Email'],
          'batch': data['Batch'],
          'role': 'student',
          'department_id': deptId,
          'advisor_email': data['Advisor Email'],
        });
      }
      setState(() => status = 'Upload successful');
    } catch (e) {
      setState(() => status = 'Error: $e');
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<String?> getDepartmentId(String name) async {
    final response = await supabase
        .from('departments')
        .select('id')
        .eq('name', name)
        .maybeSingle();
    return response?['id'] ?? (await supabase.from('departments').insert({'name': name}).select('id').maybeSingle())?['id'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: isUploading ? null : uploadCSV,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Upload Students CSV', style: TextStyle(color: Colors.white)),
                ),
                if (status.isNotEmpty) Text(status, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                const Text('CSV Format: Student Name, Email, Batch, Department, Advisor Email',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
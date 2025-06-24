import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_model.dart';
import 'complaint_service.dart';
import 'auth_service.dart';

class CreateComplaintScreen extends StatefulWidget {
  final AppUser user;

  const CreateComplaintScreen({super.key, required this.user});

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  AppUser? _selectedReceiver;
  List<AppUser> _availableReceivers = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableReceivers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableReceivers() async {
    setState(() => _isLoading = true);

    try {
      List<AppUser> receivers = [];
      if (widget.user.role == UserRole.student) {
        receivers.addAll(await AuthService.getUsersByRole(UserRole.teacher));
        receivers.addAll(await AuthService.getUsersByRole(UserRole.hod));
      } else if (widget.user.role == UserRole.teacher) {
        receivers.addAll(await AuthService.getUsersByRole(UserRole.hod));
      }

      setState(() {
        _availableReceivers = receivers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading receivers: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate() || _selectedReceiver == null) {
      if (_selectedReceiver == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a receiver'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await ComplaintService.createComplaint(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        senderId: widget.user.id,
        senderName: widget.user.name,
        receiverId: _selectedReceiver!.id,
        receiverName: _selectedReceiver!.name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Complaint submitted successfully!' : 'Failed to submit complaint.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Complaint', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.06),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit New Complaint',
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      SizedBox(height: size.height * 0.03),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Complaint Title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter complaint title' : null,
                      ),
                      SizedBox(height: size.height * 0.02),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_availableReceivers.isEmpty)
                        Card(
                          color: Colors.orange,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No available receivers found',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<AppUser>(
                          value: _selectedReceiver,
                          decoration: InputDecoration(
                            labelText: 'Send to',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          items: _availableReceivers.map((user) {
                            return DropdownMenuItem(
                              value: user,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(user.name, style: GoogleFonts.poppins()),
                                  Text(
                                    '${user.role.toString().split('.').last.toUpperCase()} - ${user.email}',
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedReceiver = value),
                        ),
                      SizedBox(height: size.height * 0.02),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter complaint description';
                          if (value.length < 10) return 'Description must be at least 10 characters';
                          return null;
                        },
                      ),
                      SizedBox(height: size.height * 0.03),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _isLoading ? null : _submitComplaint,
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('Submit Complaint', style: GoogleFonts.poppins(fontSize: 16)),
                        ),
                      ),
                    ],
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
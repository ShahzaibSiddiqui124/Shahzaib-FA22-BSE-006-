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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAvailableReceivers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
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
        SnackBar(
          content: Text('Error loading receivers: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate() || _selectedReceiver == null) {
      if (_selectedReceiver == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a receiver', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
          content: Text(
            success ? 'Complaint submitted successfully!' : 'Failed to submit complaint.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: success ? Colors.green[600] : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      if (success) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Complaint',
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
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06,
                vertical: viewInsets.bottom > 0 ? 8.0 : size.height * 0.02,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.vertical,
                ),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.white.withOpacity(0.95),
                  child: Container(
                    padding: EdgeInsets.all(size.width * 0.05),
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      minHeight: viewInsets.bottom > 0 ? size.height * 0.7 : 0,
                    ),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Submit New Complaint',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),
                          TextFormField(
                            controller: _titleController,
                            maxLines: 1,
                            decoration: InputDecoration(
                              labelText: 'Complaint Title',
                              labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                              ),
                              prefixIcon: const Icon(Icons.title, color: Color(0xFF3B82F6)),
                            ),
                            validator: (value) => value!.isEmpty ? 'Please enter complaint title' : null,
                          ),
                          SizedBox(height: size.height * 0.025),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                          else if (_availableReceivers.isEmpty)
                            Card(
                              color: Colors.orange[50],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No available receivers found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            )
                          else
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: size.width * 0.8,
                                maxHeight: size.height * 0.3,
                              ),
                              child: SingleChildScrollView(
                                child: DropdownButtonFormField<AppUser>(
                                  value: _selectedReceiver,
                                  decoration: InputDecoration(
                                    labelText: 'Send to',
                                    labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                    ),
                                    prefixIcon: const Icon(Icons.person, color: Color(0xFF3B82F6)),
                                  ),
                                  items: _availableReceivers.map((user) {
                                    return DropdownMenuItem<AppUser>(
                                      value: user,
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: user.name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' | ${user.role.toString().split('.').last.toUpperCase()} - ${user.email}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(() => _selectedReceiver = value),
                                ),
                              ),
                            ),
                          SizedBox(height: size.height * 0.025),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: size.height * 0.3),
                            child: SingleChildScrollView(
                              child: TextFormField(
                                controller: _descriptionController,
                                maxLines: null,
                                minLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                  ),
                                  prefixIcon: const Icon(Icons.description, color: Color(0xFF3B82F6)),
                                  alignLabelWithHint: true,
                                ),
                                validator: (value) {
                                  if (value!.isEmpty) return 'Please enter complaint description';
                                  if (value.length < 10) return 'Description must be at least 10 characters';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting || _isLoading ? null : _submitComplaint,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.center,
                                child: _isSubmitting
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                  'Submit Complaint',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }
}

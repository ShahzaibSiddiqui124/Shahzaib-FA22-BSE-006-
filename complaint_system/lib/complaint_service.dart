import 'package:supabase_flutter/supabase_flutter.dart';
import 'complaint_model.dart';

class ComplaintService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  static Future<bool> createComplaint({
    required String title,
    required String description,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
  }) async {
    try {
      await _supabase.from('complaints').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'description': description,
        'sender_id': senderId,
        'sender_name': senderName,
        'receiver_id': receiverId,
        'receiver_name': receiverName,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Create complaint error: $e');
      return false;
    }
  }

  static Future<List<Complaint>> getSentComplaints(String userId) async {
    try {
      final response = await _supabase
          .from('complaints')
          .select()
          .eq('sender_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => Complaint.fromJson(json)).toList();
    } catch (e) {
      print('Get sent complaints error: $e');
      return [];
    }
  }

  static Future<List<Complaint>> getReceivedComplaints(String userId) async {
    try {
      final response = await _supabase
          .from('complaints')
          .select()
          .eq('receiver_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => Complaint.fromJson(json)).toList();
    } catch (e) {
      print('Get received complaints error: $e');
      return [];
    }
  }

  static Future<bool> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async {
    try {
      await _supabase.from('complaints').update({
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', complaintId);
      return true;
    } catch (e) {
      print('Update complaint status error: $e');
      return false;
    }
  }

  static Future<List<Complaint>> getAllComplaints() async {
    try {
      final response = await _supabase.from('complaints').select().order('created_at', ascending: false);
      return (response as List).map((json) => Complaint.fromJson(json)).toList();
    } catch (e) {
      print('Get all complaints error: $e');
      return [];
    }
  }

  static Future<List<Complaint>> getComplaintsByStatus(ComplaintStatus status) async {
    try {
      final response = await _supabase
          .from('complaints')
          .select()
          .eq('status', status.toString().split('.').last)
          .order('created_at', ascending: false);
      return (response as List).map((json) => Complaint.fromJson(json)).toList();
    } catch (e) {
      print('Get complaints by status error: $e');
      return [];
    }
  }
}
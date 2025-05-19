import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://fyiashlxnnlquzzpkolq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5aWFzaGx4bm5scXV6enBrb2xxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1NjYyMTQsImV4cCI6MjA2MzE0MjIxNH0.fTw10TQUxy56BmdsqCDGNnSsWpWoulUM2FHS_27sesc';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
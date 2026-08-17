import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/savings_entry.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://hgpuzvpafpbpaatcutbm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhncHV6dnBhZnBicGFhdGN1dGJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1NjUzNDIsImV4cCI6MjEwMjE0MTM0Mn0.AXXykroFn5jJ69kjol2NrnxxgRt5ctIf7dXSTd6-of0';

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;

  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (_) {}
  }

  static Future<AuthResponse?> signInWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(email: email, password: password);
      print('✅ [Supabase Auth] User Logged in: ${response.user?.email}');
      return response;
    } catch (e) {
      print('❌ [Supabase Auth] Login Error: $e');
      return null;
    }
  }

  static Future<AuthResponse?> signUpWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signUp(email: email, password: password);
      print('✅ [Supabase Auth] User Signed up: ${response.user?.email}');
      return response;
    } catch (e) {
      print('❌ [Supabase Auth] Register Error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<List<SavingsEntry>> fetchEntries() async {
    try {
      print('🔍 [Supabase] Current user: ${currentUser?.id}');
      var query = client.from('savings_entries').select('*');
      if (currentUser != null) {
        query = query.eq('user_id', currentUser!.id);
      }
      final data = await query.order('entry_date', ascending: false);
      print('✅ [Supabase] Loaded ${(data as List).length} entries from cloud database');
      return data.map((map) => SavingsEntry.fromMap(map)).toList();
    } catch (e) {
      print('❌ [Supabase] Fetch Error: $e');
      return [];
    }
  }

  static Future<void> syncSaveEntry(SavingsEntry entry) async {
    try {
      final catTag = entry.category.isNotEmpty ? '[${entry.category}] ' : '';
      final cleanNote = entry.note.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
      final fullNote = '$catTag$cleanNote'.trim();

      final payload = <String, dynamic>{
        'id': entry.id,
        'entry_date': entry.date,
        'amount': entry.amount.toInt(),
        'note': fullNote,
      };

      if (currentUser != null) {
        payload['user_id'] = currentUser!.id;
      }

      await client.from('savings_entries').upsert(payload);
      print('✅ [Supabase] Synced entry ${entry.id} (${entry.amount}đ) to cloud!');
    } catch (e) {
      print('❌ [Supabase] Sync Save Error: $e');
    }
  }

  static Future<void> syncDeleteEntry(String id) async {
    try {
      await client.from('savings_entries').delete().eq('id', id);
      print('✅ [Supabase] Deleted entry $id from cloud!');
    } catch (e) {
      print('❌ [Supabase] Sync Delete Error: $e');
    }
  }
}

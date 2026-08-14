import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/savings_entry.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://hgpuzvpafpbpaatcutbm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhncHV6dnBhZnBicGFhdGN1dGJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1NDg1NjMsImV4cCI6MjA1NDEyNDU2M30.z890-eK-e8Pj_3L7YJ7uG9u9P_0s3s-K9v-1s2';

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

  static Future<List<SavingsEntry>> fetchEntries() async {
    if (currentUser == null) return [];
    final data = await client
        .from('savings_entries')
        .select('*')
        .eq('user_id', currentUser!.id)
        .order('entry_date', ascending: false);

    return (data as List).map((map) => SavingsEntry.fromMap(map)).toList();
  }

  static Future<void> syncSaveEntry(SavingsEntry entry) async {
    if (currentUser == null) return;
    final payload = entry.toMap();
    payload['user_id'] = currentUser!.id;
    await client.from('savings_entries').upsert(payload);
  }
}

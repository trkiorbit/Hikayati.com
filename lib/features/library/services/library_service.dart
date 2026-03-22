import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hikayati/core/network/supabase_service.dart';

class LibraryService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<dynamic>> getPrivateStories() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('المستخدم غير مسجل الدخول.');
    }

    final data = await _client
        .from('stories')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data;
  }

  Future<List<dynamic>> getPublicStories() async {
    final data = await _client
        .from('public_stories')
        .select()
        .order('created_at', ascending: false);
    return data;
  }
}

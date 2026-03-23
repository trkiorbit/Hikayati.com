import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hikayati/core/network/supabase_service.dart';
import 'package:flutter/foundation.dart';

class LibraryService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<dynamic>> getPrivateStories() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('المستخدم غير مسجل الدخول.');

    final data = await _client
        .from('stories')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data;
  }

  Future<int> getStoryCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await _client
        .from('stories')
        .select('id')
        .eq('user_id', userId);

    return (data as List).length;
  }

  /// حذف قصة مع ملفاتها الصوتية من Supabase Storage
  Future<void> deleteStory(String storyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('المستخدم غير مسجل الدخول.');

    // حذف ملفات الصوت من Storage (3 مشاهد كحد أقصى)
    try {
      final filesToDelete = <String>[];
      for (int i = 0; i < 10; i++) {
        filesToDelete.add('$userId/${storyId}_scene_$i.mp3');
      }
      await _client.storage.from('story_audio').remove(filesToDelete);
      debugPrint('[Library] 🗑️ تم حذف ملفات الصوت للقصة $storyId');
    } catch (e) {
      debugPrint('[Library] ⚠️ تعذر حذف ملفات الصوت: $e');
    }

    // حذف القصة من قاعدة البيانات
    await _client
        .from('stories')
        .delete()
        .eq('id', storyId)
        .eq('user_id', userId);

    debugPrint('[Library] ✅ تم حذف القصة $storyId نهائياً');
  }

  Future<List<dynamic>> getPublicStories() async {
    final data = await _client
        .from('public_stories')
        .select()
        .order('created_at', ascending: false);
    return data;
  }

  Future<List<String>> getUnlockedPublicStories() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('purchases')
        .select('story_id')
        .eq('user_id', userId)
        .eq('unlock_type', 'access');

    return (data as List).map((e) => e['story_id'].toString()).toList();
  }
}


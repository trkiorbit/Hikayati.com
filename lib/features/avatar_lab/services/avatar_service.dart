import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hikayati/core/network/supabase_service.dart';

class AvatarService {
  final SupabaseClient _client = SupabaseService.client;

  Future<void> saveAvatarToProfile(Map<String, dynamic> avatarData) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('يجب تسجيل الدخول لحفظ البطل الخاص بك.');
    }

    await _client.from('profiles').update({
      'avatar_profile_summary': avatarData,
    }).eq('user_id', userId);
  }

  Future<Map<String, dynamic>?> getAvatarData() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select('avatar_profile_summary')
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null && response['avatar_profile_summary'] != null) {
      return response['avatar_profile_summary'] as Map<String, dynamic>;
    }
    return null;
  }
}

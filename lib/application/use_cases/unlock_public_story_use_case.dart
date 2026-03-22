import 'package:hikayati/core/network/supabase_service.dart';

class UnlockPublicStoryUseCase {
  final _client = SupabaseService.client;

  Future<void> execute(Map<String, dynamic> story) async {
    final price = story['price_credits'] as int;
    final storyId = story['id'];
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('يجب تسجيل الدخول لإتمام عملية الشراء.');
    }

    try {
      // 1. الخصم
      await SupabaseService.deductCredits(
        price,
        'Purchase public story: $storyId',
      );

      // 2. تسجيل الشراء
      await _client.from('purchases').insert({
        'user_id': userId,
        'story_id': storyId,
        'unlock_type': 'access',
        'credits_paid': price,
      });
    } catch (e) {
      if (e.toString().contains('Insufficient credits')) {
        throw Exception('رصيدك غير كافٍ. يرجى شحن الجواهر.');
      }
      throw Exception('فشلت عملية فتح القصة: $e');
    }
  }
}

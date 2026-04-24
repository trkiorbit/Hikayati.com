import 'package:flutter/foundation.dart';
import 'package:hikayati/features/avatar_lab/services/avatar_service.dart';
import 'package:hikayati/core/network/supabase_service.dart';

class SaveAvatarUseCase {
  final AvatarService _avatarService = AvatarService();

  static const int avatarCost = 20;

  /// القائمة الثابتة للأزياء — لا AI ولا خصم
  static const List<Map<String, String>> costumes = [
    {'ar': 'ملابس عادية', 'en': 'casual colorful clothes'},
    {'ar': 'فارس', 'en': 'knight armor with shield'},
    {'ar': 'بطل خارق', 'en': 'superhero costume with cape'},
    {'ar': 'مستكشف', 'en': 'explorer outfit with hat and backpack'},
    {'ar': 'رائد فضاء', 'en': 'astronaut suit'},
    {'ar': 'أمير', 'en': 'royal prince outfit with crown'},
  ];

  /// حفظ أفاتار جديد — الترتيب الذري:
  /// 1) تحقق من الرصيد (>= 20) لمنع الخصم الفاشل
  /// 2) احفظ الأفاتار في profiles
  /// 3) اخصم avatarCost
  /// 4) إن فشل الخصم بعد الحفظ → rollback: احذف الأفاتار
  Future<void> execute(Map<String, dynamic> avatarData) async {
    final client = SupabaseService.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('يجب تسجيل الدخول لحفظ البطل.');
    }

    // 1) تحقق من الرصيد مقدّمًا
    final profile = await client
        .from('profiles')
        .select('credits')
        .eq('user_id', userId)
        .maybeSingle();
    final currentCredits = (profile?['credits'] as int?) ?? 0;
    if (currentCredits < avatarCost) {
      throw Exception(
          'رصيدك ($currentCredits ⭐) غير كافٍ. تحتاج $avatarCost ⭐ لإنشاء البطل.');
    }

    final face = avatarData['face_description'] ?? 'young character';
    final clothes = avatarData['current_clothes'] ?? 'colorful clothes';
    final dataToSave = Map<String, dynamic>.from(avatarData);
    dataToSave['prompt_snippet'] =
        '3D Pixar style, $face, wearing $clothes, clean white background, high quality';

    // 2) احفظ الأفاتار أولاً
    await _avatarService.saveAvatarToProfile(dataToSave);

    // 3) اخصم الرصيد
    try {
      await SupabaseService.deductCredits(avatarCost, 'إنشاء بطل جديد');
    } catch (e) {
      // 4) rollback: احذف الأفاتار المحفوظ
      debugPrint('[SaveAvatar] deduct failed, rolling back avatar: $e');
      try {
        await client.from('profiles').update({
          'avatar_profile_summary': null,
        }).eq('user_id', userId);
      } catch (rollbackError) {
        debugPrint('[SaveAvatar] rollback failed: $rollbackError');
      }
      throw Exception('تعذّر خصم الرصيد: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  /// اختيار زي ثابت — بدون خصم، بدون AI
  Future<Map<String, dynamic>> selectCostume(
    Map<String, dynamic> currentAvatar,
    String costumeEn,
  ) async {
    final updatedData = Map<String, dynamic>.from(currentAvatar);
    updatedData['current_clothes'] = costumeEn;

    final face = updatedData['face_description'] ?? 'young character';
    updatedData['prompt_snippet'] =
        '3D Pixar style, $face, wearing $costumeEn, clean white background, high quality';

    await _avatarService.saveAvatarToProfile(updatedData);
    return updatedData;
  }
}

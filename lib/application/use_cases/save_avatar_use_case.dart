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

  /// حفظ أفاتار جديد — يخصم avatarCost ويبني prompt_snippet
  Future<void> execute(Map<String, dynamic> avatarData) async {
    final face = avatarData['face_description'] ?? 'young character';
    final clothes = avatarData['current_clothes'] ?? 'colorful clothes';

    final dataToSave = Map<String, dynamic>.from(avatarData);
    dataToSave['prompt_snippet'] =
        '3D Pixar style, $face, wearing $clothes, clean white background, high quality';

    try {
      await SupabaseService.deductCredits(avatarCost, 'إنشاء بطل جديد');
      await _avatarService.saveAvatarToProfile(dataToSave);
    } catch (e) {
      throw Exception('تعذر حفظ البطل: $e');
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

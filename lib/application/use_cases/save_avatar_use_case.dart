import 'package:hikayati/features/avatar_lab/services/avatar_service.dart';

class SaveAvatarUseCase {
  final AvatarService _avatarService = AvatarService();

  Future<void> execute(Map<String, dynamic> avatarData) async {
    try {
      await _avatarService.saveAvatarToProfile(avatarData);
    } catch (e) {
      throw Exception('تعذر حفظ البطل: $e');
    }
  }
}

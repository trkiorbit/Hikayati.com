import 'package:flutter/foundation.dart';

/// === PromptBuilderService ===
/// المسؤول الوحيد عن هندسة وصف الصور (Prompt Engineering).
/// يمنع إرسال نصوص خام إلى مولد الصور.
class PromptBuilderService {
  /// بناء الـ Prompt النهائي
  static String buildPrompt({
    required String sceneDescription,
    required String imageStyle,
    Map<String, dynamic>? avatarData,
  }) {
    // 1. تنظيف المدخلات
    final cleanScene = sceneDescription.trim();
    final cleanStyle = imageStyle.trim();

    // 2. المسار الأول: بدون أفاتار
    if (avatarData == null) {
      final prompt = '$cleanScene. Style: $cleanStyle.';
      debugPrint('[PromptBuilder] 🟢 Mode: No Avatar -> $prompt');
      return prompt;
    }

    // 3. المسار الثاني: مع أفاتار (حقن الهوية)
    // استخراج البيانات مع دعم المسميات الجديدة والقديمة (Fallback)
    final face = avatarData['face_description'] ?? 
                 avatarData['distinguishingFeatures'] ?? 
                 '';
                 
    final body = avatarData['body_traits'] ?? '';
    
    // الملابس: الأولوية للملابس الحالية (current_clothes) ثم الملابس المسجلة في الأفاتار
    final clothes = avatarData['current_clothes'] ?? 
                    avatarData['clothingStyleAndColors'] ?? 
                    'colorful casual clothes'; // قيمة افتراضية أقوى

    // التأكد من عدم وجود قيم فارغة تؤثر على الـ Prompt
    final age = avatarData['age']?.toString() ?? 'child';
    final gender = avatarData['gender'] ?? 'child';
    final skin = avatarData['skinTone'] != null ? '${avatarData['skinTone']} skin' : '';
    final hair = avatarData['hairStyleAndColor'] ?? '';

    // تجميع الهوية (Identity Block)
    final List<String> identityParts = [
      '$age $gender',
      if (face.isNotEmpty) face,
      if (body.isNotEmpty) body,
      if (skin.isNotEmpty) skin,
      if (hair.isNotEmpty) hair,
    ];
    final identityString = identityParts.join(', ');

    // بناء الـ Prompt النهائي حسب المعادلة المطلوبة
    // Format: scene_description. Main character: [face+traits]. Wearing: [clothes]. Style: [style]. Same character across all scenes.
    final finalPrompt = 
        '$cleanScene. Main character: $identityString. Wearing: $clothes. Style: $cleanStyle. Same character across all scenes.';

    debugPrint('[PromptBuilder] 🧬 Mode: Avatar Identity -> $finalPrompt');
    return finalPrompt;
  }
}
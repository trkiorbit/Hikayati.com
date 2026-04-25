/// Hikayati Visual Style Guide — مرحلة 5.1
///
/// مرجع موحد للـ prompt البصري لجميع قصص المستخدم.
/// الهدف: رفع جودة الصور مع نفس مزود Pollinations Flux، بدون تغيير المسار.
///
/// **استخدامها فقط في توليد قصص المستخدم العادية.**
/// ممنوع استخدامها مع: Avatar Lab, Voice Clone, Public Library.
///
/// طريقة العمل:
/// ```dart
/// final finalPrompt = HikayatiVisualStyleGuide.buildPrompt(
///   scenePrompt: '...',           // النص الأصلي للمشهد
///   characterDescription: '...',  // وصف ثابت للبطل (اختياري)
/// );
/// ```
library;

class HikayatiVisualStyleGuide {
  /// إصدار الدليل — نزيده عند أي تغيير حقيقي في النمط.
  static const String version = '1.0.0';

  /// نمط بصري إيجابي ثابت يُلصق بكل prompt.
  /// مكتوب بإنجليزية مكثفة لأن Pollinations يفهمها أحسن.
  static const String _positiveStyle =
      'cinematic 3D animated children\'s storybook illustration, '
      'Pixar-quality rendering, soft warm magical lighting, '
      'vibrant colors, vertical mobile composition, '
      'consistent character design, full body visible, '
      'natural anatomy, natural hands with five fingers, '
      'high detail, masterpiece quality';

  /// رموز سلبية لمنع التشوّهات الشائعة في صور الأطفال.
  /// Pollinations يدعم negative prompts عبر الكلمات الموجبة المعكوسة (limited).
  /// نضيفها كنص قابل للقراءة من المولّد.
  static const String _negativeStyle =
      'no deformed hands, no extra fingers, no missing fingers, '
      'no distorted faces, no different ages between scenes, '
      'no text, no watermarks, no logos, '
      'no scary imagery, no dark horror tones, '
      'no extra limbs, no twisted body parts';

  /// يبني prompt نهائي:
  ///   [Character Lock] + [Scene Prompt] + [Style] + [Negative]
  ///
  /// [scenePrompt] إجباري — الوصف الأصلي للمشهد.
  /// [characterDescription] اختياري — يُحقن في البداية لتثبيت الشخصية.
  static String buildPrompt({
    required String scenePrompt,
    String? characterDescription,
  }) {
    final parts = <String>[];

    if (characterDescription != null && characterDescription.trim().isNotEmpty) {
      parts.add('Main character: ${characterDescription.trim()}');
    }

    parts.add(scenePrompt.trim());
    parts.add(_positiveStyle);
    parts.add(_negativeStyle);

    return parts.join('. ');
  }

  /// Helper: يقطع الـ prompt ليبقى ضمن حد آمن (Pollinations يقبل ~2000 حرف).
  /// نحتفظ بـ 1400 لأمان URL encoding.
  static String trimToSafeLength(String prompt, {int maxLength = 1400}) {
    if (prompt.length <= maxLength) return prompt;
    return '${prompt.substring(0, maxLength).trim()}…';
  }
}

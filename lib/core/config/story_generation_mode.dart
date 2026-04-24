/// ═══════════════════════════════════════════════════════════════════
/// Story Generation Mode Configuration
/// ═══════════════════════════════════════════════════════════════════
///
/// يتحكم هذا الملف في جودة وعدد المشاهد لتوليد القصة.
///
/// ⚠️⚠️⚠️ الوضع الافتراضي للتطبيق: [StoryGenerationMode.userDefault]
/// لا تُغيّر [currentMode] إلا مؤقتاً أثناء إنتاج قصص المكتبة العامة،
/// ثم أعِدها فوراً إلى `userDefault` قبل commit/push.
///
/// الاستخدام لإنتاج قصص المكتبة العامة:
/// 1. المطوّر يفتح هذا الملف
/// 2. يُغيّر `currentMode` إلى `publicLibraryProduction`
/// 3. يبني التطبيق على جهازه الخاص (لا يُنشر release)
/// 4. يدخل بحسابه صاحب الكريدت العالي
/// 5. يُنتج القصص (بدون أفاتار وبدون صوت مستنسخ — مفروض تلقائياً)
/// 6. ينقلها يدوياً إلى `public_stories` عبر Supabase Dashboard
/// 7. يُعيد `currentMode` إلى `userDefault` قبل أي release للمستخدمين
/// ═══════════════════════════════════════════════════════════════════

enum StoryGenerationMode {
  /// الوضع العادي للمستخدمين — 5 مشاهد، تكلفة محسوبة، جودة متوازنة
  userDefault,

  /// وضع إنتاج المكتبة العامة — 6 مشاهد، جودة سينمائية، للمطوّر فقط
  ///
  /// القواعد في هذا الوضع:
  /// - لا أفاتار (مفروض بـ [blocksAvatar])
  /// - لا صوت مستنسخ (مفروض بـ [blocksClonedVoice])
  /// - صوت عادي فقط (Pollinations TTS)
  /// - جودة بصرية + سردية أعلى بكثير
  publicLibraryProduction,
}

class StoryGenerationConfig {
  // ─────────────────────────────────────────────────────────────────
  // 🔒 الوضع الحالي — يجب أن يكون userDefault في كل release
  // ─────────────────────────────────────────────────────────────────
  static const StoryGenerationMode currentMode = StoryGenerationMode.userDefault;
  // ─────────────────────────────────────────────────────────────────

  /// عدد المشاهد في القصة
  static int get sceneCount {
    switch (currentMode) {
      case StoryGenerationMode.userDefault:
        return 5;
      case StoryGenerationMode.publicLibraryProduction:
        return 6;
    }
  }

  /// عدد الأسطر لكل مشهد (نصي — يُحقن في prompt)
  static String get linesPerScene {
    switch (currentMode) {
      case StoryGenerationMode.userDefault:
        return 'من سطرين إلى أربعة أسطر';
      case StoryGenerationMode.publicLibraryProduction:
        return 'من ثلاثة إلى خمسة أسطر، نص غني دون إطالة مملة';
    }
  }

  /// توجيهات الجودة للـ system prompt
  static String get qualityDirective {
    switch (currentMode) {
      case StoryGenerationMode.userDefault:
        return '''
اكتب قصة عربية قصيرة ومتوازنة مناسبة للأطفال:
- لغة عربية فصيحة وسهلة
- بداية جذابة، تصاعد واضح، نهاية مُرضية
- لا عنف قاسٍ ولا رعب ولا محتوى مقلق
- كل مشهد يحمل حدثاً بصرياً مميزاً
''';
      case StoryGenerationMode.publicLibraryProduction:
        return '''
اكتب قصة أصلية بجودة إنتاج سينمائي للمكتبة العامة بمعايير احترافية عالية:

البنية السردية:
- افتتاحية جذابة تمسك الطفل من أول جملة
- تصاعد واضح في الأحداث يبني التشويق
- مشكلة أو تحدٍ واضح
- حل إبداعي عبر شجاعة أو ذكاء أو لطف البطل
- نهاية مبهجة أو مؤثرة تترك أثراً إيجابياً

اللغة:
- عربية فصحى سهلة ومناسبة للأطفال
- بلاغة بسيطة بدون تعقيد
- إيقاع سردي جميل
- جمل قصيرة غنية بالمعنى
- لا خلط لغات، لا كلمات إنجليزية في النص العربي

المحتوى:
- درس تربوي ناعم مدمج في الأحداث (شجاعة / لطف / صداقة / ذكاء / أمانة) — بدون وعظ مباشر
- خيال بصري قوي في كل مشهد
- لا عنف قاسٍ ولا رعب
- لا تذكر كلمة "مشهد 1" أو "مشهد 2" في النص النهائي
- كل مشهد قصير لكنه غني

ملاحظات مهمة:
- القصة يمكن أن تكون مستوحاة من موروث حكايات الأطفال لكن بصياغة أصلية خاصة
- لا تنسخ من أعمال حديثة أو علامات تجارية
- لا تستخدم اسم طفل محدد كبطل — استخدم صفة عامة (الفتاة الذكية، الولد الشجاع، الأرنب الصغير...)
''';
    }
  }

  /// إضافة لكل image prompt لرفع جودة الصور في وضع المكتبة العامة
  /// تُضاف في نهاية الـ prompt بعد scene_description
  static String get imagePromptEnhancer {
    switch (currentMode) {
      case StoryGenerationMode.userDefault:
        return ''; // لا إضافة — الـ style الحالي كافٍ
      case StoryGenerationMode.publicLibraryProduction:
        return ', cinematic 3D storybook illustration, high detail, warm magical lighting, '
            'premium children book quality, rich environment, consistent character style, '
            'safe for children, no text, no logos, no watermark, Arabic fantasy storytelling feeling';
    }
  }

  /// نمط السرد
  static String get narrativeStyle {
    switch (currentMode) {
      case StoryGenerationMode.userDefault:
        return 'balanced_premium';
      case StoryGenerationMode.publicLibraryProduction:
        return 'cinematic_public_library_premium';
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // قيود على استخدام الأفاتار والصوت المستنسخ في وضع المكتبة العامة
  // ─────────────────────────────────────────────────────────────────

  /// هل يمنع هذا الوضع استخدام الأفاتار؟
  /// وضع المكتبة العامة يمنعه لأن القصص للعرض للجمهور (ليست مخصصة لطفل واحد)
  static bool get blocksAvatar {
    switch (currentMode) {
      case StoryGenerationMode.userDefault:
        return false;
      case StoryGenerationMode.publicLibraryProduction:
        return true;
    }
  }

  /// هل يمنع هذا الوضع استخدام الصوت المستنسخ؟
  /// وضع المكتبة العامة يمنعه لأن القصص تُعرض بالصوت العادي للجمهور
  static bool get blocksClonedVoice {
    switch (currentMode) {
      case StoryGenerationMode.userDefault:
        return false;
      case StoryGenerationMode.publicLibraryProduction:
        return true;
    }
  }

  /// للتحقق في runtime — هل نحن في وضع إنتاج المكتبة العامة؟
  static bool get isPublicLibraryProductionMode =>
      currentMode == StoryGenerationMode.publicLibraryProduction;
}

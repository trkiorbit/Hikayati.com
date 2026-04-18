import 'package:flutter/foundation.dart';

/// === ContentMonitorService ===
/// يفحص المحتوى قبل العرض/الإرسال للصورة.
/// يستخدم مطابقة كلمة كاملة فقط (full-word matching) لتجنب الإيجابيات الكاذبة.
class ContentMonitorService {
  static final List<String> _blockedKeywords = [
    // English — explicit full words only
    'blood', 'kill', 'death', 'naked', 'nude', 'sex', 'violence',
    'murder', 'gore', 'abuse',
    // Arabic — كلمات كاملة فقط
    'دم', 'قتل', 'موت', 'عري', 'جنس', 'عنف', 'اغتصاب',
  ];

  /// يعيد true إذا كان المحتوى آمناً.
  /// يستخدم مطابقة حدود الكلمة (word boundary) لتجنب الإيجابيات الكاذبة.
  /// مثال: "killed" لا تُطابق "kill" كـ partial substring إلا إذا كانت كلمة مستقلة.
  static bool isContentSafe(String content) {
    if (content.trim().isEmpty) return true;

    final lowerContent = content.toLowerCase();

    for (final word in _blockedKeywords) {
      // نبحث عن الكلمة كحدود مستقلة
      final pattern = RegExp(
        r'(^|[\s\.,!?;:()\[\]"\u0600-\u0610])' +
            RegExp.escape(word) +
            r'([\s\.,!?;:()\[\]"\u0600-\u0610]|$)',
        caseSensitive: false,
      );
      if (pattern.hasMatch(lowerContent)) {
        debugPrint('[ContentMonitor] 🚫 كلمة محظورة (مطابقة كاملة): "$word"');
        return false;
      }
    }
    return true;
  }
}

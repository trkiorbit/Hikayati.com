import 'package:flutter/foundation.dart';

/// === ContentMonitorService ===
/// المراقب البسيط (Content Monitor) الذي ينص عليه الدستور
/// يفحص أي محتوى قبل العرض أو الإرسال للصورة للتأكد من خلوه من الانتهاكات السيئة.
class ContentMonitorService {
  // قائمة أولية وبسيطة للكلمات الممنوعة (للتوضيح والأساس الأمني)
  static final List<String> _blockedKeywords = [
    'blood', 'kill', 'death', 'naked', 'nude', 'sex', 'violence', 'murder', 'gun', 'weapon',
    'دم', 'قتل', 'موت', 'عري', 'جنس', 'عنف', 'سلاح', 'مسدس', 'سكين'
  ];

  /// يعيد true إذا كان المحتوى آمناً، و false إذا وجد كلمات محظورة.
  static bool isContentSafe(String content) {
    if (content.trim().isEmpty) return true;
    
    final lowerContent = content.toLowerCase();
    for (final word in _blockedKeywords) {
      if (lowerContent.contains(word)) {
        debugPrint('[ContentMonitor] 🚫 تم اكتشاف كلمة محظورة: $word');
        return false;
      }
    }
    return true;
  }
}

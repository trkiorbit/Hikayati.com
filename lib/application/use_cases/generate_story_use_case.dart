/// === GenerateStoryUseCase ===
/// Application Layer — Use Case
///
/// يمثّل هذا الكلاس الحد الفاصل بين شاشات Flutter وخدمات الذكاء الاصطناعي.
/// LAW 1 (من HIKAYATI_AGENT_MASTER_SPEC.md):
///   "UI does not generate stories. Screens collect input, trigger actions, show loading states."
///
/// الاستخدام الصحيح:
///   - تستدعي هذه الـ use case من IntroCinematicScreen (أو أي screen تحتاج للتوليد)
///   - النتيجة storyData تُمرر بالكامل إلى CinemaScreen عبر router
///   - لا يجوز استدعاء UnifiedEngine.generateStory() من أي شاشة مباشرة

import 'package:flutter/foundation.dart';
import 'package:hikayati/features/story_engine/services/unified_engine.dart';
import 'package:hikayati/core/network/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GenerateStoryUseCase {
  /// تنفيذ عملية توليد القصة الكاملة
  ///
  /// [requestData] — خريطة تحتوي على:
  ///   - heroName: String
  ///   - heroAge: String
  ///   - storyStyle: String
  ///   - imageStyle: String
  ///   - heroVisualDescription: String (اختياري — عند استخدام الأفاتار)
  ///   - useAvatar: bool
  ///
  /// تعيد: Map<String, dynamic> يحتوي على:
  ///   - title: String
  ///   - scenes: List<Map<String, dynamic>> (text + imageUrl)
  ///   - coverImage: String
  ///   - id: String? (إذا حُفظ في Supabase)
  ///
  /// في حال حدوث خطأ: تعيد storyData مع scenes احتياطية (fallback)
  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> requestData,
    {String? voice}
  ) async {
    debugPrint('[UseCase] GenerateStoryUseCase.execute() — بدء التوليد');
    
    // حساب التكلفة الجديدة: الأساسي 20
    int totalCost = 20;
    if (requestData['useAvatar'] == true) totalCost += 10;
    if (voice == 'cloned') totalCost += 10;

    // خصم الكريدت أولاً
    try {
      await SupabaseService.deductCredits(totalCost, 'توليد قصة سينمائية');
    } catch (e) {
      throw Exception('الرصيد غير كافٍ. تحتاج إلى $totalCost جواهر لتوليد هذه القصة.');
    }
    
    // جلب الأفاتار المخزن إذا طلبه المستخدم بوضع useAvatar = true
    if (requestData['useAvatar'] == true) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        final profileRes = await Supabase.instance.client.from('profiles').select('avatar_profile_summary').eq('user_id', userId as Object).single();
        final avatarData = profileRes['avatar_profile_summary'];
        
        if (avatarData != null) {
          debugPrint('[UseCase] تم العثور على أفاتار محفوظ، سيتم دمج بصمته في القصة.');
          
          final desc = 'Gender: ${avatarData['gender']}, Hair: ${avatarData['hairStyleAndColor']}, Skin: ${avatarData['skinTone']}, Clothing: ${avatarData['clothingStyleAndColors']}';
          requestData['heroVisualDescription'] = desc;
          requestData['avatarData'] = avatarData; // حفظ الهوية الكاملة ليمررها الـ Prompt Builder
          
          if (avatarData['name'] != null) requestData['heroName'] = avatarData['name'];
          if (avatarData['age'] != null) requestData['heroAge'] = avatarData['age'].toString();
        } else {
          requestData['useAvatar'] = false; // إلغاء التفعيل إن لم يجد أفاتار بالخطأ
        }
      } catch (e) {
        debugPrint('[UseCase] تحذير: فشل جلب الأفاتار: $e');
      }
    }

    debugPrint('[UseCase] heroName: ${requestData['heroName']}');
    debugPrint('[UseCase] storyStyle: ${requestData['storyStyle']}');
    debugPrint('[UseCase] useAvatar: ${requestData['useAvatar']}');
    debugPrint('[UseCase] Total Cost Paid: $totalCost credits');

    try {
      final storyData = await UnifiedEngine.generateStory(requestData);
      debugPrint('[UseCase] اكتمل التوليد — عدد المشاهد: ${(storyData['scenes'] as List?)?.length ?? 0}');
      return storyData;
    } catch (e, stack) {
      debugPrint('[UseCase] خطأ في التوليد: $e\n$stack');
      rethrow; // نُعيد الرمي ليتعامل معه caller بشكل صحيح
    }
  }
}

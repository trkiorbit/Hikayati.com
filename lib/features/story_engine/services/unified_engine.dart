/// كلاس المحرك الموحد UnifiedEngine
/// مسؤول عن توليد القصة (نص + صور) بناءً على بيانات البطل
/// يستخدم API Pollinations لتوليد النص والصور
/// جميع الخطوات موثقة بالتعليقات العربية

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hikayati/core/network/supabase_service.dart';
import 'package:hikayati/features/story_engine/services/prompt_builder_service.dart';
import 'package:hikayati/features/story_engine/services/content_monitor_service.dart';

class UnifiedEngine {
  /// دالة توليد القصة
  /// تستقبل بيانات البطل وتعيد مشاهد القصة (نص + صورة)
  static Future<Map<String, dynamic>> generateStory(
    Map<String, dynamic> requestData,
  ) async {
    // جلب مفاتيح Pollinations من ملف البيئة (نص + صور)
    final String textApiKey = dotenv.env['POLLINATIONS_TEXT_API_KEY'] ?? '';
    final String imageApiKey = dotenv.env['POLLINATIONS_IMAGE_API_KEY'] ?? '';

    // طباعة تشخيصية آمنة للتأكد من حالة المفتاح قبل الاتصال
    debugPrint('--- [Engine Diagnostics] ---');
    debugPrint('[Engine] Text Key Exists: ${textApiKey.isNotEmpty}');
    debugPrint('[Engine] Image Key Exists: ${imageApiKey.isNotEmpty}');
    debugPrint('----------------------------');

    try {
      debugPrint('[Engine] بدء توليد النص...');
      // استخلاص البيانات من الطلب مع قيم افتراضية
      final String heroName = requestData['heroName'] ?? 'البطل';
      final String heroAge = requestData['heroAge']?.toString() ?? '7';
      final String storyStyle = requestData['storyStyle'] ?? 'مغامرة';
      final String imageStyle = requestData['imageStyle'] ?? 'كرتوني';
      final bool useAvatar = requestData['useAvatar'] == true;

      // بناء prompt دقيق وموجه لإرجاع JSON مع تعليمات قاسية للحفاظ على القصة
      final String systemPrompt =
          '''
      أنت مؤلف قصص أطفال محترف ومبدع.
      الهدف: كتابة قصة تناسب طفل اسمه "$heroName" وعمره $heroAge سنوات، بأسلوب "$storyStyle".
      مهمتك:
      قم بصياغة استجابة بصيغة JSON Object يحتوي على مفتاحين:
      1. "title": عنوان ابتكاري وجذاب للقصة (نص قصير).
      2. "scenes": مصفوفة (Array) من 3 مشاهد فقط.
      كل مشهد يحتوي على:
      1. "text_ar": نص المشهد بالعربية (سطرين كحد أقصى).
      2. "scene_description_en": وصف بصري دقيق باللغة الإنجليزية للأفعال والمكان والبيئة في المشهد (مثلاً: A young child running in a magical glowing forest). لا تصف الملامح أو الملابس الثابتة للشخصية، فقط اذكر الحدث.
      
      يجب أن يكون الرد JSON فقط، بدون أي نص إضافي.
      ''';

      // الاتصال بـ API Pollinations المحدث (متوافق مع OpenAI)
      final response = await http.post(
        Uri.parse('https://gen.pollinations.ai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          if (textApiKey.isNotEmpty)
            'Authorization': 'Bearer $textApiKey', // حقن مفتاح النص
        },
        body: jsonEncode({
          "model": "openai", // استخدام أسرع وأفضل موديل للنصوص
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": "اكتب القصة الآن."},
          ],
          "response_format": {"type": "json_object"},
        }),
      );

      debugPrint('[Engine] تم استلام استجابة النص: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('[Engine] فشل توليد النص: ${response.body}');
        return _fallbackStory('تعذر توليد القصة من المصدر.');
      }

      // استخراج محتوى الرسالة من استجابة OpenAI القياسية
      List<dynamic> scenesRaw = [];
      String generatedTitle = 'قصة $heroName الممتعة';

      try {
        final dynamic fullResponse = jsonDecode(response.body);
        final String content = fullResponse['choices'][0]['message']['content'];
        final dynamic decodedJson = jsonDecode(content);

        if (decodedJson is Map) {
          if (decodedJson.containsKey('title')) {
            generatedTitle = decodedJson['title'];
          }
          if (decodedJson.containsKey('scenes')) {
            scenesRaw = decodedJson['scenes'];
          } else {
            // محاولة إيجاد أي مصفوفة
            for (var value in decodedJson.values) {
              if (value is List) {
                scenesRaw = value;
                break;
              }
            }
          }
        }

        if (scenesRaw.isEmpty) {
          debugPrint('[Engine] صيغة الاستجابة غير صحيحة.');
          return _fallbackStory('صيغة القصة المستلمة غير صحيحة.');
        }
      } catch (e) {
        debugPrint('[Engine] خطأ في تحليل JSON: $e');
        return _fallbackStory('حدث خطأ أثناء تحليل القصة: $e');
      }

      debugPrint('[Engine] بدء توليد روابط الصور...');
      final Random random = Random();
      // السر هنا: نستخدم بذرة عشوائية واحدة لكل القصة للحفاظ على النمط والشخصية وعدم تناقض التفاصيل
      final int storySeed = random.nextInt(1000000); 
      final List<Map<String, dynamic>> scenes = [];

      for (var scene in scenesRaw) {
        final String text = scene['text_ar'] ?? 'مشهد بدون نص.';
        final String sceneDescEn =
            scene['scene_description_en'] ?? scene['image_prompt_en'] ?? 'A scene';
        
        // ✅ الربط الإجباري: كل الصور تمر عبر PromptBuilderService
        final String finalImagePrompt = PromptBuilderService.buildPrompt(
          sceneDescription: sceneDescEn, 
          imageStyle: imageStyle, 
          avatarData: useAvatar ? requestData['avatarData'] : null,
        );

        // مراقبة المحتوى (Content Monitor) - للصور والنصوص
        String safePrompt = finalImagePrompt;
        if (!ContentMonitorService.isContentSafe(finalImagePrompt)) {
           debugPrint('[Monitor] 🚫 تم اكتشاف محتوى غير آمن في وصف الصورة. سيتم استخدام بديل آمن.');
           safePrompt = 'A beautiful safe child-friendly scene in $imageStyle style.';
        }

        String safeText = text;
        if (!ContentMonitorService.isContentSafe(text)) {
           debugPrint('[Monitor] 🚫 تم اكتشاف محتوى غير آمن في نص القصة الأجنبي/العربي.');
           safeText = 'مشهد آمن ولطيف.';
        }

        // تنظيف الـ Prompt النهائي من الرموز المعقدة لمنع الخطأ 400
        final String ultraSafePrompt = safePrompt.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim();

        // بناء رابط الصورة باستخدام النطاق وتحديد موديل flux واستخدام نفس (storySeed) لجميع المشاهد
        // إصلاح 401: التأكد من صيغة المفتاح أو إزالته إذا كان فارغاً
        final String keyParam = imageApiKey.isNotEmpty ? '&key=$imageApiKey' : '';
        
        // السلاح السري للاتساق: إضافة الصورة المرجعية إذا كان الأفاتار مفعلاً
        String referenceImageParam = '';
        if (useAvatar && requestData['avatarData'] != null) {
          final refUrl = requestData['avatarData']['reference_image_url'];
          if (refUrl != null && refUrl.toString().isNotEmpty) {
            referenceImageParam = '&image=${Uri.encodeComponent(refUrl)}';
          }
        }
        
        final String imageUrl =
            'https://gen.pollinations.ai/image/${Uri.encodeComponent(ultraSafePrompt)}?model=flux&width=1024&height=512&nologo=true&seed=${storySeed + scenes.length}$keyParam$referenceImageParam';
            
        scenes.add({'text': safeText, 'imageUrl': imageUrl});
      }

      debugPrint('[Engine] تم توليد المشاهد بنجاح.');

      final String coverImage = scenes.isNotEmpty ? scenes.first['imageUrl'] : '';
      final storyData = {
        'title': generatedTitle,
        'scenes': scenes,
        'coverImage': coverImage,
      };

      // إجراء الحفظ الفعلي في Supabase
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          // ✅ Batch 2 Fix: ضمان وجود profile قبل حفظ القصة (يمنع خطأ stories_user_id_fkey)
          await SupabaseService.ensureProfileExists(userId);

          final savedResponse = await Supabase.instance.client.from('stories').insert({
            'user_id': userId,
            'title': generatedTitle,
            'language': 'ar',
            'scenes_json': scenes,
            'cover_image': coverImage,
            'is_public': false,
          }).select().single();
          
          storyData['id'] = savedResponse['id'];
          debugPrint('[Engine] ✅ تمت عملية الحفظ في Supabase بنجاح، رقم القصة: ${savedResponse['id']}');
        } else {
          debugPrint('[Engine] تحذير: لا يوجد مستخدم مسجل لحفظ القصة.');
        }
      } catch (dbError) {
        debugPrint('[Engine] ❌ خطأ في حفظ القصة بقاعدة البيانات: $dbError');
      }

      return storyData;
    } catch (e, stack) {
      debugPrint('[Engine] خطأ غير متوقع: $e\n$stack');
      return _fallbackStory('حدث خطأ غير متوقع أثناء توليد القصة.');
    }
  }

  /// قصة احتياطية (Fallback) في حال حدوث خطأ
  static Map<String, dynamic> _fallbackStory(String errorMsg) {
    final String imageApiKey = dotenv.env['POLLINATIONS_IMAGE_API_KEY'] ?? '';
    return {
      'scenes': [
        {
          'text': 'عذرًا، لم نستطع توليد القصة. $errorMsg',
          'imageUrl':
              'https://gen.pollinations.ai/image/${Uri.encodeComponent('A sad robot trying to write a story, error on screen, cartoon style')}?model=flux&width=1024&height=512&nologo=true&seed=12345${imageApiKey.isNotEmpty ? '&key=$imageApiKey' : ''}',
        },
      ],
    };
  }
}

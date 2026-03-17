/// كلاس المحرك الموحد UnifiedEngine
/// مسؤول عن توليد القصة (نص + صور) بناءً على بيانات البطل
/// يستخدم API Pollinations لتوليد النص والصور
/// جميع الخطوات موثقة بالتعليقات العربية

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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

      // بناء prompt دقيق وموجه لإرجاع JSON
      final String systemPrompt =
          '''
      أنت مؤلف قصص أطفال محترف ومبدع.
      الهدف: كتابة قصة تناسب طفل اسمه "$heroName" وعمره $heroAge سنوات، بأسلوب "$storyStyle".
      مهمتك:
      قم بصياغة استجابة بصيغة JSON Object يحتوي على مفتاح واحد فقط وهو "scenes".
      قيمة "scenes" يجب أن تكون مصفوفة (Array) تحتوي على 3 مشاهد فقط.
      كل مشهد يجب أن يكون عبارة عن كائن (Object) يحتوي على مفتاحين فقط:
      1. "text_ar": نص المشهد باللغة العربية (سطرين كحد أقصى).
      2. "image_prompt_en": وصف بصري دقيق باللغة الإنجليزية لتوليد صورة المشهد. يجب أن يتضمن هذا الوصف دائماً ستايل الصورة التالي: "$imageStyle" وأن يكون متسقاً مع شخصية ਬطل القصة.
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
      try {
        final dynamic fullResponse = jsonDecode(response.body);
        final String content = fullResponse['choices'][0]['message']['content'];
        final dynamic decodedJson = jsonDecode(content);

        if (decodedJson is Map && decodedJson.containsKey('scenes')) {
          scenesRaw = decodedJson['scenes'];
        } else if (decodedJson is Map) {
          for (var value in decodedJson.values) {
            if (value is List) {
              scenesRaw = value;
              break;
            }
          }
        }

        if (scenesRaw.isEmpty) {
          debugPrint('[Engine] صيغة الاستجابة غير صحيحة.');
          return _fallbackStory('صيغة القصة المستلمة غير صحيحة.');
        }
      } catch (e) {
        debugPrint('[Engine] خطأ في تحليل JSON: $e');
        return _fallbackStory('حدث خطأ أثناء تحليل القصة.');
      }

      debugPrint('[Engine] بدء توليد روابط الصور...');
      final Random random = Random();
      final List<Map<String, dynamic>> scenes = [];

      for (var scene in scenesRaw) {
        final String text = scene['text_ar'] ?? 'مشهد بدون نص.';
        final String imagePromptEn =
            scene['image_prompt_en'] ??
            'A children story scene in $imageStyle style.';
        // توليد رقم عشوائي لكل صورة لتجنب التكرار
        final int seed = random.nextInt(1000000);
        // بناء رابط الصورة باستخدام النطاق الجديد وتحديد موديل flux لجودة عالية
        final String imageUrl =
            'https://gen.pollinations.ai/image/${Uri.encodeComponent(imagePromptEn)}?model=flux&width=1024&height=512&nologo=true&seed=$seed${imageApiKey.isNotEmpty ? '&key=$imageApiKey' : ''}';
        scenes.add({'text': text, 'imageUrl': imageUrl});
      }

      debugPrint('[Engine] تم توليد المشاهد بنجاح.');
      return {'scenes': scenes};
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

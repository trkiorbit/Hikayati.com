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
      final String heroVisualDescription = requestData['heroVisualDescription'] ?? '';

      // بناء prompt دقيق وموجه لإرجاع JSON مع تعليمات قاسية للحفاظ على مظهر الشخصية
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
      2. "image_prompt_en": وصف بصري تفصيلي بالإنجليزية للمشهد.
      
      *** تعليمات قاطعة وإلزامية لصور المشاهد (CRITICAL DIRECTIVES): ***
      - البصمة البصرية الثابتة للبطل (يجب استخدامها حَرفياً): $heroVisualDescription
      - يجب أن تبدأ كل صورة بوصف الشخصية الرئيسية والستايل مثل:
      "A full-body shot of a $heroAge years old child named $heroName, [أدخل البصمة البصرية الثابتة هنا كما هي], in $imageStyle style..."
      - يجب أن يكون وصف ملامح الشخصية وملابسها متطابقاً بنسبة 100% في المشاهد الثلاثة (Consistency is Key).
      - دورك كحارس جودة (Quality Guard): يمنع رسم الجسد مقطوعاً أو إخفاء أطرافه. يجب أن تكون الشخصية كاملة ومرئية بوضوح في المنتصف. يمنع الخلط مع الكائنات (لا أرنب بشري مثلاً).
      - يجب أن تذكر ستايل الرسم "$imageStyle style" بوضوح في كل image_prompt.
      
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
        return _fallbackStory('حدث خطأ أثناء تحليل القصة.');
      }

      debugPrint('[Engine] بدء توليد روابط الصور...');
      final Random random = Random();
      // السر هنا: نستخدم بذرة عشوائية واحدة لكل القصة للحفاظ على النمط والشخصية وعدم تناقض التفاصيل
      final int storySeed = random.nextInt(1000000); 
      final List<Map<String, dynamic>> scenes = [];

      for (var scene in scenesRaw) {
        final String text = scene['text_ar'] ?? 'مشهد بدون نص.';
        final String imagePromptEn =
            scene['image_prompt_en'] ??
            'A children story scene in $imageStyle style.';
        
        // بناء رابط الصورة باستخدام النطاق وتحديد موديل flux واستخدام نفس (storySeed) لجميع المشاهد
        final String imageUrl =
            'https://gen.pollinations.ai/image/${Uri.encodeComponent(imagePromptEn)}?model=flux&width=1024&height=512&nologo=true&seed=$storySeed${imageApiKey.isNotEmpty ? '&key=$imageApiKey' : ''}';
        scenes.add({'text': text, 'imageUrl': imageUrl});
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
          final savedResponse = await Supabase.instance.client.from('stories').insert({
            'user_id': userId,
            'title': generatedTitle,
            'language': 'ar',
            'scenes_json': scenes,
            'cover_image': coverImage,
            'is_public': false,
          }).select().single();
          
          storyData['id'] = savedResponse['id'];
          debugPrint('[Engine] تمت عملية الحفظ في Supabase بنجاح، رقم القصة: ${savedResponse['id']}');
        } else {
          debugPrint('[Engine] تحذير: لا يوجد مستخدم مسجل لحفظ القصة.');
        }
      } catch (dbError) {
        debugPrint('[Engine] خطأ في حفظ القصة بقاعدة البيانات: $dbError');
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

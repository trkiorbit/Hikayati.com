import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class HakeemService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  /// دالة لتحليل صورة الطفل واستخراج خصائصه الثابتة بصيغة JSON
  static Future<Map<String, dynamic>> analyzeChildImage(File imageFile) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY غير موجود في ملف .env');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1, // لتقليل العشوائية وضمان دقة الاستخراج
      ),
    );

    final imageBytes = await imageFile.readAsBytes();
    final prompt = TextPart('''
أنت "حكيم"، خبير التحليل البصري في تطبيق حكواتي.
مهمتك تحليل صورة هذا الطفل بدقة لاستخراج وصف ثابت ومستقر يُستخدم لاحقاً كـ (جينات بصرية) لتوليد صور متسقة.
ركز جداً على: العمر التقريبي، الجنس، لون وشكل الشعر، لون البشرة، ولون وشكل الملابس الحالية.

يجب أن يكون الرد عبارة عن كائن JSON صالح وافٍ فقط بدون أي نص إضافي أو تنسيق Markdown، بالهيكل التالي:
{
  "age": "...", 
  "gender": "...",
  "skinTone": "...",
  "hairStyleAndColor": "...",
  "clothingStyleAndColors": "...",
  "distinguishingFeatures": "...",
  "promptSnippet": "وصف باللغة الإنجليزية يدمج كل هذه الصفات بأسلوب مباشر مثل: a 7 years old boy, short curly brown hair, wearing a red t-shirt and blue jeans, brown eyes, light brown skin"
}
''');

    final imagePart = DataPart('image/jpeg', imageBytes);

    try {
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      var rawText = response.text ?? '{}';
      // تنظيف النص في حال أعاد النظام تنسيق Markdown
      rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final data = json.decode(rawText);
      return data;
    } catch (e) {
      debugPrint('[HakeemService] Error analyzing image: $e');
      throw Exception('فشل حكيم في تحليل الصورة، تأكد من الاتصال وجرب مرة أخرى.');
    }
  }
}

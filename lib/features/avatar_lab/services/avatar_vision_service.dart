/// === AvatarVisionService ===
/// خدمة تحليل صور الأفاتار — مستقلة تماماً
///
/// تنتمي إلى: features/avatar_lab/services/
/// تُستدعى من: AvatarLabScreen فقط
///
/// LAW 4 (HIKAYATI_AGENT_MASTER_SPEC.md):
///   "Avatar belongs to its own domain — Avatar setup/editing belongs in AvatarLab"
/// LAW 5:
///   "Services are isolated — avatar/vision analysis service is separate"

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AvatarVisionService {
  /// تحليل صورة الطفل عبر Pollinations (OpenAI Compatible) واستخراج الملامح
  /// ثم إنتاج 4 روابط صور لخيارات الأفاتار.
  static Future<List<Map<String, dynamic>>> analyzeAndGenerateOptions(String imageUrl) async {
    String face = 'cute child face';
    String body = 'average build';
    String clothes = 'casual clothes';
    final textApiKey = dotenv.env['POLLINATIONS_TEXT_API_KEY'] ?? '';
    final imageApiKey = dotenv.env['POLLINATIONS_IMAGE_API_KEY'] ?? '';

    try {
      // 1. تحليل الصورة لاستخراج الهوية باستخدام الرابط وموديل gemini-fast للرؤية
      final visionResponse = await http.post(
        Uri.parse('https://gen.pollinations.ai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          if (textApiKey.isNotEmpty) 'Authorization': 'Bearer $textApiKey',
        },
        body: jsonEncode({
          "model": "gemini-fast",
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text", 
                  "text": "Analyze this child's image. Output ONLY a valid JSON object with these keys: 'face_description' (max 4 words), 'body_traits' (max 2 words), 'current_clothes' (max 4 words). Use simple English words, no punctuation."
                },
                {
                  "type": "image_url", 
                  "image_url": {"url": imageUrl}
                }
              ]
            }
          ],
          "response_format": { "type": "json_object" }
        }),
      );

      if (visionResponse.statusCode == 200) {
        final responseBody = jsonDecode(visionResponse.body);
        final content = responseBody['choices'][0]['message']['content'];
        final Map<String, dynamic> extractedData = jsonDecode(content);

        face = extractedData['face_description'] ?? face;
        body = extractedData['body_traits'] ?? body;
        clothes = extractedData['current_clothes'] ?? clothes;
      } else {
        debugPrint('[AvatarVision] فشل التحليل برمز: ${visionResponse.statusCode}. سيتم استخدام وصف افتراضي.');
      }
    } catch (e) {
      debugPrint('[AvatarVision] خطأ أثناء التحليل: $e');
    }
    
    // تنظيف النص من أي رموز قد تسبب خطأ 400 في الرابط
    final String cleanFace = face.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    final String cleanBody = body.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    final String cleanClothes = clothes.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();

    final String identityPrompt = "$cleanFace, $cleanBody. Wearing $cleanClothes. Pixar 3D style.";
    final String encodedPrompt = Uri.encodeComponent(identityPrompt);

    List<Map<String, dynamic>> options = [];
    
    // 2. توليد 4 صور مع دمج الصورة الأصلية كمرجع (&image=URL) لضمان الشبه الدقيق
    for (int i = 0; i < 4; i++) {
      final seed = DateTime.now().millisecondsSinceEpoch + i;
      
      final String keyParam = imageApiKey.isNotEmpty ? '&key=$imageApiKey' : '';
      final String referenceParam = '&image=${Uri.encodeComponent(imageUrl)}';
      
      final generatedImageUrl = "https://gen.pollinations.ai/image/$encodedPrompt?model=flux&width=1024&height=1024&nologo=true&seed=$seed$keyParam$referenceParam";

      options.add({
        "face_description": face,
        "body_traits": body,
        "current_clothes": clothes,
        "preview_url": generatedImageUrl,
        "reference_image_url": imageUrl, // حفظ الرابط الأصلي
        "seed": seed
      });
    }
    return options;
  }
}

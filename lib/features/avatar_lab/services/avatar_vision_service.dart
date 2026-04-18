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
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarVisionService {
  /// تحليل صورة الطفل واستخراج الوصف والترجمة للمراجعة
  static Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    String face = 'cute child face';
    String body = 'average build';
    String clothes = 'modest colorful clothes';
    String arabicTranslation = 'طفل لطيف بملابس ملونة ومحتشمة';
    final textApiKey = dotenv.env['POLLINATIONS_TEXT_API_KEY'] ?? '';

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
                  "text": "Analyze this child's image. Output ONLY a valid JSON object with these keys: 'face_description' (max 4 words, focusing on hair/eyes/skin), 'body_traits' (max 2 words), 'current_clothes' (max 5 words, MUST describe the garments and colors clearly), 'arabic_translation' (an accurate Arabic translation of the overall visual description). Use simple English words, no punctuation."
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
        arabicTranslation = extractedData['arabic_translation'] ?? arabicTranslation;
        
        // حماية إضافية: إذا كان الوصف فارغاً، نعطيه ملابس افتراضية لمنع الحجب
        if (clothes.trim().isEmpty) clothes = 'modest colorful clothes';
      } else {
        debugPrint('[AvatarVision] فشل التحليل برمز: ${visionResponse.statusCode}. سيتم استخدام وصف افتراضي.');
      }
    } catch (e) {
      debugPrint('[AvatarVision] خطأ أثناء التحليل: $e');
    }
    
    // إصلاح الخلل: السماح باللغة العربية والإنجليزية وإزالة الأسطر الجديدة فقط لمنع خطأ 400
    final String cleanFace = face.replaceAll(RegExp(r'[\n\r]'), ' ').trim();
    final String cleanBody = body.replaceAll(RegExp(r'[\n\r]'), ' ').trim();
    final String cleanClothes = clothes.replaceAll(RegExp(r'[\n\r]'), ' ').trim().isNotEmpty ? clothes.replaceAll(RegExp(r'[\n\r]'), ' ').trim() : 'modest colorful clothes';

    String shorten(String text, int max) => text.length > max ? text.substring(0, max) : text;
    final String identityPrompt = "3D Pixar child, ${shorten(cleanFace, 80)}, wearing ${shorten(cleanClothes, 80)}, clean background";

    return {
      "face_description": cleanFace,
      "body_traits": cleanBody,
      "current_clothes": cleanClothes,
      "english_prompt": identityPrompt,
      "arabic_prompt": arabicTranslation,
      "reference_image_url": imageUrl,
    };
  }

  /// توليد 4 خيارات بناءً على الوصف المعتمد
  /// تم الإصلاح: استخدام POST بدل GET للتعامل مع prompts الطويلة
  static Future<List<Map<String, dynamic>>> generateOptionsFromData(Map<String, dynamic> data) async {
    final imageApiKey = dotenv.env['POLLINATIONS_IMAGE_API_KEY'] ?? '';
    final String identityPrompt = data['english_prompt'] ?? '';
    debugPrint('[AvatarGen] prompt built: $identityPrompt');
    
    final futures = List.generate(4, (i) async {
      final seed = DateTime.now().millisecondsSinceEpoch + i;
      
      try {
        // ✅ الإصلاح: استخدام POST endpoint بدل GET (لدعم الـ prompts الطويلة)
        final response = await http.post(
          Uri.parse('https://gen.pollinations.ai/v1/images/generations'),
          headers: {
            'Content-Type': 'application/json',
            if (imageApiKey.isNotEmpty) 'Authorization': 'Bearer $imageApiKey',
          },
          body: jsonEncode({
            'prompt': identityPrompt,
            'model': 'flux',
            'size': '1024x1024',
            'seed': seed,
            'nologo': true,
            'response_format': 'b64_json',
          }),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final b64Json = responseData['data']?[0]?['b64_json'] as String?;
          
          if (b64Json != null && b64Json.isNotEmpty) {
            debugPrint('[AvatarGen] raw image received');
            
            final Uint8List imageBytes = base64Decode(b64Json);
            final String userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
            final String fileName = '$userId/avatar_option_${DateTime.now().millisecondsSinceEpoch}_$seed.jpg';

            await Supabase.instance.client.storage.from('avatars').uploadBinary(
              fileName,
              imageBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
            debugPrint('[AvatarGen] uploaded to Supabase Storage');

            final String publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
            debugPrint('[AvatarGen] preview_url ready');

            return {
              "face_description": data['face_description'],
              "body_traits": data['body_traits'],
              "current_clothes": data['current_clothes'],
              "preview_url": publicUrl,
              "reference_image_url": data['reference_image_url'],
              "seed": seed
            };
          } else {
            debugPrint('[AvatarGen] skipped invalid output');
            return null;
          }
        }
        
        debugPrint('[AvatarGen] ❌ فشل (status=${response.statusCode}, body=${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)})');
        return null;
      } catch (e) {
        debugPrint('[AvatarGen] ❌ استثناء: $e');
        return null;
      }
    });
    
    final results = await Future.wait(futures);
    return results.whereType<Map<String, dynamic>>().toList();
  }
}

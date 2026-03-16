import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hikayati/core/network/supabase_service.dart';

class StoryGenerationService {
  static const String _baseUrl = 'https://text.pollinations.ai/';

  /// Generates a story in JSON format based on child details, and deducts credits first.
  static Future<Map<String, dynamic>> generateStory({
    required String childName,
    required int age,
    required String theme,
    required String avatarDescription,
  }) async {
    // 1. Deduct Credits before generation
    await SupabaseService.deductCredits(10, 'Story Creation: $theme');

    // 2. Build the structured Prompt to ensure JSON output and Character Consistency
    final systemPrompt =
        '''
    أنت مؤلف قصص أطفال محترف ومبدع.
    الهدف: كتابة قصة تناسب طفل اسمه "$childName" وعمره $age سنوات بموضوع "$theme".
    
    مهمتك:
    قم بصياغة استجابة بصيغة JSON حصراً، تحتوي على:
    1. "title": عنوان القصة الجذاب.
    2. "scenes": مصفوفة (Array) تحتوي على 4 مشاهد على الأقل.
       كل مشهد يحتوي على:
       - "text": نص الرواية باللغة العربية.
       - "image_prompt": وصف بصري دقيق باللغة الإنجليزية لتوليد صورة المشهد. يجب أن يتضمن هذا الوصف دائماً صفات بطل القصة لضمان الاتساق (Character Consistency): $avatarDescription.
    
    يجب أن يكون الرد JSON فقط، بدون أي نص إضافي أو شروحات.
    ''';

    // 3. Call Pollinations Text API
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": "اكتب القصة الآن."},
        ],
        "jsonMode": true,
      }),
    );

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw Exception('فشل في تحليل القصة (JSON Error): $e');
      }
    } else {
      throw Exception('فشل الاتصال بمحرك القصص: ${response.statusCode}');
    }
  }
}

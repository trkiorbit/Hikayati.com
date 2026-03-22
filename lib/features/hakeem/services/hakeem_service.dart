/// === HakeemService ===
/// خدمة دردشة حكيم — مستقلة تماماً
///
/// LAW 5 (HIKAYATI_AGENT_MASTER_SPEC.md):
///   "Services are isolated"
///
/// ملاحظة: analyzeChildImage() انتقلت إلى:
///   features/avatar_lab/services/avatar_vision_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class HakeemService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  /// دردشة تفاعلية مع حكيم كمستشار لأولياء الأمور
  static Future<String> chatWithHakeem(
    List<Map<String, String>> chatHistory,
    String newMessage,
  ) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY غير موجود');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );

    final systemPrompt = '''
أنت "حكيم"، مرشد ذكي ومستشار في تطبيق "حكواتي" لقصص الأطفال.
دورك:
1. الجد الحكيم الذي يوجه "ولي الأمر" (الآباء والأمهات). لا تخاطب الأطفال مباشرة.
2. المساعد التقني لحل مشاكل التطبيق (الشراء، الكريدت، استنساخ الصوت، الأفاتار).
3. مستشار تربوي لاقتراح أفكار قصص مفيدة للأطفال.

تحدث بأسلوب محترم، راقٍ، وواضح باللغة العربية.
رسالة المستخدم (ولي الأمر) الحالية هي:
$newMessage
''';

    try {
      final historyContent = chatHistory.map((msg) {
        final sender = msg['role'] == 'user' ? 'ولي الأمر' : 'حكيم';
        return "$sender: ${msg['content']}";
      }).join("\n");

      final finalPrompt =
          "$systemPrompt\n\nتاريخ المحادثة السابقة:\n$historyContent\n\nأجب الآن كحكيم على الرسالة الحالية بتجاوب مناسب ومفيد.";

      final response =
          await model.generateContent([Content.text(finalPrompt)]);
      return response.text ??
          'المعذرة يا طال عمرك، لم أستطع الاستيعاب بالكامل.';
    } catch (e) {
      debugPrint('[HakeemService] Error chatting: $e');
      return 'المعذرة، يبدو أن هناك عطلاً في شبكة الاتصال بالمكتبة السحرية.';
    }
  }
}

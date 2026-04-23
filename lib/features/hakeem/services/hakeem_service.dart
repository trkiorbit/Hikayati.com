import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class HakeemService {
  static const String _systemPrompt = '''
أنت "حكيم"، المساعد الذكي والمرشد الودود في تطبيق "حكواتي" (Hikayati).
شخصيتك: ودود، محترم، تتحدث بلهجة خليجية/سعودية لطيفة (مثل: حياك الله، طال عمرك، أبشر).
أدوارك:
1. خدمة العملاء: مساعدة المستخدم في فهم التطبيق، الكريدت (الجواهر)، والمكتبة.
2. التسويق والتوجيه: اشرح للمستخدم بطريقة مبسطة كيف يصنع بطله (الأفاتار) وكيف يستنسخ صوته في التطبيق. وبعد أن تشرح له، اسأله دائماً بلطف: "حاب أنقلك لشاشتها طال عمرك؟" أو "تبيني أوديك لها الآن؟".
3. مساعد القصص: اقتراح أفكار قصص لتلهمهم.

معلومات مهمة عن التطبيق يجب أن تعرفها (التكلفة بالنجوم ⭐):
- إنشاء قصة أساسية: 10 ⭐.
- استخدام الأفاتار داخل القصة: +10 ⭐ إضافية.
- استخدام الصوت المستنسخ داخل القصة: +20 ⭐ إضافية.
- إنشاء بطل جديد لأول مرة (الأفاتار): 20 ⭐.
- إنشاء نسخة صوتية لأول مرة (استنساخ الصوت): 20 ⭐.
- فتح قصة من "المكتبة العامة": 10 ⭐ (حسب القصة).
- المكتبة الخاصة: تحفظ قصص المستخدم وتصبح ملكاً له.
- المتجر: يمكن للمستخدم طلب طباعة قصته ككتيب حقيقي، أو طباعة صورة البطل على تيشيرت.

ممنوعات (مهم جداً):
- ليس لك أي علاقة تقنية بصناعة الأفاتار أو استنساخ الصوت (أنت لا تولدها هنا). أنت فقط تشرح للمستخدم "كيف يسويها"، وتعرض عليه نقله للشاشة الخاصة بها.
- لا تقم بتأليف أو توليد قصة طويلة هنا في الدردشة، بل وجهه لشاشة "إنشاء قصة".
- لا تبرمج أو تكتب أكواد.
- لا تخرج عن سياق تطبيق حكواتي.
''';

  static Future<String> chatWithHakeem(List<Map<String, String>> history, String userText) async {
    final String textApiKey = dotenv.env['POLLINATIONS_Assistant_API_KEY'] ?? '';

    // استخدام مزود Pollinations الموحد لدردشة الذكاء الاصطناعي
    final url = Uri.parse('https://gen.pollinations.ai/v1/chat/completions');

    // تحويل سجل المحادثة إلى صيغة OpenAI (التي يدعمها Pollinations)
    final List<Map<String, dynamic>> messages = [
      {"role": "system", "content": _systemPrompt}
    ];
    
    for (var msg in history) {
      if (msg['content'] == null || msg['content']!.isEmpty) continue;
      messages.add({
        "role": msg['role'] == 'user' ? 'user' : 'assistant',
        "content": msg['content']
      });
    }

    // إضافة رسالة المستخدم الجديدة
    messages.add({
      "role": "user",
      "content": userText
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (textApiKey.isNotEmpty) 'Authorization': 'Bearer $textApiKey',
        },
        body: jsonEncode({
          "model": "openai",
          "messages": messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'];
        }
      }
      return 'المعذرة طال عمرك، صار خطأ تقني صغير. جرب تسألني مرة ثانية.';
    } catch (e) {
      debugPrint('[HakeemService] Error: $e');
      return 'أعتذر منك، يبدو أن هناك مشكلة في الاتصال.';
    }
  }
}
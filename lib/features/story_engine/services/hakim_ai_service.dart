import 'package:google_generative_ai/google_generative_ai.dart';

class HakimAiService {
  late final GenerativeModel _model;
  
  HakimAiService(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('''
      أنت "حكيم"، المساعد الذكي لتطبيق "حكواتي". التطبيق مخصص للأطفال حيث يحولهم لأبطال القصة بسحر الذكاء الاصطناعي.
      دورك: مساعدة الآباء والأسرة باقتراح أفكار قصص رائعة، المساعدة في حل أي مشكلة تواجههم في التطبيق، واقتراح زيارة "المتجر" لشراء الجواهر والإضافات.
      يجب أن يكون أسلوبك: لطيف، سحري، محب للأطفال ومطمئن للآباء. تحدث باللغة العربية الفصحى المبسطة أو بلهجة لطيفة.
      '''),
    );
  }

  Future<String> askHakim(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'المعذرة يا صديقي، "حكيم" يحتاج لبعض الراحة الآن. حاول مرة أخرى.';
    } catch (e) {
      return 'حدث خطأ في الاتصال بحكيم: $e';
    }
  }
}

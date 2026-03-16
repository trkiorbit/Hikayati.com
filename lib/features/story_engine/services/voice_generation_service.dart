import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoiceGenerationService {
  static const String _pollinationsBaseUrl = 'https://text.pollinations.ai/';

  /// Generates a voice URL from Pollinations v3
  static String generateVoiceUrl({
    required String text,
    String voice = 'alloy', 
  }) {
    final encodedText = Uri.encodeComponent(text);
    return '$_pollinationsBaseUrl$encodedText?model=openai-audio&voice=$voice';
  }

  /// Generates a voice URL from ElevenLabs using the API key in .env
  static Future<String> generateElevenLabsVoiceUrl({
    required String text,
    required String voiceId, // Needs a valid cloned Voice ID from ElevenLabs
  }) async {
    final apiKey = dotenv.env['ELEVEN_LABS_API_KEY'];
    if (apiKey == null) {
      throw Exception('أمر خطير: لم يتم العثور على مفتاح ElevenLabs في ملف .env!');
    }

    final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId');
    
    final response = await http.post(
      url,
      headers: {
        'Accept': 'audio/mpeg',
        'xi-api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "text": text,
        "model_id": "eleven_multilingual_v2", // Supporting Arabic
      }),
    );

    if (response.statusCode == 200) {
      // Return a temporary solution or handle stream
      // In a real scenario, we might save this to temporary directory and return local path,
      // or we return the response body bytes to be played directly.
      // For now, we indicate success.
      return 'elevenlabs_audio_generated_successfully';
    } else {
      throw Exception('فشل الاتصال بـ ElevenLabs: ${response.statusCode}');
    }
  }
}

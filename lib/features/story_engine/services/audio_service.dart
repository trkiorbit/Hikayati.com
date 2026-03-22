import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة الصوت الموحدة - تتحكم في دورة الحياة وتمنع الانهيارات
class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDisposed = false;

  /// تشغيل النص كصوت (TTS)
  Future<void> playStoryText(String text, {required bool useClonedVoice}) async {
    if (_isDisposed) return;

    try {
      if (useClonedVoice) {
        // مسار ElevenLabs: استخدام المفتاح المباشر لاستنساخ الصوت
        final String elevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
        final prefs = await SharedPreferences.getInstance();
        final String? voiceId = prefs.getString('cloned_voice_id');

        if (elevenLabsKey.isEmpty || voiceId == null) {
          debugPrint('[AudioService] خطأ: مفتاح ElevenLabs أو Voice ID مفقود.');
          return;
        }

        debugPrint('[AudioService] توجيه الصوت إلى ElevenLabs (Voice: $voiceId)');
        
        final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId');
        final response = await http.post(
          url,
          headers: {
            'xi-api-key': elevenLabsKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "text": text,
            "model_id": "eleven_multilingual_v2", // الموديل الداعم للغة العربية
            "voice_settings": {
              "stability": 0.5,
              "similarity_boost": 0.75
            }
          }),
        );

        if (response.statusCode == 200 && !_isDisposed) {
          // ElevenLabs يُرجع ملف صوتي كـ Bytes، نقوم بحفظه مؤقتاً لتشغيله
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/elevenlabs_${DateTime.now().millisecondsSinceEpoch}.mp3');
          await file.writeAsBytes(response.bodyBytes);
          
          await _audioPlayer.play(DeviceFileSource(file.path));
        } else {
          debugPrint('[AudioService] فشل ElevenLabs: ${response.statusCode} - ${response.body}');
          return; // إيقاف التشغيل إذا فشل الجلب
        }
      } else {
        // مسار Pollinations: خدمة TTS المجانية للقصص العادية
        final audioUrl = 'https://text.pollinations.ai/tts/${Uri.encodeComponent(text)}';
        debugPrint('[AudioService] توجيه الصوت إلى Pollinations Audio');
        if (_isDisposed) return;
        await _audioPlayer.play(UrlSource(audioUrl));
      }

      if (_isDisposed || audioUrl.isEmpty) return;
      
      await _audioPlayer.play(UrlSource(audioUrl));
      
      // الانتظار حتى يكتمل المقطع الصوتي تماماً (لضمان التسلسل في السينما)
      if (!_isDisposed) {
        await _audioPlayer.onPlayerComplete.first;
      }
    } catch (e) {
      debugPrint('[AudioService] خطأ في تشغيل الصوت: $e');
    }
  }

  /// إيقاف التشغيل بأمان
  Future<void> stop() async {
    if (_isDisposed) return;
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('[AudioService] تجاهل خطأ الإيقاف: $e');
    }
  }

  /// التخلص من المشغل وإغلاقه بشكل نهائي يمنع الانهيارات
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Dispose handled: $e');
    }
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// خدمة الصوت الموحدة - تتحكم في دورة الحياة وتمنع الانهيارات
class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDisposed = false;

  /// تشغيل النص كصوت (TTS)
  Future<void> playStoryText(String text, {required bool useClonedVoice}) async {
    if (_isDisposed) return;

    try {
      String audioUrl = '';

      if (useClonedVoice) {
        // مسار ElevenLabs: استخدام المفتاح المباشر لاستنساخ الصوت
        final String elevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
        // يتم إضافة منطق ElevenLabs الفعلي هنا (API Call لجلب الرابط أو البايتات)
        // audioUrl = await _fetchElevenLabsAudio(text, elevenLabsKey);
        debugPrint('[AudioService] توجيه الصوت إلى ElevenLabs');
      } else {
        // مسار Pollinations: خدمة TTS المجانية للقصص العادية
        audioUrl = 'https://text.pollinations.ai/tts/${Uri.encodeComponent(text)}';
        debugPrint('[AudioService] توجيه الصوت إلى Pollinations Audio');
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

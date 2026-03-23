/// === TTS Service ===
/// مسار مستقل لتحويل النص إلى صوت عبر Pollinations ElevenLabs
/// الأصوات: onyx/adam (ذكر) - nova/rachel (أنثى) - alloy (متوازن)

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TtsService {
  static AudioPlayer? _activePlayer;

  static const maleVoice = 'onyx';
  static const femaleVoice = 'shimmer'; // تم استبدال nova بـ shimmer لتجنب التشويش

  /// تشغيل صوت وإرجاع Future عند اكتمال التشغيل
  /// [onComplete]: callback يُستدعى بعد انتهاء الصوت
  static Future<void> speakAndWait(
    String text, {
    String voice = 'alloy',
    VoidCallback? onComplete,
  }) async {
    if (text.trim().isEmpty) {
      onComplete?.call();
      return;
    }

    try {
      await _activePlayer?.stop();
      await _activePlayer?.dispose();
      _activePlayer = null;

      final String audioKey = dotenv.env['POLLINATIONS_AUDIO_API_KEY'] ?? '';
      final String encodedText = Uri.encodeComponent(text);
      final String url = 'https://gen.pollinations.ai/audio/$encodedText'
          '?voice=$voice'
          '&model=elevenlabs'
          '${audioKey.isNotEmpty ? "&key=$audioKey" : ""}';

      debugPrint('[TTS] Speaking with voice=$voice');

      final player = AudioPlayer();
      _activePlayer = player;

      // الاستماع لانتهاء التشغيل
      player.onPlayerComplete.listen((_) {
        debugPrint('[TTS] Completed');
        onComplete?.call();
      });

      // استماع للأخطاء
      player.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.stopped || state == PlayerState.disposed) {
          // لا نستدعي onComplete عند الإيقاف اليدوي
        }
      });

      await player.play(UrlSource(url));
    } catch (e) {
      debugPrint('[TTS] Error: ${e.toString()}');
      onComplete?.call(); // استكمال حتى لو كان خطأ
    }
  }

  /// تشغيل بسيط بدون انتظار
  static Future<void> speakScene(String text, {String voice = 'nova'}) async {
    await speakAndWait(text, voice: voice);
  }

  /// إيقاف الصوت الحالي
  static Future<void> stop() async {
    try {
      await _activePlayer?.stop();
      await _activePlayer?.dispose();
      _activePlayer = null;
    } catch (e) {
      debugPrint('[TTS] Stop error: ${e.toString()}');
    }
  }

  /// يتحقق من صحة اسم الصوت
  static String resolveVoice(String voice) {
    const validVoices = {
      'nova', 'shimmer', 'rachel', 'bella', 'elli', 'charlotte',
      'dorothy', 'sarah', 'emily', 'lily', 'matilda',
      'onyx', 'adam', 'josh', 'sam', 'daniel', 'echo', 'fable',
      'alloy', 'ash', 'ballad', 'coral', 'sage', 'verse',
      'callum', 'liam', 'george', 'brian', 'bill',
    };
    return validVoices.contains(voice) ? voice : femaleVoice;
  }
}

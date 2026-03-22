/// === ElevenLabs Direct Service ===
/// مسار مستقل للتحدث المباشر مع ElevenLabs API
/// يُستخدم لـ:
/// 1. قراءة مشاهد القصة بصوت مستنسخ (صوت الأب/الأم)
/// 2. قراءة بصوت راوٍ فنّي من ElevenLabs
///
/// الرسوم التشغيلية (Operational Fees):
/// كل عملية توليد صوتي ستخصم من رصيد المستخدم:
///   BASE_API_COST + OPERATIONAL_FEE
///
/// --- مسار منفصل تماماً عن TtsService (Pollinations) ---

import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// =============================================
// رسوم التشغيل الداخلية (Operational Fees)
// =============================================
class CreditFees {
  /// التكلفة الأساسية لاستدعاء API الصوت
  static const int baseApiCost = 50;

  /// الرسوم التشغيلية للتطبيق (تُضاف فوق التكلفة الأساسية)
  static const int operationalFee = 10;

  /// إجمالي ما يُخصم من رصيد المستخدم
  static int get totalCost => baseApiCost + operationalFee;

  /// رسالة الشفافية للمستخدم
  static String get transparencyMessage =>
      'تكلفة التوليد هي $totalCost نقطة (شاملة الرسوم التشغيلية)';
}

// =============================================
// الخدمة المباشرة لـ ElevenLabs
// =============================================
class ElevenLabsDirectService {
  static AudioPlayer? _activePlayer;

  /// قراءة نص بصوت محدد عبر ElevenLabs مباشرة
  ///
  /// [text]: النص المراد قراءته
  /// [voiceId]: معرّف الصوت من ElevenLabs
  ///   - يمكن أن يكون صوتاً مستنسخاً (voice_id المحفوظ في Supabase)
  ///   - أو صوتاً جاهزاً من ElevenLabs
  static Future<void> speak({
    required String text,
    required String voiceId,
  }) async {
    if (text.trim().isEmpty) return;

    final String apiKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('[ElevenLabs] مفتاح API غير موجود في .env');
      return;
    }

    try {
      // إيقاف أي صوت سابق
      await _activePlayer?.stop();
      await _activePlayer?.dispose();
      _activePlayer = null;

      debugPrint('[ElevenLabs] بدء توليد صوت - voice=$voiceId');

      final url = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/$voiceId',
      );

      final response = await http.post(
        url,
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',
        },
        body: '{'
            '"text": ${_jsonString(text)},'
            '"model_id": "eleven_multilingual_v2",'
            '"voice_settings": {'
            '"stability": 0.4,'
            '"similarity_boost": 0.85,'
            '"style": 0.0,'
            '"use_speaker_boost": true'
            '}'
            '}',
      );

      if (response.statusCode == 200) {
        // حفظ البيانات الصوتية في ملف مؤقت
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          '${tempDir.path}/eleven_${DateTime.now().millisecondsSinceEpoch}.mp3',
        );
        await tempFile.writeAsBytes(response.bodyBytes);

        debugPrint('[ElevenLabs] تم حفظ الصوت في: ${tempFile.path}');

        // تشغيل الملف الصوتي
        final player = AudioPlayer();
        _activePlayer = player;
        await player.play(DeviceFileSource(tempFile.path));

        // حذف الملف المؤقت بعد الانتهاء (اختياري)
        player.onPlayerComplete.listen((_) {
          tempFile.delete().ignore();
        });
      } else {
        debugPrint(
          '[ElevenLabs] خطأ HTTP: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[ElevenLabs] خطأ: ${e.toString()}');
    }
  }

  /// إيقاف الصوت الحالي
  static Future<void> stop() async {
    try {
      await _activePlayer?.stop();
      await _activePlayer?.dispose();
      _activePlayer = null;
    } catch (e) {
      debugPrint('[ElevenLabs] Stop error: ${e.toString()}');
    }
  }

  /// تحويل النص إلى صيغة JSON آمنة
  static String _jsonString(String text) {
    final escaped = text
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', '');
    return '"$escaped"';
  }
}

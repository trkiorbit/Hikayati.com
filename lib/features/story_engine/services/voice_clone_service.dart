/// === Voice Clone Service ===
/// مسار مستقل تماماً لاستنساخ صوت ولي الأمر
/// يعتمد على ElevenLabs API مباشرة
///
/// --- مسار مستقل عن TtsService و ElevenLabsDirectService ---
/// VoiceCloneService مسؤول فقط عن:
/// 1. رفع ملف صوتي وإنشاء Voice Profile
/// 2. حفظ voice_id (يتم في Supabase خارج هذا الملف)
/// 3. حذف Voice Profile عند الطلب
///
/// قراءة القصة بالصوت المستنسخ → ElevenLabsDirectService.speak(voiceId: clonedId)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VoiceCloneService {
  static String get _apiKey => dotenv.env['ELEVENLABS_API_KEY'] ?? '';

  // =========================================================
  // STEP 1: رفع صوت ولي الأمر وإنشاء Voice Profile
  // =========================================================
  /// [audioBytes]: بيانات ملف الصوت (mp3 أو wav)
  /// [voiceName]: اسم يصف الصوت (مثلاً "صوت أبو يزيد")
  /// يُعيد: voice_id من ElevenLabs للحفظ في Supabase
  static Future<String> cloneVoice({
    required List<int> audioBytes,
    required String voiceName,
    String description = 'صوت ولي الأمر لرواية القصص',
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('ELEVENLABS_API_KEY غير موجود في .env');
    }

    debugPrint('[VoiceClone] بدء رفع صوت: $voiceName');

    final url = Uri.parse('https://api.elevenlabs.io/v1/voices/add');

    // إنشاء طلب multipart
    final request = http.MultipartRequest('POST', url)
      ..headers['xi-api-key'] = _apiKey
      ..fields['name'] = voiceName
      ..fields['description'] = description
      ..files.add(
        http.MultipartFile.fromBytes(
          'files',
          audioBytes,
          filename: '${voiceName.replaceAll(' ', '_')}.mp3',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final voiceId = data['voice_id'] as String?;
      if (voiceId == null || voiceId.isEmpty) {
        throw Exception('لم يتم الحصول على voice_id من ElevenLabs');
      }
      debugPrint('[VoiceClone] تم إنشاء الصوت - voice_id: $voiceId');
      return voiceId;
    } else {
      final errorBody = response.body;
      debugPrint('[VoiceClone] خطأ: ${response.statusCode} - $errorBody');
      throw Exception('فشل استنساخ الصوت: ${response.statusCode}');
    }
  }

  // =========================================================
  // STEP 2: جلب قائمة أصوات المستخدم
  // =========================================================
  static Future<List<Map<String, dynamic>>> listMyVoices() async {
    if (_apiKey.isEmpty) return [];

    final response = await http.get(
      Uri.parse('https://api.elevenlabs.io/v1/voices'),
      headers: {'xi-api-key': _apiKey},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final voices = (data['voices'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      // فقط الأصوات التي أنشأها المستخدم (cloned)
      return voices
          .where((v) => v['category'] == 'cloned')
          .toList();
    }
    return [];
  }

  // =========================================================
  // STEP 3: حذف Voice Profile
  // =========================================================
  static Future<void> deleteVoice(String voiceId) async {
    if (_apiKey.isEmpty || voiceId.isEmpty) return;

    final response = await http.delete(
      Uri.parse('https://api.elevenlabs.io/v1/voices/$voiceId'),
      headers: {'xi-api-key': _apiKey},
    );

    if (response.statusCode == 200) {
      debugPrint('[VoiceClone] تم حذف الصوت: $voiceId');
    } else {
      debugPrint('[VoiceClone] فشل الحذف: ${response.statusCode}');
    }
  }
}
